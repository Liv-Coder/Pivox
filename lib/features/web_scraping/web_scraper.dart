import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../proxy_management/presentation/managers/proxy_manager.dart';
import '../http_integration/http/http_proxy_client.dart';
import 'adaptive_scraping_strategy.dart';
import 'site_reputation_tracker.dart';
import 'scraping_logger.dart';
import 'specialized_site_handlers.dart';

/// A web scraper that uses proxies to avoid detection and blocking
class WebScraper {
  /// The proxy manager for getting proxies
  final ProxyManager proxyManager;

  /// The HTTP client with proxy support
  final ProxyHttpClient _httpClient;

  /// Default user agent to use for requests
  final String _defaultUserAgent;

  /// Default headers to use for requests
  final Map<String, String> _defaultHeaders;

  /// Default timeout for requests in milliseconds
  final int _defaultTimeout;

  /// Maximum number of retry attempts
  final int _maxRetries;

  /// The adaptive scraping strategy
  final AdaptiveScrapingStrategy _adaptiveStrategy;

  /// The site reputation tracker (accessible through the adaptive strategy)
  final SiteReputationTracker _reputationTracker;

  /// The scraping logger
  final ScrapingLogger _logger;

  /// Registry of specialized site handlers
  final SpecializedSiteHandlerRegistry _specializedHandlers =
      SpecializedSiteHandlerRegistry();

  /// Gets the site reputation tracker
  SiteReputationTracker get reputationTracker => _reputationTracker;

  /// Gets the scraping logger
  ScrapingLogger get logger => _logger;

  /// Creates a new [WebScraper] with the given parameters
  WebScraper({
    required this.proxyManager,
    ProxyHttpClient? httpClient,
    String? defaultUserAgent,
    Map<String, String>? defaultHeaders,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    AdaptiveScrapingStrategy? adaptiveStrategy,
    SiteReputationTracker? reputationTracker,
    ScrapingLogger? logger,
  }) : _httpClient =
           httpClient ??
           ProxyHttpClient(
             proxyManager: proxyManager,
             useValidatedProxies: true,
             rotateProxies: true,
           ),
       _defaultUserAgent =
           defaultUserAgent ??
           'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
       _defaultHeaders = defaultHeaders ?? {},
       _defaultTimeout = defaultTimeout,
       _maxRetries = maxRetries,
       _reputationTracker = reputationTracker ?? SiteReputationTracker(),
       _logger = logger ?? ScrapingLogger(),
       _adaptiveStrategy =
           adaptiveStrategy ??
           AdaptiveScrapingStrategy(reputationTracker: reputationTracker);

  /// Fetches HTML content from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<String> fetchHtml({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) async {
    final effectiveHeaders = {
      'User-Agent': _defaultUserAgent,
      ..._defaultHeaders,
      ...?headers,
    };

    final effectiveTimeout = timeout ?? _defaultTimeout;
    final effectiveRetries = retries ?? _maxRetries;

