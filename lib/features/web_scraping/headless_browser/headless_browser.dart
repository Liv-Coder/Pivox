import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy.dart';
import 'package:pivox/features/proxy_management/platform/android_proxy_setter.dart';
import 'package:pivox/features/web_scraping/headless_browser/headless_browser_config.dart';
import 'package:pivox/features/web_scraping/scraping_logger.dart';
import 'package:pivox/features/web_scraping/scraping_exception.dart';

/// A headless browser implementation for web scraping
class HeadlessBrowser {
  /// The headless web view controller
  HeadlessInAppWebView? _headlessWebView;

  /// The web view controller
  InAppWebViewController? _controller;

  /// Configuration for the headless browser
  final HeadlessBrowserConfig config;

  /// Logger for scraping operations
  final ScrapingLogger _logger;

  /// Completer for page load events
  Completer<bool>? _pageLoadCompleter;

  // We track loading state through the page load completer

  /// The proxy to use for requests
  Proxy? _proxy;

  /// Creates a new [HeadlessBrowser] instance
  HeadlessBrowser({HeadlessBrowserConfig? config, ScrapingLogger? logger})
    : config = config ?? HeadlessBrowserConfig.defaultConfig(),
      _logger = logger ?? ScrapingLogger();

  /// Initializes the headless browser
  Future<void> initialize() async {
    if (_isDisposed) {
      throw ScrapingException.validation(
        'Cannot initialize a disposed browser',
        isRetryable: false,
      );
    }

    if (_headlessWebView != null) {
      return;
    }

    final webViewSettings = config.toInAppWebViewSettings();

    _headlessWebView = HeadlessInAppWebView(
      initialSettings: webViewSettings,
      onWebViewCreated: (controller) {
        _controller = controller;
        _log('Headless browser initialized');
      },
      onLoadStart: (controller, url) {
        _log('Started loading: $url');
      },
      onLoadStop: (controller, url) {
        _log('Finished loading: $url');
        _pageLoadCompleter?.complete(true);
      },
      onReceivedError: (controller, request, error) {
        _log(
          'Error loading ${request.url}: ${error.description} (${error.type})',
          isError: true,
        );
        _pageLoadCompleter?.completeError(
          ScrapingException.network(
            'Failed to load page: ${error.description} (${error.type})',
            isRetryable: true,
          ),
        );
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        _log(
          'HTTP error loading ${request.url}: ${errorResponse.statusCode} ${errorResponse.reasonPhrase}',
          isError: true,
        );
        _pageLoadCompleter?.completeError(
          ScrapingException.http(
            'HTTP error: ${errorResponse.statusCode} ${errorResponse.reasonPhrase}',
            statusCode: errorResponse.statusCode,
            isRetryable:
                (errorResponse.statusCode ?? 0) >= 500 ||
                errorResponse.statusCode == 429,
          ),
        );
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (config.loggingEnabled) {
          _log('Console: ${consoleMessage.message}');
        }
      },
    );

    await _headlessWebView!.run();

    // Set up proxy if available
    if (_proxy != null) {
      await setProxy(_proxy!);
    }

    // Clear cookies and cache if configured
    if (config.clearCookies) {
      await CookieManager.instance().deleteAllCookies();
    }

    if (config.clearCache) {
      await InAppWebViewController.clearAllCache();
    }
  }

  /// Sets a proxy for the browser to use
  Future<void> setProxy(Proxy proxy) async {
    _checkDisposed();

    _proxy = proxy;

    if (_controller == null) {
      return;
    }

    if (Platform.isAndroid) {
      // Try to set system proxy if available
      bool systemProxySet = false;
      try {
        // Check if Android proxy setter is supported
        if (AndroidProxySetter.isSupported) {
          final hasPermission = await AndroidProxySetter.hasProxyPermission();
          if (hasPermission) {
            systemProxySet = await AndroidProxySetter.setSystemProxy(proxy);
          }
        }
      } catch (e) {
        _log('Error setting system proxy: $e', isError: true);
      }

      // Set WebView settings
      await _controller!.setSettings(
        settings: InAppWebViewSettings(
          // Android uses system proxy settings
          // We can't set them directly from the app
          // This is a limitation of the Android WebView
        ),
      );

      if (systemProxySet) {
        _log('System proxy set to ${proxy.host}:${proxy.port}');
      } else {
        _log(
          'Proxy set to ${proxy.host}:${proxy.port} (Note: Android uses system proxy)',
        );
      }
    } else if (Platform.isIOS) {
      // iOS doesn't support proxy configuration in WebView
      _log('Proxy settings not supported on iOS WebView', isError: true);
    }
  }

