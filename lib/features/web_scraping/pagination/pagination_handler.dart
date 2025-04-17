import '../../../core/utils/logger.dart';
import '../scraping_exception.dart';
import '../web_scraper.dart';
import 'pagination_detector.dart';

/// Configuration for pagination handling
class PaginationConfig {
  /// The maximum number of pages to scrape
  final int maxPages;

  /// The maximum depth of pagination to follow
  final int maxDepth;

  /// Whether to follow pagination links automatically
  final bool followPagination;

  /// Whether to extract content from all pages
  final bool extractAllPages;

  /// Whether to merge content from all pages
  final bool mergeContent;

  /// Whether to validate pagination links
  final bool validateLinks;

  /// Whether to respect the order of pagination
  final bool respectOrder;

  /// Creates a new [PaginationConfig]
  const PaginationConfig({
    this.maxPages = 10,
    this.maxDepth = 5,
    this.followPagination = true,
    this.extractAllPages = true,
    this.mergeContent = true,
    this.validateLinks = true,
    this.respectOrder = true,
  });

  /// Creates a [PaginationConfig] for a single page
  factory PaginationConfig.singlePage() {
    return const PaginationConfig(
      maxPages: 1,
      maxDepth: 0,
      followPagination: false,
      extractAllPages: false,
      mergeContent: false,
    );
  }

  /// Creates a [PaginationConfig] for unlimited pagination
  factory PaginationConfig.unlimited() {
    return const PaginationConfig(
      maxPages: 100,
      maxDepth: 20,
      followPagination: true,
      extractAllPages: true,
      mergeContent: true,
    );
  }
}

/// Result of pagination handling
class PaginationResult<T> {
  /// The results from all pages
  final List<T> results;

  /// The URLs of all pages that were scraped
  final List<String> pageUrls;

  /// The total number of pages that were scraped
  final int pageCount;

  /// Whether there are more pages available
  final bool hasMorePages;

  /// The next page URL, if available
  final String? nextPageUrl;

  /// Creates a new [PaginationResult]
  PaginationResult({
    required this.results,
    required this.pageUrls,
    required this.pageCount,
    required this.hasMorePages,
    this.nextPageUrl,
  });

  /// Creates an empty [PaginationResult]
  factory PaginationResult.empty() {
    return PaginationResult(
      results: [],
      pageUrls: [],
      pageCount: 0,
      hasMorePages: false,
    );
  }
}

/// A class for handling pagination in web scraping
class PaginationHandler {
  /// The web scraper to use
  final WebScraper _webScraper;

  /// Logger for logging operations
  final Logger? logger;

  /// Creates a new [PaginationHandler]
  PaginationHandler({
    required WebScraper webScraper,
    this.logger,
  }) : _webScraper = webScraper;

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
    final results = <T>[];
    final pageUrls = <String>[];
    String? nextPageUrl = url;
    bool hasMorePages = false;
    int pageCount = 0;

    try {
      // Scrape pages until we reach the maximum or there are no more pages
      while (nextPageUrl != null && 
             pageCount < config.maxPages && 
             pageUrls.length <= config.maxDepth) {
        // Avoid duplicate pages
        if (pageUrls.contains(nextPageUrl)) {
          logger?.warning('Duplicate page URL detected: $nextPageUrl');
          break;
        }

        // Fetch the page
        logger?.info('Fetching page ${pageCount + 1}: $nextPageUrl');
        final html = await _webScraper.fetchHtml(
          url: nextPageUrl,
          headers: headers,
          timeout: timeout,
          retries: retries,
        );

        // Add the page URL to the list
        pageUrls.add(nextPageUrl);
        pageCount++;

        // Extract data from the page
        final result = await extractor(html, nextPageUrl);
        results.add(result);

        // If we're not following pagination, stop here
        if (!config.followPagination) {
          break;
        }

        // Detect pagination
        final paginationDetector = PaginationDetector(
          baseUrl: nextPageUrl,
          logger: logger,
        );
        final paginationResult = paginationDetector.detectPagination(html);

        // Update the next page URL
        nextPageUrl = paginationResult.nextPageUrl;
        hasMorePages = !paginationResult.isLastPage;

        // If there's no next page URL, we're done
        if (nextPageUrl == null) {
          logger?.info('No more pages to scrape');
          break;
        }

        // Validate the next page URL if needed
        if (config.validateLinks) {
          if (!_isValidUrl(nextPageUrl)) {
            logger?.warning('Invalid next page URL: $nextPageUrl');
            nextPageUrl = null;
            break;
          }
        }

        // Log the next page URL
        logger?.info('Next page URL: $nextPageUrl');
      }

      // Return the results
      return PaginationResult(
        results: results,
        pageUrls: pageUrls,
        pageCount: pageCount,
        hasMorePages: hasMorePages,
        nextPageUrl: nextPageUrl,
      );
    } catch (e) {
      logger?.error('Error scraping with pagination: $e');
      throw ScrapingException.pagination(
        'Error scraping with pagination',
        originalException: e,
        isRetryable: true,
      );
    }
  }

  /// Checks if a URL is valid
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }
}
