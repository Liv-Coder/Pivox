# Phase 3: Performance Optimization

This document outlines the performance optimization features implemented in Phase 3 of the Pivox project.

## Overview

Phase 3 focuses on improving the performance, efficiency, and scalability of the web scraping capabilities. The key areas of improvement include:

1. **Parallel Processing**: Enabling concurrent scraping operations with controlled parallelism
2. **Memory Management**: Optimizing memory usage for large datasets and streaming operations
3. **Caching Improvements**: Implementing efficient caching strategies using DataCacheX

## Features

### 1. Parallel Processing

#### TaskScheduler

The `TaskScheduler` class manages concurrent scraping operations with the following features:

- **Configurable Concurrency Limits**: Control the maximum number of concurrent tasks globally and per domain
- **Priority-based Scheduling**: Execute tasks based on priority levels (critical, high, normal, low, background)
- **Adaptive Concurrency**: Automatically adjust concurrency levels based on system resource usage
- **Task Dependencies**: Define dependencies between tasks to ensure proper execution order
- **Automatic Retries**: Retry failed tasks with configurable retry limits

```dart
// Create a task scheduler
final scheduler = webScraper.createTaskScheduler(
  config: TaskSchedulerConfig.conservative(),
  logger: logger,
);

// Scrape multiple URLs in parallel
final results = await webScraper.scrapeInParallel<Map<String, dynamic>>(
  urls: urls,
  extractor: (html, url) async {
    // Extract data from HTML
    return {'url': url, 'title': extractTitle(html)};
  },
  scheduler: scheduler,
  priority: TaskPriority.high,
);
```

#### ResourceMonitor

The `ResourceMonitor` class tracks system resource usage to enable adaptive concurrency:

- **CPU Usage Monitoring**: Track CPU usage to prevent overloading the system
- **Memory Usage Monitoring**: Track memory usage to prevent excessive memory consumption
- **Adaptive Throttling**: Automatically adjust concurrency based on resource availability

### 2. Memory Management

#### DataChunker

The `DataChunker` class optimizes memory usage for large datasets:

- **Chunked Processing**: Process large datasets in smaller, manageable chunks
- **Streaming Support**: Stream data processing for reduced memory footprint
- **Compression**: Compress data to reduce memory and storage requirements

```dart
// Create a data chunker
final dataChunker = webScraper.createDataChunker(
  chunkSize: 1024 * 10, // 10 KB chunks
  logger: logger,
);

// Process HTML in chunks
final wordCounts = await webScraper.scrapeWithChunking<Map<String, int>>(
  url: url,
  dataChunker: dataChunker,
  processor: (chunk, previousResult) {
    // Process each chunk and accumulate results
    final wordMap = previousResult ?? {};
    // Count word frequencies in this chunk
    // ...
    return wordMap;
  },
  initialResult: {},
);
```

### 3. Caching Improvements

#### DataCacheManager

The `DataCacheManager` class provides efficient caching using DataCacheX:

- **Multi-level Caching**: Cache data in memory and on disk for optimal performance
- **Configurable Cache Policies**: Control cache expiration, compression, and storage type
- **Namespace Support**: Organize cache entries by namespace for better management
- **Compressed Storage**: Reduce storage requirements with automatic compression

```dart
// Create a cache manager
final cacheManager = webScraper.createCacheManager(
  namespace: 'web_scraper',
  logger: logger,
);

// Fetch HTML with caching
final html = await webScraper.fetchHtmlWithCache(
  url: url,
  cacheManager: cacheManager,
  cacheOptions: DataCacheOptions.mediumLived(),
);
```

## Integration with WebScraper

All performance optimization features are integrated with the `WebScraper` class through extension methods:

```dart
extension WebScraperPerformanceExtension on WebScraper {
  TaskScheduler createTaskScheduler({...});
  DataCacheManager createCacheManager({...});
  DataChunker createDataChunker({...});
  Future<String> fetchHtmlWithCache({...});
  Future<List<T>> scrapeInParallel<T>({...});
  Future<T> scrapeWithChunking<T>({...});
}
```

## Usage Example

See the `example/performance_optimization_example.dart` file for a complete example of how to use these features.

## Performance Improvements

The performance optimization features provide significant improvements:

- **Throughput**: Increased scraping throughput with parallel processing
- **Memory Efficiency**: Reduced memory usage with chunked processing
- **Response Time**: Improved response time with caching
- **Scalability**: Better scalability with adaptive concurrency
- **Reliability**: Enhanced reliability with automatic retries and error handling

## Best Practices

1. **Configure Concurrency Limits**: Set appropriate concurrency limits based on your system resources
2. **Use Priority Levels**: Assign appropriate priority levels to tasks based on importance
3. **Enable Adaptive Concurrency**: Use adaptive concurrency to automatically adjust based on system load
4. **Choose Appropriate Chunk Sizes**: Select chunk sizes based on the nature of your data
5. **Configure Cache Policies**: Set appropriate cache expiration times based on data freshness requirements
6. **Monitor Resource Usage**: Keep an eye on CPU and memory usage during scraping operations
7. **Handle Errors Gracefully**: Implement proper error handling for failed tasks
