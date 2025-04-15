import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../proxy_management/presentation/managers/proxy_manager.dart';
import '../http_integration/http/http_proxy_client.dart';
import 'cookie_manager.dart';
import 'rate_limiter.dart';
import 'user_agent_rotator.dart';

/// An advanced web scraper with proxy rotation, rate limiting, and more
class AdvancedWebScraper {
  /// The proxy manager for getting proxies
  final ProxyManager _proxyManager;

  /// The HTTP client with proxy support
  final ProxyHttpClient _httpClient;

  /// The rate limiter for respectful scraping
  final RateLimiter _rateLimiter;

  /// The user agent rotator for avoiding detection
  final UserAgentRotator _userAgentRotator;

  /// The cookie manager for maintaining sessions
  final CookieManager _cookieManager;

  /// Default timeout for requests in milliseconds
  final int _defaultTimeout;

  /// Maximum number of retry attempts
  final int _maxRetries;

  /// Whether to automatically handle cookies
  final bool _handleCookies;

  /// Whether to automatically follow redirects
  final bool _followRedirects;

  // Maximum number of redirects to follow is not used in this implementation

  /// Creates a new [AdvancedWebScraper] with the given parameters
  AdvancedWebScraper({
    required ProxyManager proxyManager,
    ProxyHttpClient? httpClient,
    RateLimiter? rateLimiter,
    UserAgentRotator? userAgentRotator,
    CookieManager? cookieManager,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    bool handleCookies = true,
    bool followRedirects = true,
  }) : _proxyManager = proxyManager,
       _httpClient =
           httpClient ??
           ProxyHttpClient(
             proxyManager: proxyManager,
             useValidatedProxies: true,
             rotateProxies: true,
           ),
       _rateLimiter = rateLimiter ?? RateLimiter(),
       _userAgentRotator = userAgentRotator ?? UserAgentRotator(),
       _cookieManager = cookieManager ?? CookieManager(null),
       _defaultTimeout = defaultTimeout,
       _maxRetries = maxRetries,
       _handleCookies = handleCookies,
       _followRedirects = followRedirects;

  /// Factory constructor to create an [AdvancedWebScraper] with default components
  static Future<AdvancedWebScraper> create({
    required ProxyManager proxyManager,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    bool handleCookies = true,
    bool followRedirects = true,
  }) async {
    final cookieManager = await CookieManager.create();

    return AdvancedWebScraper(
      proxyManager: proxyManager,
      cookieManager: cookieManager,
      defaultTimeout: defaultTimeout,
      maxRetries: maxRetries,
      handleCookies: handleCookies,
      followRedirects: followRedirects,
    );
  }

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
    return _rateLimiter.execute(
      url: url,
      fn:
          () => _fetchWithRetry(
            url: url,
            headers: headers,
            timeout: timeout ?? _defaultTimeout,
            retries: retries ?? _maxRetries,
          ),
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
    final effectiveHeaders = {'Accept': 'application/json', ...?headers};

    final response = await fetchHtml(
      url: url,
      headers: effectiveHeaders,
      timeout: timeout,
      retries: retries,
    );

    try {
      return json.decode(response) as Map<String, dynamic>;
    } catch (e) {
      throw ScrapingException('Failed to parse JSON response: $e');
    }
  }

  /// Submits a form with the given data
  ///
  /// [url] is the URL to submit the form to
  /// [method] is the HTTP method to use (GET or POST)
  /// [formData] is the form data to submit
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<String> submitForm({
    required String url,
    String method = 'POST',
    required Map<String, String> formData,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) async {
    final effectiveMethod = method.toUpperCase();
    final effectiveHeaders = {
      'Content-Type': 'application/x-www-form-urlencoded',
      ...?headers,
    };

    return _rateLimiter.execute(
      url: url,
      fn:
          () => _fetchWithRetry(
            url: url,
            method: effectiveMethod,
            headers: effectiveHeaders,
            body: Uri(queryParameters: formData).query,
            timeout: timeout ?? _defaultTimeout,
            retries: retries ?? _maxRetries,
          ),
    );
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
      final document = html_parser.parse(html);
      final elements = document.querySelectorAll(selector);

      return elements.map((element) {
        if (attribute != null) {
          return element.attributes[attribute] ?? '';
        } else if (asText) {
          return element.text.trim();
        } else {
          return element.outerHtml;
        }
      }).toList();
    } catch (e) {
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
      final document = html_parser.parse(html);
      final result = <Map<String, String>>[];

      // Find the maximum number of items for any selector
      int maxItems = 0;
      selectors.forEach((field, selector) {
        final elements = document.querySelectorAll(selector);
        if (elements.length > maxItems) {
          maxItems = elements.length;
        }
      });

      // Extract data for each item
      for (int i = 0; i < maxItems; i++) {
        final item = <String, String>{};

        selectors.forEach((field, selector) {
          final elements = document.querySelectorAll(selector);
          if (i < elements.length) {
            final element = elements[i];
            final attribute = attributes?[field];

            if (attribute != null) {
              item[field] = element.attributes[attribute] ?? '';
            } else {
              item[field] = element.text.trim();
            }
          } else {
            item[field] = '';
          }
        });

        result.add(item);
      }

      return result;
    } catch (e) {
      throw ScrapingException('Failed to extract structured data: $e');
    }
  }

