import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../proxy_management/presentation/managers/proxy_manager.dart';
import '../http_integration/http/http_proxy_client.dart';
import 'cookie_manager.dart';
import 'enhanced_rate_limiter.dart';
import 'robots_txt_handler.dart';
import 'user_agent_rotator.dart';
import 'scraping_exception.dart';
import 'scraping_logger.dart';
import 'streaming_html_parser.dart';
import 'memory_efficient_parser.dart';
import 'scraping_task_queue.dart';

/// An advanced web scraper with proxy rotation, rate limiting, and more
class AdvancedWebScraper {
  /// The proxy manager for getting proxies
  final ProxyManager _proxyManager;

  /// The HTTP client with proxy support
  final ProxyHttpClient _httpClient;

  /// The rate limiter for respectful scraping
  final EnhancedRateLimiter _rateLimiter;

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

  /// The robots.txt handler for checking permissions
  // ignore: unused_field
  final RobotsTxtHandler? _robotsTxtHandler;

  /// The streaming HTML parser
  final StreamingHtmlParser _streamingParser;

  /// The memory-efficient HTML parser
  final MemoryEfficientParser _memoryEfficientParser;

  /// The task queue for concurrency control
  final ScrapingTaskQueue _taskQueue;

  /// The logger for scraping operations
  final ScrapingLogger _logger;

  // Maximum number of redirects to follow is not used in this implementation

  /// Creates a new [AdvancedWebScraper] with the given parameters
  AdvancedWebScraper({
    required ProxyManager proxyManager,
    ProxyHttpClient? httpClient,
    EnhancedRateLimiter? rateLimiter,
    UserAgentRotator? userAgentRotator,
    CookieManager? cookieManager,
    RobotsTxtHandler? robotsTxtHandler,
    StreamingHtmlParser? streamingParser,
    MemoryEfficientParser? memoryEfficientParser,
    ScrapingTaskQueue? taskQueue,
    ScrapingLogger? logger,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    bool handleCookies = true,
    bool followRedirects = true,
    bool respectRobotsTxt = true,
    int maxConcurrentTasks = 5,
  }) : _proxyManager = proxyManager,
       _httpClient =
           httpClient ??
           ProxyHttpClient(
             proxyManager: proxyManager,
             useValidatedProxies: true,
             rotateProxies: true,
           ),
       _rateLimiter =
           rateLimiter ??
           EnhancedRateLimiter(
             robotsTxtHandler: robotsTxtHandler,
             maxRetries: maxRetries,
           ),
       _userAgentRotator = userAgentRotator ?? UserAgentRotator(),
       _cookieManager = cookieManager ?? CookieManager(null),
       _defaultTimeout = defaultTimeout,
       _maxRetries = maxRetries,
       _handleCookies = handleCookies,
       _followRedirects = followRedirects,
       _robotsTxtHandler = robotsTxtHandler,
       _logger = logger ?? ScrapingLogger(),
       _streamingParser =
           streamingParser ?? StreamingHtmlParser(logger: logger),
       _memoryEfficientParser =
           memoryEfficientParser ?? MemoryEfficientParser(logger: logger),
       _taskQueue =
           taskQueue ??
           ScrapingTaskQueue(
             maxConcurrentTasks: maxConcurrentTasks,
             logger: logger,
           );

