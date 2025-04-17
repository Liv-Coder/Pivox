import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../core/utils/logger.dart';
import '../proxy_management/presentation/managers/proxy_manager.dart';
import '../http_integration/http/http_proxy_client.dart';
import 'adaptive_scraping_strategy.dart';
import 'content/content_validator.dart';
import 'content/structured_data_validator.dart';
import 'robots_txt_handler.dart';
import 'scraping_exception.dart';
import 'scraping_logger.dart';
import 'selector/selector_validator.dart';
import 'site_reputation_tracker.dart';
import 'specialized_site_handlers.dart';
import 'streaming_html_parser.dart';

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

  /// The robots.txt handler
  final RobotsTxtHandler _robotsTxtHandler;

  /// Whether to respect robots.txt rules
  final bool _respectRobotsTxt;

  /// The streaming HTML parser
  final StreamingHtmlParser _streamingParser;

  /// The content validator
  final ContentValidator _contentValidator;

  /// The structured data validator
  final StructuredDataValidator _structuredDataValidator;

  /// The selector validator
  final SelectorValidator _selectorValidator;

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
    RobotsTxtHandler? robotsTxtHandler,
    StreamingHtmlParser? streamingParser,
    ContentValidator? contentValidator,
    StructuredDataValidator? structuredDataValidator,
    SelectorValidator? selectorValidator,
    bool respectRobotsTxt = true,
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
           AdaptiveScrapingStrategy(reputationTracker: reputationTracker),
       _robotsTxtHandler =
           robotsTxtHandler ??
           RobotsTxtHandler(
             proxyManager: proxyManager,
             logger: logger,
             defaultUserAgent: defaultUserAgent,
             respectRobotsTxt: respectRobotsTxt,
           ),
       _respectRobotsTxt = respectRobotsTxt,
       _streamingParser =
           streamingParser ?? StreamingHtmlParser(logger: logger),
       _contentValidator =
           contentValidator ?? ContentValidator(logger: Logger('WebScraper')),
       _structuredDataValidator =
           structuredDataValidator ??
           StructuredDataValidator(logger: Logger('WebScraper')),
       _selectorValidator =
           selectorValidator ?? SelectorValidator(logger: Logger('WebScraper'));

  /// Fetches HTML content from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  Future<String> fetchHtml({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
  }) async {
    final effectiveHeaders = {
      'User-Agent': _defaultUserAgent,
      ..._defaultHeaders,
      ...?headers,
    };

    final effectiveTimeout = timeout ?? _defaultTimeout;
    final effectiveRetries = retries ?? _maxRetries;

    // Check robots.txt if enabled and not explicitly ignored
    if (_respectRobotsTxt && !ignoreRobotsTxt) {
      final userAgent = effectiveHeaders['User-Agent'] ?? _defaultUserAgent;
      final isAllowed = await _robotsTxtHandler.isAllowed(url, userAgent);

      if (!isAllowed) {
        _logger.warning('URL not allowed by robots.txt: $url');
        throw ScrapingException.robotsTxt(
          'URL not allowed by robots.txt',
          url: url,
          isRetryable: false,
        );
      }
    }

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
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  Future<Map<String, dynamic>> fetchJson({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
  }) async {
    final effectiveHeaders = {
      'User-Agent': _defaultUserAgent,
      'Accept': 'application/json',
      ..._defaultHeaders,
      ...?headers,
    };

    final effectiveTimeout = timeout ?? _defaultTimeout;
    final effectiveRetries = retries ?? _maxRetries;

    // Check robots.txt if enabled and not explicitly ignored
    if (_respectRobotsTxt && !ignoreRobotsTxt) {
      final userAgent = effectiveHeaders['User-Agent'] ?? _defaultUserAgent;
      final isAllowed = await _robotsTxtHandler.isAllowed(url, userAgent);

      if (!isAllowed) {
        _logger.warning('URL not allowed by robots.txt: $url');
        throw ScrapingException.robotsTxt(
          'URL not allowed by robots.txt',
          url: url,
          isRetryable: false,
        );
      }
    }

    final response = await _fetchWithRetry(
      url: url,
      headers: effectiveHeaders,
      timeout: effectiveTimeout,
      retries: effectiveRetries,
    );

    try {
      return json.decode(response) as Map<String, dynamic>;
    } catch (e) {
      throw ScrapingException.parsing(
        'Failed to parse JSON response',
        originalException: e,
        url: url,
        isRetryable: false,
      );
    }
  }

  /// Parses HTML content and extracts data using CSS selectors
  ///
  /// [html] is the HTML content to parse
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  /// [validateContent] whether to validate and clean the extracted content
  /// [validateSelector] whether to validate and repair the selector
  List<String> extractData({
    required String html,
    required String selector,
    String? attribute,
    bool asText = true,
    bool validateContent = true,
    bool validateSelector = true,
  }) {
    try {
      // Log the selector for debugging
      _logger.info('Extracting data with selector: $selector');
      if (attribute != null) {
        _logger.info('Using attribute: $attribute');
      }

      // Parse the HTML
      final document = html_parser.parse(html);
      String effectiveSelector = selector;

      // Validate and repair the selector if needed
      if (validateSelector) {
        final validationResult = _selectorValidator
            .validateSelectorWithDocument(selector, document);

        if (!validationResult.isValid &&
            validationResult.repairedSelector != null) {
          _logger.warning(
            'Invalid selector: $selector. Using repaired selector: ${validationResult.repairedSelector}',
          );
          effectiveSelector = validationResult.repairedSelector!;
        } else if (!validationResult.isValid) {
          _logger.error(
            'Invalid selector: $selector. ${validationResult.errorMessage}',
          );
          return [];
        }
      }

      // Query the elements
      final elements = document.querySelectorAll(effectiveSelector);
      _logger.info('Found ${elements.length} elements matching selector');

      // If no elements found, log a warning and suggest alternatives
      if (elements.isEmpty) {
        _logger.warning(
          'No elements found matching selector: $effectiveSelector',
        );

        if (validateSelector) {
          final alternatives = _selectorValidator
              .suggestAlternativesWithDocument(effectiveSelector, document);

          if (alternatives.isNotEmpty) {
            _logger.info(
              'Suggested alternative selectors: ${alternatives.join(', ')}',
            );

            // Try the first alternative
            final alternativeElements = document.querySelectorAll(
              alternatives.first,
            );
            if (alternativeElements.isNotEmpty) {
              _logger.info(
                'Found ${alternativeElements.length} elements with alternative selector: ${alternatives.first}',
              );

              // Extract data with the alternative selector
              final alternativeResults =
                  alternativeElements.map((element) {
                    if (attribute != null) {
                      return element.attributes[attribute] ?? '';
                    } else if (asText) {
                      return element.text.trim();
                    } else {
                      return element.outerHtml;
                    }
                  }).toList();

              // Validate and clean the content if needed
              if (validateContent) {
                return _contentValidator.cleanContentList(alternativeResults);
              }

              return alternativeResults;
            }
          }
        }

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

      // Validate and clean the content if needed
      if (validateContent) {
        return _contentValidator.cleanContentList(results);
      }

      return results;
    } catch (e) {
      _logger.error('Failed to extract data: $e');
      throw ScrapingException.parsing(
        'Failed to extract data',
        originalException: e,
        isRetryable: false,
      );
    }
  }

  /// Parses HTML content and extracts structured data using CSS selectors
  ///
  /// [html] is the HTML content to parse
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [validateContent] whether to validate and clean the extracted content
  /// [validateSelectors] whether to validate and repair the selectors
  /// [requiredFields] fields that must be present and non-empty
  List<Map<String, String>> extractStructuredData({
    required String html,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    bool validateContent = true,
    bool validateSelectors = true,
    List<String> requiredFields = const [],
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
      final effectiveSelectors = <String, String>{};

      // Validate and repair selectors if needed
      if (validateSelectors) {
        final validationResults = _selectorValidator
            .validateSelectorsWithDocument(selectors, document);

        for (final entry in validationResults.entries) {
          final field = entry.key;
          final result = entry.value;

          if (!result.isValid && result.repairedSelector != null) {
            _logger.warning(
              'Invalid selector for field "$field": ${result.originalSelector}. '
              'Using repaired selector: ${result.repairedSelector}',
            );
            effectiveSelectors[field] = result.repairedSelector!;
          } else if (!result.isValid) {
            _logger.error(
              'Invalid selector for field "$field": ${result.originalSelector}. '
              '${result.errorMessage}',
            );
            // Use the original selector anyway, it might still work partially
            effectiveSelectors[field] = result.originalSelector;
          } else {
            effectiveSelectors[field] = result.originalSelector;
          }
        }
      } else {
        effectiveSelectors.addAll(selectors);
      }

      final result = <Map<String, String>>[];

      // Find the maximum number of items for any selector
      int maxItems = 0;
      effectiveSelectors.forEach((field, selector) {
        try {
          final elements = document.querySelectorAll(selector);
          _logger.info(
            'Found ${elements.length} elements for field "$field" with selector "$selector"',
          );
          if (elements.length > maxItems) {
            maxItems = elements.length;
          }
        } catch (e) {
          _logger.warning('Error querying selector for field "$field": $e');
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

        effectiveSelectors.forEach((field, selector) {
          try {
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
          } catch (e) {
            _logger.warning('Error extracting field "$field" in item $i: $e');
            item[field] = '';
          }
        });

        // Only add the item if it has at least one non-empty field
        if (item.values.any((value) => value.isNotEmpty)) {
          result.add(item);
        }
      }

      _logger.info('Extracted ${result.length} structured data items');

      // Validate and clean the content if needed
      if (validateContent) {
        return _structuredDataValidator.cleanStructuredDataList(result);
      }

      return result;
    } catch (e) {
      _logger.error('Failed to extract structured data: $e');
      throw ScrapingException.parsing(
        'Failed to extract structured data',
        originalException: e,
        isRetryable: false,
      );
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
          // Set the proxy in the HTTP client
          _httpClient.setProxy(proxy);
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
            throw ScrapingException.network(
              'Error reading response body',
              originalException: e,
              url: url,
              isRetryable: true,
            );
          }
        } else {
          // Record failure with the status code
          final statusCode = response.statusCode;
          final errorMessage = 'HTTP error: $statusCode';
          lastErrorMessage = errorMessage;
          _adaptiveStrategy.recordFailure(url, errorMessage);
          _logger.error(errorMessage);

          // Create appropriate exception based on status code
          if (statusCode == 429) {
            throw ScrapingException.rateLimit(
              'Rate limit exceeded',
              url: url,
              statusCode: statusCode,
              isRetryable: true,
            );
          } else if (statusCode == 403) {
            throw ScrapingException.permission(
              'Access forbidden',
              url: url,
              statusCode: statusCode,
              isRetryable: false,
            );
          } else if (statusCode == 401) {
            throw ScrapingException.authentication(
              'Authentication required',
              url: url,
              statusCode: statusCode,
              isRetryable: false,
            );
          } else if (statusCode >= 500) {
            throw ScrapingException.http(
              'Server error',
              url: url,
              statusCode: statusCode,
              isRetryable: true,
            );
          } else {
            throw ScrapingException.http(
              errorMessage,
              url: url,
              statusCode: statusCode,
              isRetryable: statusCode >= 500 || statusCode == 429,
            );
          }
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

    if (lastException is ScrapingException) {
      throw lastException;
    } else {
      throw ScrapingException.network(
        finalErrorMessage,
        originalException: lastException,
        url: url,
        isRetryable: false,
      );
    }
  }

  /// Fetches HTML content as a stream from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  Future<Stream<List<int>>> fetchHtmlStream({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
  }) async {
    final effectiveHeaders = {
      'User-Agent': _defaultUserAgent,
      ..._defaultHeaders,
      ...?headers,
    };

    final effectiveTimeout = timeout ?? _defaultTimeout;
    final effectiveRetries = retries ?? _maxRetries;

    // Check robots.txt if enabled and not explicitly ignored
    if (_respectRobotsTxt && !ignoreRobotsTxt) {
      final userAgent = effectiveHeaders['User-Agent'] ?? _defaultUserAgent;
      final isAllowed = await _robotsTxtHandler.isAllowed(url, userAgent);

      if (!isAllowed) {
        _logger.warning('URL not allowed by robots.txt: $url');
        throw ScrapingException.robotsTxt(
          'URL not allowed by robots.txt',
          url: url,
          isRetryable: false,
        );
      }
    }

    // Get the optimal strategy for this URL
    final strategy = _adaptiveStrategy.getStrategyForUrl(url);

    // Use the strategy parameters or the provided ones
    final effectiveRetries2 =
        strategy.retries > effectiveRetries
            ? strategy.retries
            : effectiveRetries;
    final effectiveTimeout2 =
        strategy.timeout > effectiveTimeout
            ? strategy.timeout
            : effectiveTimeout;
    final effectiveHeaders2 = Map<String, String>.from(effectiveHeaders);
    effectiveHeaders2.addAll(strategy.headers);

    _logger.info(
      'Using strategy for stream: retries=$effectiveRetries2, timeout=${effectiveTimeout2}ms',
    );

    // Ensure URL has proper scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
      _logger.info('URL scheme added: $url');
    }

    // Check if we have a specialized handler for this URL
    if (_specializedHandlers.hasHandlerForUrl(url)) {
      _logger.info('Using specialized handler for URL stream: $url');
      try {
        final handler = _specializedHandlers.getHandlerForUrl(url)!;
        final html = await handler.fetchHtml(
          url: url,
          headers: effectiveHeaders2,
          timeout: effectiveTimeout2,
          logger: _logger,
        );

        // Convert the HTML string to a stream
        return Stream.value(utf8.encode(html));
      } catch (e) {
        _logger.error('Specialized handler failed for stream: $e');
        _logger.info('Falling back to standard fetching mechanism for stream');
        // Fall through to standard mechanism
      }
    }

    // Get a fresh proxy
    final proxy = proxyManager.getNextProxy(
      validated: strategy.validateProxies,
    );
    // Set the proxy in the HTTP client
    _httpClient.setProxy(proxy);
    _logger.proxy('Using proxy for stream: ${proxy.ip}:${proxy.port}');

    // Create a request
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(effectiveHeaders2);
    _logger.request('Sending stream request to $url');

    try {
      // Send the request
      final response = await _httpClient
          .send(request)
          .timeout(Duration(milliseconds: effectiveTimeout2));

      // Check if the response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Record success for this URL
        _adaptiveStrategy.recordSuccess(url);
        _logger.success('Stream request successful');

        // Return the response stream
        return response.stream;
      } else {
        // Handle HTTP error
        final statusCode = response.statusCode;
        final errorMessage = 'HTTP error: $statusCode';
        _adaptiveStrategy.recordFailure(url, errorMessage);
        _logger.error(errorMessage);

        // Create appropriate exception based on status code
        if (statusCode == 429) {
          throw ScrapingException.rateLimit(
            'Rate limit exceeded',
            url: url,
            statusCode: statusCode,
            isRetryable: true,
          );
        } else if (statusCode == 403) {
          throw ScrapingException.permission(
            'Access forbidden',
            url: url,
            statusCode: statusCode,
            isRetryable: false,
          );
        } else if (statusCode == 401) {
          throw ScrapingException.authentication(
            'Authentication required',
            url: url,
            statusCode: statusCode,
            isRetryable: false,
          );
        } else if (statusCode >= 500) {
          throw ScrapingException.http(
            'Server error',
            url: url,
            statusCode: statusCode,
            isRetryable: true,
          );
        } else {
          throw ScrapingException.http(
            errorMessage,
            url: url,
            statusCode: statusCode,
            isRetryable: statusCode >= 500 || statusCode == 429,
          );
        }
      }
    } catch (e) {
      // Record the error
      _adaptiveStrategy.recordFailure(url, e.toString());
      _logger.error('Stream error: ${e.toString()}');

      if (e is ScrapingException) {
        rethrow;
      } else {
        throw ScrapingException.network(
          'Failed to fetch URL stream',
          originalException: e,
          url: url,
          isRetryable: true,
        );
      }
    }
  }

  /// Extracts data from a URL using streaming for memory efficiency
  ///
  /// [url] is the URL to fetch
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  Stream<String> extractDataStream({
    required String url,
    required String selector,
    String? attribute,
    bool asText = true,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) async* {
    final htmlStream = await fetchHtmlStream(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
      ignoreRobotsTxt: ignoreRobotsTxt,
    );

    final dataStream = _streamingParser.extractDataStream(
      htmlStream: htmlStream,
      selector: selector,
      attribute: attribute,
      asText: asText,
      chunkSize: chunkSize,
    );

    await for (final item in dataStream) {
      yield item;
    }
  }

  /// Extracts structured data from a URL using streaming for memory efficiency
  ///
  /// [url] is the URL to fetch
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  Stream<Map<String, String>> extractStructuredDataStream({
    required String url,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) async* {
    final htmlStream = await fetchHtmlStream(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
      ignoreRobotsTxt: ignoreRobotsTxt,
    );

    final dataStream = _streamingParser.extractStructuredDataStream(
      htmlStream: htmlStream,
      selectors: selectors,
      attributes: attributes,
      chunkSize: chunkSize,
    );

    await for (final item in dataStream) {
      yield item;
    }
  }

  /// Closes the HTTP client and other resources
  void close() {
    _httpClient.close();
    _robotsTxtHandler.close();
  }
}