  // Android proxy setter is now imported directly

  /// Checks if the browser is disposed and throws an exception if it is
  void _checkDisposed() {
    if (_isDisposed) {
      throw ScrapingException.validation(
        'Browser has been disposed',
        isRetryable: false,
      );
    }
  }

  /// Navigates to the specified URL
  Future<bool> navigateTo(
    String url, {
    Map<String, String>? headers,
    int? timeoutMillis,
  }) async {
    _checkDisposed();

    if (_controller == null) {
      await initialize();
    }

    if (_controller == null) {
      throw ScrapingException.validation(
        'Failed to initialize headless browser',
        isRetryable: false,
      );
    }

    // Reset page load completer
    _pageLoadCompleter = Completer<bool>();

    // Combine headers
    final combinedHeaders = <String, String>{};
    if (config.customHeaders != null) {
      combinedHeaders.addAll(config.customHeaders!);
    }
    if (headers != null) {
      combinedHeaders.addAll(headers);
    }

    // Load URL
    await _controller!.loadUrl(
      urlRequest: URLRequest(url: WebUri(url), headers: combinedHeaders),
    );

    // Wait for page to load with timeout
    try {
      return await _pageLoadCompleter!.future.timeout(
        Duration(milliseconds: timeoutMillis ?? config.timeoutMillis),
      );
    } on TimeoutException {
      _log('Navigation to $url timed out', isError: true);
      return false;
    } catch (e) {
      _log('Error navigating to $url: $e', isError: true);
      return false;
    }
  }

  /// Gets the HTML content of the current page
  Future<String> getHtml() async {
    _checkDisposed();

    if (_controller == null) {
      throw ScrapingException.validation(
        'Browser not initialized',
        isRetryable: false,
      );
    }

    final html = await _controller!.getHtml();
    return html ?? '';
  }

  /// Executes JavaScript in the browser and returns the result
  Future<dynamic> executeScript(String script) async {
    _checkDisposed();

    if (_controller == null) {
      throw ScrapingException.validation(
        'Browser not initialized',
        isRetryable: false,
      );
    }

    try {
      final result = await _controller!.evaluateJavascript(source: script);
      return result;
    } catch (e) {
      _log('Error executing script: $e', isError: true);
      throw ScrapingException.parsing(
        'Failed to execute script',
        originalException: e,
        isRetryable: false,
      );
    }
  }