  /// Factory constructor to create an [AdvancedWebScraper] with default components
  static Future<AdvancedWebScraper> create({
    required ProxyManager proxyManager,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    bool handleCookies = true,
    bool followRedirects = true,
    bool respectRobotsTxt = true,
    int maxConcurrentTasks = 5,
  }) async {
    final logger = ScrapingLogger();
    final cookieManager = await CookieManager.create();
    final robotsTxtHandler = RobotsTxtHandler(
      proxyManager: proxyManager,
      logger: logger,
      respectRobotsTxt: respectRobotsTxt,
    );

    final rateLimiter = EnhancedRateLimiter(
      robotsTxtHandler: robotsTxtHandler,
      logger: logger,
      maxRetries: maxRetries,
    );

    final streamingParser = StreamingHtmlParser(logger: logger);
    final memoryEfficientParser = MemoryEfficientParser(logger: logger);
    final taskQueue = ScrapingTaskQueue(
      maxConcurrentTasks: maxConcurrentTasks,
      logger: logger,
    );

    return AdvancedWebScraper(
      proxyManager: proxyManager,
      cookieManager: cookieManager,
      rateLimiter: rateLimiter,
      robotsTxtHandler: robotsTxtHandler,
      streamingParser: streamingParser,
      memoryEfficientParser: memoryEfficientParser,
      taskQueue: taskQueue,
      logger: logger,
      defaultTimeout: defaultTimeout,
      maxRetries: maxRetries,
      handleCookies: handleCookies,
      followRedirects: followRedirects,
      respectRobotsTxt: respectRobotsTxt,
      maxConcurrentTasks: maxConcurrentTasks,
    );
  }

  /// Fetches HTML content from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [priority] is the priority of the request (higher values = higher priority)
  Future<String> fetchHtml({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    int priority = 0,
  }) async {
    // Prepare headers with user agent
    final effectiveHeaders = {
      'User-Agent': _userAgentRotator.getRandomUserAgent(),
      ...?headers,
    };

    final userAgent = effectiveHeaders['User-Agent'];

    return _rateLimiter.execute(
      url: url,
      fn:
          () => _fetchWithRetry(
            url: url,
            headers: effectiveHeaders,
            timeout: timeout ?? _defaultTimeout,
            retries: retries ?? _maxRetries,
          ),
      userAgent: userAgent,
      priority: priority,
    );
  }

