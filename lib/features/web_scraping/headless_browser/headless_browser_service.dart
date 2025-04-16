import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, Uint8List;
import 'package:pivox/features/proxy_management/domain/entities/proxy.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_filter_options.dart';
import 'package:pivox/features/proxy_management/presentation/managers/proxy_manager.dart';
import 'package:pivox/features/web_scraping/advanced_web_scraper.dart';
import 'package:pivox/features/web_scraping/dynamic_user_agent_manager.dart';
import 'package:pivox/features/web_scraping/headless_browser/headless_browser.dart';
import 'package:pivox/features/web_scraping/headless_browser/headless_browser_config.dart';
import 'package:pivox/features/web_scraping/headless_browser/headless_browser_result.dart';
import 'package:pivox/features/web_scraping/scraping_logger.dart';
import 'package:pivox/features/web_scraping/site_reputation_tracker.dart';

/// Service for headless browser operations
class HeadlessBrowserService {
  /// The headless browser instance
  final HeadlessBrowser _browser;

  /// The proxy manager
  final ProxyManager? _proxyManager;

  /// The user agent manager
  final DynamicUserAgentManager _userAgentManager;

  /// The site reputation tracker
  final SiteReputationTracker _reputationTracker;

  /// The scraping logger
  final ScrapingLogger _logger;

  /// Whether to use proxies
  final bool _useProxies;

  /// Whether to rotate proxies
  final bool _rotateProxies;

  /// Maximum number of retries
  final int _maxRetries;

  /// Creates a new [HeadlessBrowserService] instance
  HeadlessBrowserService({
    HeadlessBrowser? browser,
    ProxyManager? proxyManager,
    DynamicUserAgentManager? userAgentManager,
    SiteReputationTracker? reputationTracker,
    ScrapingLogger? logger,
    HeadlessBrowserConfig? config,
    bool useProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
  }) : _browser = browser ?? HeadlessBrowser(config: config, logger: logger),
       _proxyManager = proxyManager,
       _userAgentManager = userAgentManager ?? DynamicUserAgentManager(),
       _reputationTracker = reputationTracker ?? SiteReputationTracker(),
       _logger = logger ?? ScrapingLogger(),
       _useProxies = useProxies && proxyManager != null,
       _rotateProxies = rotateProxies && proxyManager != null,
       _maxRetries = maxRetries;

  /// Initializes the service
  Future<void> initialize() async {
    await _browser.initialize();
  }