  /// Waits for an element to be present in the DOM
  Future<bool> waitForElement(
    String selector, {
    int timeoutMillis = 10000,
  }) async {
    _checkDisposed();

    if (_controller == null) {
      throw ScrapingException.validation(
        'Browser not initialized',
        isRetryable: false,
      );
    }

    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime).inMilliseconds <
        timeoutMillis) {
      final result = await _controller!.evaluateJavascript(
        source: "document.querySelector('$selector') != null",
      );

      if (result == true) {
        return true;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    return false;
  }

  /// Extracts data from the page using CSS selectors
  Future<Map<String, dynamic>> extractData(
    Map<String, String> selectors, {
    Map<String, String>? attributes,
  }) async {
    _checkDisposed();

    if (_controller == null) {
      throw ScrapingException.validation(
        'Browser not initialized',
        isRetryable: false,
      );
    }

    final result = <String, dynamic>{};

    for (final entry in selectors.entries) {
      final key = entry.key;
      final selector = entry.value;
      final attribute = attributes?[key];

      try {
        String script;
        if (attribute != null) {
          script = """
            (function() {
              const elements = document.querySelectorAll('$selector');
              if (elements.length === 0) return null;

              if (elements.length === 1) {
                return elements[0].getAttribute('$attribute');
              } else {
                return Array.from(elements).map(el => el.getAttribute('$attribute'));
              }
            })();
          """;
        } else {
          script = """
            (function() {
              const elements = document.querySelectorAll('$selector');
              if (elements.length === 0) return null;

              if (elements.length === 1) {
                return elements[0].textContent.trim();
              } else {
                return Array.from(elements).map(el => el.textContent.trim());
              }
            })();
          """;
        }

        final value = await _controller!.evaluateJavascript(source: script);
        result[key] = value;
      } catch (e) {
        _log('Error extracting data for selector $selector: $e', isError: true);
        result[key] = null;
      }
    }

    return result;
  }

  /// Takes a screenshot of the current page
  Future<Uint8List?> takeScreenshot() async {
    _checkDisposed();

    if (_controller == null) {
      throw ScrapingException.validation(
        'Browser not initialized',
        isRetryable: false,
      );
    }

    try {
      final screenshot = await _controller!.takeScreenshot();
      return screenshot;
    } catch (e) {
      _log('Error taking screenshot: $e', isError: true);
      return null;
    }
  }

  /// Gets all cookies for the current page
  Future<List<Map<String, String>>> getCookies(String url) async {
    final uri = WebUri(url);
    final cookies = await CookieManager.instance().getCookies(url: uri);

    return cookies.map((webViewCookie) {
      return <String, String>{
        'name': webViewCookie.name,
        'value': webViewCookie.value,
        'domain': webViewCookie.domain ?? '',
        'path': webViewCookie.path ?? '/',
      };
    }).toList();
  }

  /// Sets cookies for the current page
  Future<void> setCookies(String url, List<Map<String, String>> cookies) async {
    final uri = WebUri(url);

    for (final cookie in cookies) {
      await CookieManager.instance().setCookie(
        url: uri,
        name: cookie['name'] ?? '',
        value: cookie['value'] ?? '',
        domain: cookie['domain'],
        path: cookie['path'] ?? '/',
      );
    }
  }

  /// Clears all cookies
  Future<void> clearCookies() async {
    await CookieManager.instance().deleteAllCookies();
  }

  /// Clears the browser cache
  Future<void> clearCache() async {
    await InAppWebViewController.clearAllCache();
  }

  /// Flag to track if the browser has been disposed
  bool _isDisposed = false;

  /// Launches the browser with the given configuration
  Future<HeadlessBrowser> launch(HeadlessBrowserConfig config) async {
    // Create a new browser with the given configuration
    final browser = HeadlessBrowser(config: config, logger: _logger);

    // Initialize the browser
    await browser.initialize();

    // Navigate to the URL if provided
    if (config.url != null) {
      await browser.navigateTo(
        config.url!,
        headers: config.headers,
        timeoutMillis: config.timeout,
      );

      // Wait for network idle if configured
      if (config.waitForNetworkIdle) {
        await browser.waitForNetworkIdle();
      }

      // Wait for DOM content loaded if configured
      if (config.waitForDomContentLoaded) {
        await browser.waitForDomContentLoaded();
      }
    }

    return browser;
  }

  /// Fetches HTML content from a URL
  Future<String> fetchHtml({
    required String url,
    Map<String, String>? headers,
  }) async {
    try {
      // Navigate to the URL
      await navigateTo(url, headers: headers);

      // Wait for the page to load
      await waitForDomContentLoaded();

      // Get the HTML content
      return await getHtml();
    } catch (e) {
      _log('Error fetching HTML: $e', isError: true);
      throw ScrapingException.network(
        'Failed to fetch HTML',
        originalException: e,
        isRetryable: true,
      );
    }
  }

  /// Waits for the DOM content to be loaded
  Future<bool> waitForDomContentLoaded({int timeoutMillis = 30000}) async {
    _checkDisposed();

    if (_controller == null) {
      throw ScrapingException.validation(
        'Browser not initialized',
        isRetryable: false,
      );
    }

    try {
      final result = await _controller!.evaluateJavascript(
        source: """
        new Promise((resolve) => {
          if (document.readyState === 'complete' || document.readyState === 'interactive') {
            resolve(true);
          } else {
            document.addEventListener('DOMContentLoaded', () => resolve(true));
          }
        });
      """,
      );

      return result == true;
    } catch (e) {
      _log('Error waiting for DOM content loaded: $e', isError: true);
      return false;
    }
  }

  /// Waits for the network to be idle
  Future<bool> waitForNetworkIdle({
    int timeoutMillis = 30000,
    int idleTimeMs = 500,
  }) async {
    _checkDisposed();

    if (_controller == null) {
      throw ScrapingException.validation(
        'Browser not initialized',
        isRetryable: false,
      );
    }

    try {
      // Inject a script to track network requests
      await _controller!.evaluateJavascript(
        source: """
        window._networkRequests = 0;
        window._originalFetch = window.fetch;
        window._originalXHR = window.XMLHttpRequest.prototype.open;

        window.fetch = function() {
          window._networkRequests++;
          return window._originalFetch.apply(this, arguments).finally(() => {
            window._networkRequests--;
          });
        };

        window.XMLHttpRequest.prototype.open = function() {
          window._networkRequests++;
          this.addEventListener('loadend', () => {
            window._networkRequests--;
          });
          return window._originalXHR.apply(this, arguments);
        };
      """,
      );

      // Wait for network to be idle
      final startTime = DateTime.now();
      while (DateTime.now().difference(startTime).inMilliseconds <
          timeoutMillis) {
        final requests = await _controller!.evaluateJavascript(
          source: "window._networkRequests",
        );

        if (requests is int && requests == 0) {
          // Wait for the idle time to make sure no new requests start
          await Future.delayed(Duration(milliseconds: idleTimeMs));

          // Check again
          final requestsAfterIdle = await _controller!.evaluateJavascript(
            source: "window._networkRequests",
          );
          if (requestsAfterIdle is int && requestsAfterIdle == 0) {
            return true;
          }
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Timeout reached
      return false;
    } catch (e) {
      _log('Error waiting for network idle: $e', isError: true);
      return false;
    }
  }

  /// Clicks on an element matching the given selector
  Future<bool> click(String selector) async {
    _checkDisposed();

    if (_controller == null) {
      throw ScrapingException.validation(
        'Browser not initialized',
        isRetryable: false,
      );
    }

    try {
      // Wait for the element to be present
      final elementExists = await waitForElement(selector);
      if (!elementExists) {
        _log('Element not found: $selector', isError: true);
        return false;
      }

      // Click the element
      final result = await _controller!.evaluateJavascript(
        source: """
        (function() {
          const element = document.querySelector('$selector');
          if (!element) return false;

          element.click();
          return true;
        })();
      """,
      );

      return result == true;
    } catch (e) {
      _log('Error clicking element: $e', isError: true);
      return false;
    }
  }

  /// Gets the current page source
  Future<String> getPageSource() async {
    return getHtml();
  }

  /// Closes the browser
  Future<void> close() async {
    await dispose();
  }

  /// Disposes the headless browser
  Future<void> dispose() async {
    if (_isDisposed) {
      // Already disposed, do nothing
      return;
    }

    _isDisposed = true;

    try {
      // Cancel any pending page load
      _pageLoadCompleter?.completeError(
        ScrapingException.validation(
          'Browser disposed during page load',
          isRetryable: false,
        ),
      );

      // Clear references first
      final headlessWebView = _headlessWebView;
      _headlessWebView = null;
      _controller = null;

      // Then dispose the web view if it exists
      if (headlessWebView != null) {
        await headlessWebView.dispose();
      }
    } catch (e) {
      _log('Error during disposal: $e', isError: true);
    }
  }

  /// Logs a message
  void _log(String message, {bool isError = false}) {
    if (config.loggingEnabled) {
      if (isError) {
        _logger.error('HeadlessBrowser: $message');
      } else {
        _logger.info('HeadlessBrowser: $message');
      }
    }
  }
}
