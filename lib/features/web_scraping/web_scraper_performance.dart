import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/utils/logger.dart';
import 'caching/data_cache_manager.dart';
import 'memory/data_chunker.dart';
import 'parallel/resource_monitor.dart';
import 'parallel/scraping_task.dart';
import 'parallel/task_scheduler.dart';
import 'web_scraper.dart';

/// Extension methods for WebScraper to add performance optimization capabilities
extension WebScraperPerformanceExtension on WebScraper {
  /// Creates a task scheduler for parallel scraping
  TaskScheduler createTaskScheduler({
    TaskSchedulerConfig? config,
    ResourceMonitor? resourceMonitor,
    Logger? logger,
  }) {
    // Create a resource monitor if not provided
    final monitor = resourceMonitor ?? ResourceMonitor(logger: logger);

    // Start the resource monitor
    monitor.start();

    // Create the task scheduler
    final scheduler = TaskScheduler(
      rateLimiter: rateLimiter,
      resourceMonitor: monitor,
      config: config ?? TaskSchedulerConfig(),
      logger: logger,
    );

    // Start the scheduler
    scheduler.start();

    return scheduler;
  }

  /// Creates a data cache manager for caching scraping results
  DataCacheManager createCacheManager({
    String namespace = 'web_scraper',
    Logger? logger,
  }) {
    // Create the cache manager
    final cacheManager = DataCacheManager(namespace: namespace, logger: logger);

    // Initialize the cache manager
    cacheManager.initialize();

    return cacheManager;
  }

  /// Creates a data chunker for handling large datasets
  DataChunker createDataChunker({
    int chunkSize = DataChunker.defaultChunkSize,
    Logger? logger,
  }) {
    return DataChunker(chunkSize: chunkSize, logger: logger);
  }

  /// Fetches HTML with caching
  Future<String> fetchHtmlWithCache({
    required String url,
    required DataCacheManager cacheManager,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    DataCacheOptions cacheOptions = const DataCacheOptions(),
  }) async {
    // Generate a cache key from the URL
    final cacheKey = _generateCacheKey(url);

    // Try to get the HTML from cache
    final cachedHtml = await cacheManager.get<String>(cacheKey);
    if (cachedHtml != null) {
      logger.info('Cache hit for $url');
      return cachedHtml;
    }

    // If not in cache, fetch the HTML
    logger.info('Cache miss for $url, fetching...');
    final html = await fetchHtml(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );

    // Cache the HTML
    await cacheManager.put<String>(cacheKey, html, options: cacheOptions);

    return html;
  }

  /// Scrapes multiple URLs in parallel
  Future<List<T>> scrapeInParallel<T>({
    required List<String> urls,
    required Future<T> Function(String html, String url) extractor,
    required TaskScheduler scheduler,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    TaskPriority priority = TaskPriority.normal,
    int maxRetries = 3,
  }) async {
    // Create a task for each URL
    final tasks = <ScrapingTask<T>>[];
    final results = <T>[];

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      final domain = _extractDomain(url);

      // Create a task for this URL
      final task = ScrapingTask<T>(
        id: Uuid().v4(),
        domain: domain,
        url: url,
        execute: () async {
          // Fetch the HTML
          final html = await fetchHtml(
            url: url,
            headers: headers,
            timeout: timeout,
            retries: retries,
          );

          // Extract the data
          return await extractor(html, url);
        },
        priority: priority,
        maxRetries: maxRetries,
        logger: Logger('ScrapingTask-$i'),
      );

      // Add the task to the list
      tasks.add(task);

      // Enqueue the task
      scheduler.enqueue(task);
    }

    // Wait for all tasks to complete
    for (final task in tasks) {
      try {
        final result = await task.future;
        results.add(result);
      } catch (e) {
        logger.error('Error scraping ${task.url}: $e');
      }
    }

    return results;
  }

  /// Scrapes a URL with chunked processing for large HTML documents
  Future<T> scrapeWithChunking<T>({
    required String url,
    required DataChunker dataChunker,
    required FutureOr<T> Function(String chunk, T? previousResult) processor,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    T? initialResult,
  }) async {
    // Fetch the HTML
    final html = await fetchHtml(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );

    // Process the HTML in chunks
    return await dataChunker.processStringInChunks<T>(
      data: html,
      processor: processor,
      initialResult: initialResult,
    );
  }

  /// Extracts the domain from a URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  /// Generates a cache key from a URL
  String _generateCacheKey(String url) {
    // Use the URL as the cache key
    return url;
  }
}
