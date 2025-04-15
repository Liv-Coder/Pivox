import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../proxy_management/presentation/managers/proxy_manager.dart';
import '../http_integration/http/http_proxy_client.dart';

/// A web scraper that uses proxies to avoid detection and blocking
class WebScraper {
  /// The proxy manager for getting proxies
  final ProxyManager _proxyManager;

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

  /// Creates a new [WebScraper] with the given parameters
  WebScraper({
    required ProxyManager proxyManager,
    ProxyHttpClient? httpClient,
    String? defaultUserAgent,
    Map<String, String>? defaultHeaders,
    int defaultTimeout = 30000,
    int maxRetries = 3,
  }) : _proxyManager = proxyManager,
       _httpClient =
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
       _maxRetries = maxRetries;

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
    required Map<String, String> headers,
    required int timeout,
    required int retries,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < retries) {
      attempts++;

      try {
        // Get a fresh proxy for each retry
        _proxyManager.getNextProxy(validated: true);

        // Create a request with a timeout
        final request = http.Request('GET', Uri.parse(url));
        request.headers.addAll(headers);

        final response = await _httpClient
            .send(request)
            .timeout(Duration(milliseconds: timeout));

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
