import 'dart:async';

import '../proxy_management/presentation/managers/proxy_manager.dart';
import '../http_integration/http/http_proxy_client.dart';
import 'web_scraper.dart';
import 'scraping_task_queue.dart';
import 'scraping_logger.dart';
import 'robots_txt_handler.dart';
import 'streaming_html_parser.dart';

/// A web scraper with concurrency control
class ConcurrentWebScraper {
  /// The underlying web scraper
  final WebScraper _webScraper;

  /// The task queue for concurrency control
  final ScrapingTaskQueue _taskQueue;

  /// The logger for scraping operations
  final ScrapingLogger _logger;

  /// Creates a new [ConcurrentWebScraper] with the given parameters
  ///
  /// [proxyManager] is the proxy manager for getting proxies
  /// [maxConcurrentTasks] is the maximum number of concurrent tasks
  /// [httpClient] is the HTTP client to use
  /// [defaultUserAgent] is the default user agent to use
  /// [defaultHeaders] are the default headers to use
  /// [defaultTimeout] is the default timeout for requests in milliseconds
  /// [maxRetries] is the maximum number of retry attempts
  /// [logger] is the logger for scraping operations
  /// [robotsTxtHandler] is the robots.txt handler
  /// [streamingParser] is the streaming HTML parser
  /// [respectRobotsTxt] whether to respect robots.txt rules
  ConcurrentWebScraper({
    required ProxyManager proxyManager,
    int maxConcurrentTasks = 5,
    ProxyHttpClient? httpClient,
    String? defaultUserAgent,
    Map<String, String>? defaultHeaders,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    ScrapingLogger? logger,
    RobotsTxtHandler? robotsTxtHandler,
    StreamingHtmlParser? streamingParser,
    bool respectRobotsTxt = true,
  }) : _webScraper = WebScraper(
         proxyManager: proxyManager,
         httpClient: httpClient,
         defaultUserAgent: defaultUserAgent,
         defaultHeaders: defaultHeaders,
         defaultTimeout: defaultTimeout,
         maxRetries: maxRetries,
         logger: logger,
         robotsTxtHandler: robotsTxtHandler,
         streamingParser: streamingParser,
         respectRobotsTxt: respectRobotsTxt,
       ),
       _taskQueue = ScrapingTaskQueue(
         maxConcurrentTasks: maxConcurrentTasks,
         logger: logger,
       ),
       _logger = logger ?? ScrapingLogger();

  /// Factory constructor to create a [ConcurrentWebScraper] with default components
  static Future<ConcurrentWebScraper> create({
    required ProxyManager proxyManager,
    int maxConcurrentTasks = 5,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    bool respectRobotsTxt = true,
  }) async {
    final logger = ScrapingLogger();
    final robotsTxtHandler = RobotsTxtHandler(
      proxyManager: proxyManager,
      logger: logger,
      respectRobotsTxt: respectRobotsTxt,
    );
    final streamingParser = StreamingHtmlParser(logger: logger);

    return ConcurrentWebScraper(
      proxyManager: proxyManager,
      maxConcurrentTasks: maxConcurrentTasks,
      defaultTimeout: defaultTimeout,
      maxRetries: maxRetries,
      logger: logger,
      robotsTxtHandler: robotsTxtHandler,
      streamingParser: streamingParser,
      respectRobotsTxt: respectRobotsTxt,
    );
  }