    return _fetchWithRetry(
      url: url,
      headers: effectiveHeaders,
      timeout: effectiveTimeout,
      retries: effectiveRetries,
    );
  }

  /// Fetches JSON content from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<Map<String, dynamic>> fetchJson({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) async {
    final effectiveHeaders = {
      'User-Agent': _defaultUserAgent,
      'Accept': 'application/json',
      ..._defaultHeaders,
      ...?headers,
    };

    final effectiveTimeout = timeout ?? _defaultTimeout;
    final effectiveRetries = retries ?? _maxRetries;

    final response = await _fetchWithRetry(
      url: url,
      headers: effectiveHeaders,
      timeout: effectiveTimeout,
      retries: effectiveRetries,
    );

    try {
      return json.decode(response) as Map<String, dynamic>;
    } catch (e) {
      throw ScrapingException('Failed to parse JSON response: $e');
    }
  }

  /// Parses HTML content and extracts data using CSS selectors
  ///
  /// [html] is the HTML content to parse
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  List<String> extractData({
    required String html,
    required String selector,
    String? attribute,
    bool asText = true,
  }) {
    try {
      // Log the selector for debugging
      _logger.info('Extracting data with selector: $selector');
      if (attribute != null) {
        _logger.info('Using attribute: $attribute');
      }

      // Parse the HTML
      final document = html_parser.parse(html);

      // Query the elements
      final elements = document.querySelectorAll(selector);
      _logger.info('Found ${elements.length} elements matching selector');

      // If no elements found, log a warning
      if (elements.isEmpty) {
        _logger.warning('No elements found matching selector: $selector');
        return [];
      }

      // Extract the data from the elements
      final results =
          elements.map((element) {
            if (attribute != null) {
              final value = element.attributes[attribute] ?? '';
              if (value.isEmpty) {
                _logger.warning(
                  'Attribute "$attribute" not found or empty in element',
                );
              }
              return value;
            } else if (asText) {
              final text = element.text.trim();
              if (text.isEmpty) {
                _logger.warning('Text content is empty in element');
              }
              return text;
            } else {
              return element.outerHtml;
            }
          }).toList();

      _logger.info('Extracted ${results.length} items');
      return results;
    } catch (e) {
      _logger.error('Failed to extract data: $e');
      throw ScrapingException('Failed to extract data: $e');
    }
  }

  /// Parses HTML content and extracts structured data using CSS selectors
  ///
  /// [html] is the HTML content to parse
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  List<Map<String, String>> extractStructuredData({
    required String html,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
  }) {
    try {
      // Log the selectors for debugging
      _logger.info(
        'Extracting structured data with selectors: ${selectors.toString()}',
      );
      if (attributes != null) {
        _logger.info('Using attributes: ${attributes.toString()}');
      }

      // Parse the HTML
      final document = html_parser.parse(html);
      final result = <Map<String, String>>[];

      // Find the maximum number of items for any selector
      int maxItems = 0;
      selectors.forEach((field, selector) {
        final elements = document.querySelectorAll(selector);
        _logger.info(
          'Found ${elements.length} elements for field "$field" with selector "$selector"',
        );
        if (elements.length > maxItems) {
          maxItems = elements.length;
        }
      });

      _logger.info('Maximum items found: $maxItems');

      // If no items found, log a warning
      if (maxItems == 0) {
        _logger.warning('No elements found for any selector');
        return [];
      }

      // Extract data for each item
      for (int i = 0; i < maxItems; i++) {
        final item = <String, String>{};

        selectors.forEach((field, selector) {
          final elements = document.querySelectorAll(selector);
          if (i < elements.length) {
            final element = elements[i];
            final attribute = attributes?[field];

            if (attribute != null) {
              final value = element.attributes[attribute] ?? '';
              if (value.isEmpty) {
                _logger.warning(
                  'Attribute "$attribute" not found or empty for field "$field" in item $i',
                );
              }
              item[field] = value;
            } else {
              final text = element.text.trim();
              if (text.isEmpty) {
                _logger.warning(
                  'Text content is empty for field "$field" in item $i',
                );
              }
              item[field] = text;
            }
          } else {
            _logger.warning('No element found for field "$field" in item $i');
            item[field] = '';
          }
        });

        result.add(item);
      }

      _logger.info('Extracted ${result.length} structured data items');
      return result;
    } catch (e) {
      _logger.error('Failed to extract structured data: $e');
      throw ScrapingException('Failed to extract structured data: $e');
    }
  }

  /// Fetches a URL with retry logic
  Future<String> _fetchWithRetry({
    required String url,
    required Map<String, String> headers,
    required int timeout,
    required int retries,
  }) async {
    _logger.info('Starting to fetch URL: $url');

    // Check if we have a specialized handler for this URL
    if (_specializedHandlers.hasHandlerForUrl(url)) {
      _logger.info('Using specialized handler for URL: $url');
      try {
        final handler = _specializedHandlers.getHandlerForUrl(url)!;
        return await handler.fetchHtml(
          url: url,
          headers: headers,
          timeout: timeout,
          logger: _logger,
        );
      } catch (e) {
        _logger.error('Specialized handler failed: $e');
        _logger.info('Falling back to standard fetching mechanism');
        // Fall through to standard mechanism
      }
    }

    // Get the optimal strategy for this URL
    final strategy = _adaptiveStrategy.getStrategyForUrl(url);

    // Use the strategy parameters or the provided ones
    final effectiveRetries =
        strategy.retries > retries ? strategy.retries : retries;
    final effectiveTimeout =
        strategy.timeout > timeout ? strategy.timeout : timeout;
    final effectiveHeaders = Map<String, String>.from(headers);
    effectiveHeaders.addAll(strategy.headers);

    _logger.info(
      'Using strategy: retries=$effectiveRetries, timeout=${effectiveTimeout}ms',
    );

    // Ensure URL has proper scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
      _logger.info('URL scheme added: $url');
    }

    int attempts = 0;
    Exception? lastException;
    String? lastErrorMessage;
    int currentBackoff = strategy.initialBackoff;

    while (attempts < effectiveRetries) {
      attempts++;

      try {
        _logger.info('Attempt $attempts/$effectiveRetries');

        // Get a fresh proxy for each retry if needed
        if (strategy.rotateProxiesOnRetry || attempts == 1) {
          final proxy = proxyManager.getNextProxy(
            validated: strategy.validateProxies,
          );
          _logger.proxy('Using proxy: ${proxy.ip}:${proxy.port}');
        }

        // Create a request with a timeout
        final request = http.Request('GET', Uri.parse(url));
        request.headers.addAll(effectiveHeaders);
        _logger.request('Sending request to $url');

        // Log headers for debugging
        _logger.request(
          'Headers: ${effectiveHeaders.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
        );

        final response = await _httpClient
            .send(request)
            .timeout(Duration(milliseconds: effectiveTimeout));

        _logger.response(
          'Received response: ${response.statusCode} ${response.reasonPhrase}',
        );

        // Check if the response is successful
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Record success for this URL
          _adaptiveStrategy.recordSuccess(url);
          _logger.success('Request successful');

          // Get the response body
          try {
            final body = await response.stream.bytesToString();
            _logger.success('Received ${body.length} bytes of data');

            // Check if the body is empty
            if (body.isEmpty) {
              _logger.warning('Received empty response body');
            }

            // Check if the body contains HTML
            if (!body.contains('<html') && !body.contains('<HTML')) {
              _logger.warning('Response body does not appear to be HTML');
            }

            // Return the response body
            return body;
          } catch (e) {
            _logger.error('Error reading response body: $e');
            throw ScrapingException('Error reading response body: $e');
          }
        } else {
          // Record failure with the status code
          final errorMessage = 'HTTP error: ${response.statusCode}';
          lastErrorMessage = errorMessage;
          _adaptiveStrategy.recordFailure(url, errorMessage);
          _logger.error(errorMessage);

          throw ScrapingException(errorMessage);
        }
      } catch (e) {
        // Record the error message
        lastErrorMessage = e.toString();
        _adaptiveStrategy.recordFailure(url, lastErrorMessage);
        _logger.error('Error: $lastErrorMessage');

        lastException =
            e is Exception ? e : ScrapingException('Failed to fetch URL: $e');

        // Wait before retrying with exponential backoff
        if (attempts < effectiveRetries) {
          // Calculate backoff based on strategy
          currentBackoff =
              (currentBackoff * strategy.backoffMultiplier).toInt();
          if (currentBackoff > strategy.maxBackoff) {
            currentBackoff = strategy.maxBackoff;
          }

          _logger.warning(
            'Retrying in ${currentBackoff}ms (attempt $attempts/$effectiveRetries)',
          );
          await Future.delayed(Duration(milliseconds: currentBackoff));
        } else {
          _logger.error('All retry attempts failed');
        }
      }
    }

    // If we've exhausted all retries and the URL is problematic, try one last time with a specialized handler
    if (_specializedHandlers.hasHandlerForUrl(url)) {
      _logger.info('Trying specialized handler as last resort for URL: $url');
      try {
        final handler = _specializedHandlers.getHandlerForUrl(url)!;
        return await handler.fetchHtml(
          url: url,
          headers: headers,
          timeout: timeout * 2, // Double the timeout for last resort
          logger: _logger,
        );
      } catch (e) {
        _logger.error('Last resort specialized handler also failed: $e');
        // Fall through to throw the original exception
      }
    }

    final finalErrorMessage =
        'Failed to fetch URL after $effectiveRetries attempts';
    _logger.error(finalErrorMessage);

    throw lastException ?? ScrapingException(finalErrorMessage);
  }

  /// Closes the HTTP client
  void close() {
    _httpClient.close();
  }
}

/// Exception thrown when scraping fails
class ScrapingException implements Exception {
  /// The error message
  final String message;

  /// Creates a new [ScrapingException] with the given message
  ScrapingException(this.message);

  @override
  String toString() => 'ScrapingException: $message';
}