  /// Fetches a URL with retry logic
  Future<String> _fetchWithRetry({
    required String url,
    String method = 'GET',
    Map<String, String>? headers,
    String? body,
    required int timeout,
    required int retries,
  }) async {
    int attempts = 0;
    Exception? lastException;
    final domain = _extractDomain(url);

    while (attempts < retries) {
      attempts++;

      try {
        // Get a fresh proxy for each retry
        _proxyManager.getNextProxy(validated: true);

        // Prepare headers
        final effectiveHeaders = {
          'User-Agent': _userAgentRotator.getRandomUserAgent(),
          ...?headers,
        };

        // Add cookies if enabled
        if (_handleCookies) {
          final cookieHeader = _cookieManager.getCookieHeader(domain);
          if (cookieHeader.isNotEmpty) {
            effectiveHeaders['Cookie'] = cookieHeader;
          }
        }

        // Create a request
        final request = http.Request(method, Uri.parse(url));
        request.headers.addAll(effectiveHeaders);

        if (body != null) {
          request.body = body;
        }

        // Send the request
        final response = await _httpClient
            .send(request)
            .timeout(Duration(milliseconds: timeout));

        // Handle redirects if enabled
        if (_followRedirects &&
            (response.statusCode == 301 || response.statusCode == 302) &&
            response.headers.containsKey('location')) {
          final redirectUrl = response.headers['location']!;
          final absoluteUrl = _resolveRedirectUrl(url, redirectUrl);

          // Follow the redirect
          return _fetchWithRetry(
            url: absoluteUrl,
            method: 'GET', // Redirects should use GET
            headers: headers,
            timeout: timeout,
            retries: retries - 1, // Decrement retries for redirects
          );
        }

        // Store cookies if enabled
        if (_handleCookies && response.headers.containsKey('set-cookie')) {
          final cookies =
              response.headers['set-cookie']!
                  .split(',')
                  .map((cookie) => Cookie.fromSetCookieValue(cookie))
                  .toList();

          _cookieManager.storeCookies(domain, cookies);
        }

        // Check if the response is successful
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // We would record success for this proxy if the method existed
          // _proxyManager.recordSuccess(proxy);

          // Return the response body
          return await response.stream.bytesToString();
        } else {
          // We would record failure for this proxy if the method existed
          // _proxyManager.recordFailure(proxy);

          throw ScrapingException(
            'Failed to fetch URL: HTTP ${response.statusCode}',
          );
        }
      } catch (e) {
        lastException =
            e is Exception ? e : ScrapingException('Failed to fetch URL: $e');

        // Wait before retrying
        if (attempts < retries) {
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
        }
      }
    }

    throw lastException ??
        ScrapingException('Failed to fetch URL after $retries attempts');
  }

  /// Extracts the domain from a URL
  String _extractDomain(String url) {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return url;
    }

    return uri.host;
  }

  /// Resolves a redirect URL against a base URL
  String _resolveRedirectUrl(String baseUrl, String redirectUrl) {
    if (redirectUrl.startsWith('http://') ||
        redirectUrl.startsWith('https://')) {
      return redirectUrl;
    }

    final baseUri = Uri.parse(baseUrl);
    if (redirectUrl.startsWith('/')) {
      // Absolute path
      return Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: redirectUrl,
      ).toString();
    } else {
      // Relative path
      final basePath =
          baseUri.path.endsWith('/')
              ? baseUri.path
              : baseUri.path.substring(0, baseUri.path.lastIndexOf('/') + 1);

      return Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: basePath + redirectUrl,
      ).toString();
    }
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