  /// Fetches HTML content from multiple URLs concurrently
  ///
  /// [urls] is the list of URLs to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  /// [onProgress] is a callback for progress updates
  Future<Map<String, String>> fetchHtmlBatch({
    required List<String> urls,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
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
            () => _webScraper.fetchHtml(
              url: url,
              headers: headers,
              timeout: timeout,
              retries: retries,
              ignoreRobotsTxt: ignoreRobotsTxt,
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

  /// Extracts data from multiple URLs concurrently
  ///
  /// [urls] is the list of URLs to fetch
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  /// [onProgress] is a callback for progress updates
  Future<Map<String, List<String>>> extractDataBatch({
    required List<String> urls,
    required String selector,
    String? attribute,
    bool asText = true,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
    void Function(int completed, int total, String url)? onProgress,
  }) async {
    _logger.info('Extracting data batch: ${urls.length} URLs');
    final results = <String, List<String>>{};
    final errors = <String, dynamic>{};
    final completer = Completer<Map<String, List<String>>>();

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
      _taskQueue.addTask<List<String>>(
        task: () async {
          // First fetch the HTML
          final html = await _webScraper.fetchHtml(
            url: url,
            headers: headers,
            timeout: timeout,
            retries: retries,
            ignoreRobotsTxt: ignoreRobotsTxt,
          );

          // Then extract the data from the HTML
          return _webScraper.extractData(
            html: html,
            selector: selector,
            attribute: attribute,
            asText: asText,
          );
        },
        priority: 0,
        taskName: 'ExtractData-$url',
        onStart: () {
          _logger.info('Starting extraction for URL: $url');
        },
        onComplete: (result) {
          _logger.success('Extraction completed for URL: $url');
          results[url] = result;
          completed++;
          onProgress?.call(completed, urls.length, url);
          checkCompletion();
        },
        onError: (error, stackTrace) {
          _logger.error('Extraction failed for URL: $url - $error');
          errors[url] = error;
          completed++;
          onProgress?.call(completed, urls.length, url);
          checkCompletion();
        },
      );
    }

    return completer.future;
  }

  /// Extracts structured data from multiple URLs concurrently
  ///
  /// [urls] is the list of URLs to fetch
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  /// [onProgress] is a callback for progress updates
  Future<Map<String, List<Map<String, String>>>> extractStructuredDataBatch({
    required List<String> urls,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
    void Function(int completed, int total, String url)? onProgress,
  }) async {
    _logger.info('Extracting structured data batch: ${urls.length} URLs');
    final results = <String, List<Map<String, String>>>{};
    final errors = <String, dynamic>{};
    final completer = Completer<Map<String, List<Map<String, String>>>>();

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
      _taskQueue.addTask<List<Map<String, String>>>(
        task: () async {
          // First fetch the HTML
          final html = await _webScraper.fetchHtml(
            url: url,
            headers: headers,
            timeout: timeout,
            retries: retries,
            ignoreRobotsTxt: ignoreRobotsTxt,
          );

          // Then extract the structured data from the HTML
          return _webScraper.extractStructuredData(
            html: html,
            selectors: selectors,
            attributes: attributes,
          );
        },
        priority: 0,
        taskName: 'ExtractStructuredData-$url',
        onStart: () {
          _logger.info('Starting structured extraction for URL: $url');
        },
        onComplete: (result) {
          _logger.success('Structured extraction completed for URL: $url');
          results[url] = result;
          completed++;
          onProgress?.call(completed, urls.length, url);
          checkCompletion();
        },
        onError: (error, stackTrace) {
          _logger.error('Structured extraction failed for URL: $url - $error');
          errors[url] = error;
          completed++;
          onProgress?.call(completed, urls.length, url);
          checkCompletion();
        },
      );
    }

    return completer.future;
  }

  /// Fetches HTML content from a URL with priority
  ///
  /// [url] is the URL to fetch
  /// [priority] is the priority of the task (higher values = higher priority)
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  Future<String> fetchHtml({
    required String url,
    int priority = 0,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
  }) {
    return _taskQueue.addTask<String>(
      task:
          () => _webScraper.fetchHtml(
            url: url,
            headers: headers,
            timeout: timeout,
            retries: retries,
            ignoreRobotsTxt: ignoreRobotsTxt,
          ),
      priority: priority,
      taskName: 'FetchHTML-$url',
    );
  }

  /// Extracts data from a URL with priority
  ///
  /// [url] is the URL to fetch
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  /// [priority] is the priority of the task (higher values = higher priority)
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  Future<List<String>> extractData({
    required String url,
    required String selector,
    String? attribute,
    bool asText = true,
    int priority = 0,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
  }) {
    return _taskQueue.addTask<List<String>>(
      task: () async {
        // First fetch the HTML
        final html = await _webScraper.fetchHtml(
          url: url,
          headers: headers,
          timeout: timeout,
          retries: retries,
          ignoreRobotsTxt: ignoreRobotsTxt,
        );

        // Then extract the data from the HTML
        return _webScraper.extractData(
          html: html,
          selector: selector,
          attribute: attribute,
          asText: asText,
        );
      },
      priority: priority,
      taskName: 'ExtractData-$url',
    );
  }

  /// Extracts structured data from a URL with priority
  ///
  /// [url] is the URL to fetch
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [priority] is the priority of the task (higher values = higher priority)
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  /// [ignoreRobotsTxt] whether to ignore robots.txt rules (default: false)
  Future<List<Map<String, String>>> extractStructuredData({
    required String url,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    int priority = 0,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    bool ignoreRobotsTxt = false,
  }) {
    return _taskQueue.addTask<List<Map<String, String>>>(
      task: () async {
        // First fetch the HTML
        final html = await _webScraper.fetchHtml(
          url: url,
          headers: headers,
          timeout: timeout,
          retries: retries,
          ignoreRobotsTxt: ignoreRobotsTxt,
        );

        // Then extract the structured data from the HTML
        return _webScraper.extractStructuredData(
          html: html,
          selectors: selectors,
          attributes: attributes,
        );
      },
      priority: priority,
      taskName: 'ExtractStructuredData-$url',
    );
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

  /// Closes the web scraper
  void close() {
    _webScraper.close();
  }
}