  /// Fetches JSON content from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [priority] is the priority of the request (higher values = higher priority)
  Future<Map<String, dynamic>> fetchJson({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    int priority = 0,
  }) async {
    final effectiveHeaders = {'Accept': 'application/json', ...?headers};

    final response = await fetchHtml(
      url: url,
      headers: effectiveHeaders,
      timeout: timeout,
      retries: retries,
      priority: priority,
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
        final proxy = _proxyManager.getNextProxy(validated: true);
        // Set the proxy in the HTTP client
        _httpClient.setProxy(proxy);

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

          final statusCode = response.statusCode;

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
              'HTTP error: $statusCode',
              url: url,
              statusCode: statusCode,
              isRetryable: statusCode >= 500 || statusCode == 429,
            );
          }
        }
      } catch (e) {
        if (e is ScrapingException) {
          lastException = e;
        } else {
          lastException = ScrapingException.network(
            'Failed to fetch URL',
            originalException: e,
            url: url,
            isRetryable: true,
          );
        }

        // Wait before retrying
        if (attempts < retries) {
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
        }
      }
    }

    if (lastException != null) {
      throw lastException;
    } else {
      throw ScrapingException.network(
        'Failed to fetch URL after $retries attempts',
        url: url,
        isRetryable: false,
      );
    }
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

  /// Extracts data using memory-efficient parsing for large HTML documents
  ///
  /// [html] is the HTML content to parse
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  List<String> extractDataEfficient({
    required String html,
    required String selector,
    String? attribute,
    bool asText = true,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) {
    _logger.info(
      'Using memory-efficient extraction for HTML (${html.length} bytes)',
    );
    return _memoryEfficientParser.extractData(
      html: html,
      selector: selector,
      attribute: attribute,
      asText: asText,
      chunkSize: chunkSize,
    );
  }

  /// Extracts structured data using memory-efficient parsing for large HTML documents
  ///
  /// [html] is the HTML content to parse
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  List<Map<String, String>> extractStructuredDataEfficient({
    required String html,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) {
    _logger.info(
      'Using memory-efficient structured extraction for HTML (${html.length} bytes)',
    );
    return _memoryEfficientParser.extractStructuredData(
      html: html,
      selectors: selectors,
      attributes: attributes,
      chunkSize: chunkSize,
    );
  }

  /// Fetches HTML content as a stream from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [priority] is the priority of the request (higher values = higher priority)
  Future<Stream<List<int>>> fetchHtmlStream({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    int priority = 0,
  }) async {
    // Prepare headers with user agent
    final effectiveHeaders = {
      'User-Agent': _userAgentRotator.getRandomUserAgent(),
      ...?headers,
    };

    // User agent is already in the headers

    return _taskQueue.addTask<Stream<List<int>>>(
      task: () async {
        final response = await _httpClient
            .send(
              http.Request('GET', Uri.parse(url))
                ..headers.addAll(effectiveHeaders),
            )
            .timeout(Duration(milliseconds: timeout ?? _defaultTimeout));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.stream;
        } else {
          final statusCode = response.statusCode;
          final errorMessage = 'HTTP error: $statusCode';

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
      },
      priority: priority,
      taskName: 'FetchHTMLStream-$url',
    );
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
  /// [priority] is the priority of the request (higher values = higher priority)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  Stream<String> extractDataStream({
    required String url,
    required String selector,
    String? attribute,
    bool asText = true,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    int priority = 0,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) async* {
    final htmlStream = await fetchHtmlStream(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
      priority: priority,
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
  /// [priority] is the priority of the request (higher values = higher priority)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  Stream<Map<String, String>> extractStructuredDataStream({
    required String url,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    int priority = 0,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) async* {
    final htmlStream = await fetchHtmlStream(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
      priority: priority,
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

  /// Fetches HTML content from multiple URLs concurrently
  ///
  /// [urls] is the list of URLs to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [onProgress] is a callback for progress updates
  Future<Map<String, String>> fetchHtmlBatch({
    required List<String> urls,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    void Function(int completed, int total, String url)? onProgress,
  }) async {
    _logger.info('Fetching HTML batch: ${urls.length} URLs');
    final results = <String, String>{};
    final errors = <String, dynamic>{};
    final completer = Completer<Map<String, String>>();

    int completed = 0;

    // Function to check if all tasks are completed
    void checkCompletion() {
      if (completed == urls.length) {
        if (errors.isNotEmpty) {
          _logger.warning(
            'Batch completed with ${errors.length} errors: ${errors.keys.join(', ')}',
          );
        } else {
          _logger.success('Batch completed successfully');
        }

        completer.complete(results);
      }
    }

    // Add each URL as a task
    for (final url in urls) {
      _taskQueue.addTask<String>(
        task:
            () => fetchHtml(
              url: url,
              headers: headers,
              timeout: timeout,
              retries: retries,
            ),
        priority: 0,
        taskName: 'FetchHTML-$url',
        onStart: () {
          _logger.info('Starting fetch for URL: $url');
        },
        onComplete: (result) {
          _logger.success('Fetch completed for URL: $url');
          results[url] = result;
          completed++;
          onProgress?.call(completed, urls.length, url);
          checkCompletion();
        },
        onError: (error, stackTrace) {
          _logger.error('Fetch failed for URL: $url - $error');
          errors[url] = error;
          completed++;
          onProgress?.call(completed, urls.length, url);
          checkCompletion();
        },
      );
    }

    return completer.future;
  }

  /// Gets the number of pending tasks
  int get pendingTaskCount => _taskQueue.pendingTaskCount;

  /// Gets the number of running tasks
  int get runningTaskCount => _taskQueue.runningTaskCount;

  /// Gets the total number of tasks (pending + running)
  int get totalTaskCount => _taskQueue.totalTaskCount;

  /// Clears all pending tasks
  void clearPendingTasks() {
    _taskQueue.clearPendingTasks();
  }

  /// Closes the HTTP client
  void close() {
    _httpClient.close();
  }
}
