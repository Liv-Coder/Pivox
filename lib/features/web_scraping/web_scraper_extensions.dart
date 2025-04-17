import 'content/content_detector.dart';
import 'content/text_extractor.dart';
import 'lazy_loading/lazy_load_handler.dart';
import 'pagination/pagination_handler.dart';
import 'web_scraper.dart';

/// Extension methods for WebScraper to add intelligent scraping capabilities
extension WebScraperIntelligentScrapingExtension on WebScraper {
  /// Detects the main content area of a webpage
  ///
  /// [html] is the HTML content to parse
  ContentDetectionResult detectMainContent(String html) {
    return contentDetector.detectContent(html);
  }

  /// Extracts clean, readable text from HTML
  ///
  /// [html] is the HTML content to parse
  /// [options] are the text extraction options
  TextExtractionResult extractText(
    String html, {
    TextExtractionOptions options = const TextExtractionOptions(),
  }) {
    return textExtractor.extractText(html, options: options);
  }

  /// Fetches HTML content with lazy loading support
  ///
  /// [url] is the URL to fetch
  /// [config] is the lazy loading configuration
  /// [headers] are additional headers to send with the request
  Future<LazyLoadResult> fetchHtmlWithLazyLoading({
    required String url,
    LazyLoadConfig config = const LazyLoadConfig(),
    Map<String, String>? headers,
  }) async {
    return lazyLoadHandler.handleLazyLoading(
      url: url,
      config: config,
      headers: headers,
    );
  }

  /// Scrapes multiple pages with pagination
  ///
  /// [url] is the starting URL
  /// [config] is the pagination configuration
  /// [extractor] is a function that extracts data from each page
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<PaginationResult<T>> scrapeWithPagination<T>({
    required String url,
    required PaginationConfig config,
    required Future<T> Function(String html, String pageUrl) extractor,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) async {
    return paginationHandler.scrapeWithPagination(
      url: url,
      config: config,
      extractor: extractor,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );
  }

  /// Fetches HTML content with both lazy loading and pagination support
  ///
  /// [url] is the starting URL
  /// [paginationConfig] is the pagination configuration
  /// [lazyLoadConfig] is the lazy loading configuration
  /// [extractor] is a function that extracts data from each page
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<PaginationResult<T>> scrapeWithLazyLoadingAndPagination<T>({
    required String url,
    required PaginationConfig paginationConfig,
    required LazyLoadConfig lazyLoadConfig,
    required Future<T> Function(String html, String pageUrl) extractor,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) async {
    // Create a new extractor that applies lazy loading before extraction
    Future<T> lazyLoadingExtractor(String html, String pageUrl) async {
      // Apply lazy loading to the HTML
      final lazyLoadResult = await lazyLoadHandler.handleLazyLoading(
        url: pageUrl,
        config: lazyLoadConfig,
        headers: headers,
      );

      // Extract data from the lazy-loaded HTML
      return extractor(lazyLoadResult.html, pageUrl);
    }

    // Use the pagination handler with the lazy loading extractor
    return paginationHandler.scrapeWithPagination(
      url: url,
      config: paginationConfig,
      extractor: lazyLoadingExtractor,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );
  }

  /// Extracts the main content from multiple pages with pagination
  ///
  /// [url] is the starting URL
  /// [paginationConfig] is the pagination configuration
  /// [lazyLoadConfig] is the lazy loading configuration (optional)
  /// [textExtractionOptions] are the text extraction options (optional)
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<List<TextExtractionResult>> extractContentWithPagination({
    required String url,
    required PaginationConfig paginationConfig,
    LazyLoadConfig? lazyLoadConfig,
    TextExtractionOptions textExtractionOptions = const TextExtractionOptions(),
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) async {
    // Create an extractor function
    Future<TextExtractionResult> contentExtractor(
      String html,
      String pageUrl,
    ) async {
      // Apply lazy loading if configured
      if (lazyLoadConfig != null && lazyLoadConfig.handleLazyLoading) {
        final lazyLoadResult = await lazyLoadHandler.handleLazyLoading(
          url: pageUrl,
          config: lazyLoadConfig,
          headers: headers,
        );
        html = lazyLoadResult.html;
      }

      // Extract text from the HTML
      return textExtractor.extractText(html, options: textExtractionOptions);
    }

    // Use the pagination handler with the content extractor
    final result = await paginationHandler.scrapeWithPagination(
      url: url,
      config: paginationConfig,
      extractor: contentExtractor,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );

    return result.results;
  }
}