  /// Scrapes a URL using the headless browser
  Future<HeadlessBrowserResult> scrapeUrl(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? selectors,
    Map<String, String>? attributes,
    bool takeScreenshot = false,
    int? timeoutMillis,
    bool useProxy = true,
    Proxy? specificProxy,
  }) async {
    final startTime = DateTime.now();
    int retryCount = 0;
    Proxy? currentProxy;

    while (retryCount <= _maxRetries) {
      try {
        // Set up proxy if needed
        if (_useProxies && useProxy) {
          try {
            if (specificProxy != null) {
              currentProxy = specificProxy;
            } else if (_rotateProxies || currentProxy == null) {
              try {
                currentProxy = _proxyManager?.getNextProxy(validated: true);
              } catch (e) {
                _logger.error('Error getting validated proxy: $e');

                // Try to fetch and validate new proxies
                _logger.info('Attempting to fetch and validate new proxies...');
                try {
                  await _proxyManager?.fetchValidatedProxies(
                    options: ProxyFilterOptions(count: 10, onlyHttps: true),
                  );
                  currentProxy = _proxyManager?.getNextProxy(validated: true);
                } catch (e) {
                  _logger.error('Failed to fetch validated proxies: $e');

                  // Try with unvalidated proxies as a fallback
                  _logger.info('Trying with unvalidated proxies...');
                  try {
                    currentProxy = _proxyManager?.getNextProxy(
                      validated: false,
                    );
                    _logger.warning('Using unvalidated proxy as fallback');
                  } catch (e) {
                    _logger.error('No proxies available at all: $e');
                    // Continue without proxy
                  }
                }
              }
            }

            if (currentProxy != null) {
              await _browser.setProxy(currentProxy);
              _logger.info(
                'Using proxy: ${currentProxy.host}:${currentProxy.port}',
              );
            } else {
              _logger.warning('No proxy available, proceeding without proxy');
            }
          } catch (e) {
            _logger.error('Error setting up proxy: $e');
            // Continue without proxy
          }
        }

        // Prepare headers with user agent
        final combinedHeaders = <String, String>{};
        if (headers != null) {
          combinedHeaders.addAll(headers);
        }

        if (!combinedHeaders.containsKey('User-Agent')) {
          final userAgent = _userAgentManager.getRandomUserAgentForSite(url);
          combinedHeaders['User-Agent'] = userAgent;
        }

        // Navigate to URL
        final success = await _browser.navigateTo(
          url,
          headers: combinedHeaders,
          timeoutMillis: timeoutMillis,
        );

        if (!success) {
          throw ScrapingException('Failed to load page: $url');
        }

        // Get HTML content
        final html = await _browser.getHtml();

        // Extract data if selectors provided
        Map<String, dynamic>? extractedData;
        if (selectors != null && selectors.isNotEmpty) {
          extractedData = await _browser.extractData(
            selectors,
            attributes: attributes,
          );
        }

        // Take screenshot if requested
        Uint8List? screenshot;
        if (takeScreenshot) {
          screenshot = await _browser.takeScreenshot();
        }

        // Calculate elapsed time
        final elapsedMillis =
            DateTime.now().difference(startTime).inMilliseconds;

        // Update site reputation
        _reputationTracker.recordSuccess(url);

        // Return successful result
        return HeadlessBrowserResult.success(
          html: html,
          data: extractedData,
          screenshot: screenshot,
          elapsedMillis: elapsedMillis,
        );
      } catch (e, stackTrace) {
        _logger.error(
          'Error scraping $url (attempt ${retryCount + 1}/$_maxRetries): $e',
        );
        if (kDebugMode) {
          _logger.error(stackTrace.toString());
        }

        // Update site reputation
        _reputationTracker.recordFailure(url, e.toString());

        // Mark proxy as invalid if using proxies
        if (currentProxy != null && _proxyManager != null) {
          // Use validateSpecificProxy with false result to mark as invalid
          await _proxyManager.validateSpecificProxy(
            currentProxy,
            updateScore: true,
          );
          currentProxy = null;
        }

        retryCount++;

        if (retryCount <= _maxRetries) {
          _logger.info('Retrying in 1 second...');
          await Future.delayed(const Duration(seconds: 1));
        } else {
          final elapsedMillis =
              DateTime.now().difference(startTime).inMilliseconds;
          return HeadlessBrowserResult.failure(
            errorMessage: 'Failed after $retryCount attempts: ${e.toString()}',
            elapsedMillis: elapsedMillis,
          );
        }
      }
    }

    // This should never be reached, but just in case
    return HeadlessBrowserResult.failure(
      errorMessage: 'Unknown error occurred',
    );
  }

  /// Executes JavaScript on a page
  Future<dynamic> executeScript(String script) async {
    return await _browser.executeScript(script);
  }

  /// Waits for an element to be present in the DOM
  Future<bool> waitForElement(
    String selector, {
    int timeoutMillis = 10000,
  }) async {
    return await _browser.waitForElement(
      selector,
      timeoutMillis: timeoutMillis,
    );
  }

  /// Gets all cookies for the current page
  Future<List<Map<String, String>>> getCookies(String url) async {
    return await _browser.getCookies(url);
  }

  /// Sets cookies for the current page
  Future<void> setCookies(String url, List<Map<String, String>> cookies) async {
    await _browser.setCookies(url, cookies);
  }

  /// Clears all cookies
  Future<void> clearCookies() async {
    await _browser.clearCookies();
  }

  /// Clears the browser cache
  Future<void> clearCache() async {
    await _browser.clearCache();
  }

  /// Flag to track if the service has been disposed
  bool _isDisposed = false;

  /// Disposes the service
  Future<void> dispose() async {
    if (_isDisposed) {
      // Already disposed, do nothing
      return;
    }

    _isDisposed = true;

    try {
      await _browser.dispose();
    } catch (e) {
      _logger.error('Error disposing browser service: $e');
    }
  }
}
