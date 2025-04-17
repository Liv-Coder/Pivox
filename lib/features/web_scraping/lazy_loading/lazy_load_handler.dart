import '../../../core/utils/logger.dart';
import '../headless_browser/headless_browser.dart';
import '../headless_browser/headless_browser_config.dart';
import '../scraping_exception.dart';
import 'lazy_load_detector.dart';

/// Configuration for lazy loading handling
class LazyLoadConfig {
  /// Whether to handle lazy loading
  final bool handleLazyLoading;

  /// Whether to use a headless browser for lazy loading
  final bool useHeadlessBrowser;

  /// The maximum scroll depth (in viewport heights)
  final int maxScrollDepth;

  /// The scroll step size (in viewport heights)
  final double scrollStepSize;

  /// The scroll delay in milliseconds
  final int scrollDelayMs;

  /// The maximum wait time in milliseconds
  final int maxWaitTimeMs;

  /// Whether to click on load more buttons
  final bool clickLoadMoreButtons;

  /// Whether to wait for network idle
  final bool waitForNetworkIdle;

  /// Whether to wait for DOM content to be loaded
  final bool waitForDomContentLoaded;

  /// Creates a new [LazyLoadConfig]
  const LazyLoadConfig({
    this.handleLazyLoading = true,
    this.useHeadlessBrowser = true,
    this.maxScrollDepth = 10,
    this.scrollStepSize = 1.0,
    this.scrollDelayMs = 500,
    this.maxWaitTimeMs = 30000,
    this.clickLoadMoreButtons = true,
    this.waitForNetworkIdle = true,
    this.waitForDomContentLoaded = true,
  });

  /// Creates a [LazyLoadConfig] for no lazy loading
  factory LazyLoadConfig.none() {
    return const LazyLoadConfig(
      handleLazyLoading: false,
      useHeadlessBrowser: false,
    );
  }

  /// Creates a [LazyLoadConfig] for aggressive lazy loading
  factory LazyLoadConfig.aggressive() {
    return const LazyLoadConfig(
      handleLazyLoading: true,
      useHeadlessBrowser: true,
      maxScrollDepth: 20,
      scrollStepSize: 0.5,
      scrollDelayMs: 300,
      maxWaitTimeMs: 60000,
      clickLoadMoreButtons: true,
      waitForNetworkIdle: true,
      waitForDomContentLoaded: true,
    );
  }
}

/// Result of lazy loading handling
class LazyLoadResult {
  /// The HTML content after lazy loading
  final String html;

  /// Whether lazy loading was detected
  final bool lazyLoadingDetected;

  /// The type of lazy loading that was detected
  final LazyLoadType? lazyLoadType;

  /// The number of scroll operations performed
  final int scrollCount;

  /// The number of click operations performed
  final int clickCount;

  /// The total time spent in milliseconds
  final int totalTimeMs;

  /// Creates a new [LazyLoadResult]
  LazyLoadResult({
    required this.html,
    required this.lazyLoadingDetected,
    this.lazyLoadType,
    required this.scrollCount,
    required this.clickCount,
    required this.totalTimeMs,
  });

  /// Creates a [LazyLoadResult] with the original HTML
  factory LazyLoadResult.original(String html) {
    return LazyLoadResult(
      html: html,
      lazyLoadingDetected: false,
      scrollCount: 0,
      clickCount: 0,
      totalTimeMs: 0,
    );
  }
}

/// A class for handling lazy loading in web scraping
class LazyLoadHandler {
  /// The headless browser to use
  final HeadlessBrowser _headlessBrowser;

  /// The lazy load detector to use
  final LazyLoadDetector _lazyLoadDetector;

  /// Logger for logging operations
  final Logger? logger;

  /// Creates a new [LazyLoadHandler]
  LazyLoadHandler({
    required HeadlessBrowser headlessBrowser,
    LazyLoadDetector? lazyLoadDetector,
    this.logger,
  }) : _headlessBrowser = headlessBrowser,
       _lazyLoadDetector = lazyLoadDetector ?? LazyLoadDetector(logger: logger);

  /// Handles lazy loading for a URL
  ///
  /// [url] is the URL to handle
  /// [config] is the lazy loading configuration
  /// [headers] are additional headers to send with the request
  Future<LazyLoadResult> handleLazyLoading({
    required String url,
    required LazyLoadConfig config,
    Map<String, String>? headers,
  }) async {
    if (!config.handleLazyLoading) {
      // If lazy loading is disabled, just fetch the HTML
      final html = await _fetchHtml(url, headers);
      return LazyLoadResult.original(html);
    }

    try {
      // First, fetch the HTML normally
      final html = await _fetchHtml(url, headers);

      // Detect lazy loading
      final detectionResult = _lazyLoadDetector.detectLazyLoading(html);
      final lazyLoadingDetected = detectionResult.hasLazyLoading;

      if (!lazyLoadingDetected) {
        // If no lazy loading is detected, return the original HTML
        logger?.info('No lazy loading detected for $url');
        return LazyLoadResult.original(html);
      }

      logger?.info(
        'Detected ${detectionResult.type} lazy loading for $url. '
        'Requires JavaScript: ${detectionResult.requiresJavaScript}, '
        'Requires scrolling: ${detectionResult.requiresScrolling}, '
        'Requires interaction: ${detectionResult.requiresInteraction}',
      );

      // If lazy loading is detected but doesn't require JavaScript, scrolling, or interaction,
      // return the original HTML
      if (!detectionResult.requiresJavaScript &&
          !detectionResult.requiresScrolling &&
          !detectionResult.requiresInteraction) {
        return LazyLoadResult.original(html);
      }

      // If lazy loading requires JavaScript, scrolling, or interaction,
      // use a headless browser if enabled
      if (config.useHeadlessBrowser) {
        final startTime = DateTime.now();
        int scrollCount = 0;
        int clickCount = 0;

        // Configure the headless browser
        final browserConfig = HeadlessBrowserConfig(
          url: url,
          headers: headers,
          waitForDomContentLoaded: config.waitForDomContentLoaded,
          waitForNetworkIdle: config.waitForNetworkIdle,
          timeout: config.maxWaitTimeMs,
          userAgent: headers?['User-Agent'],
        );

        // Launch the headless browser
        logger?.info('Launching headless browser for $url');
        final browser = await _headlessBrowser.launch(browserConfig);

        try {
          // Scroll if needed
          if (detectionResult.requiresScrolling) {
            logger?.info('Scrolling to reveal lazy-loaded content');
            for (int i = 0; i < config.maxScrollDepth; i++) {
              // Scroll down
              await browser.executeScript(
                'window.scrollBy(0, ${config.scrollStepSize * 100}vh);',
              );
              scrollCount++;

              // Wait for content to load
              await Future.delayed(
                Duration(milliseconds: config.scrollDelayMs),
              );

              // Check if we've reached the bottom of the page
              final isAtBottom =
                  await browser.executeScript(
                        'return (window.innerHeight + window.scrollY) >= document.body.scrollHeight;',
                      )
                      as bool;

              if (isAtBottom) {
                logger?.info('Reached the bottom of the page');
                break;
              }
            }
          }

          // Click on load more buttons if needed
          if (detectionResult.requiresInteraction &&
              config.clickLoadMoreButtons &&
              detectionResult.triggerElements.isNotEmpty) {
            logger?.info('Clicking on load more buttons');
            for (final element in detectionResult.triggerElements) {
              // Try to find the element by various attributes
              final id = element.id;
              final classes = element.classes.join(' ');
              final text = element.text.trim();

              String? selector;
              if (id.isNotEmpty) {
                selector = '#$id';
              } else if (classes.isNotEmpty) {
                selector = '.${classes.replaceAll(' ', '.')}';
              } else if (text.isNotEmpty) {
                selector = 'button:contains("$text"), a:contains("$text")';
              }

              if (selector != null) {
                try {
                  // Click the element
                  await browser.click(selector);
                  clickCount++;

                  // Wait for content to load
                  await Future.delayed(
                    Duration(milliseconds: config.scrollDelayMs),
                  );
                } catch (e) {
                  logger?.warning(
                    'Failed to click element with selector "$selector": $e',
                  );
                }
              }
            }
          }

          // Get the final HTML
          final finalHtml = await browser.getPageSource();
          final endTime = DateTime.now();
          final totalTimeMs = endTime.difference(startTime).inMilliseconds;

          logger?.info(
            'Lazy loading handled in ${totalTimeMs}ms. '
            'Scroll count: $scrollCount, Click count: $clickCount',
          );

          return LazyLoadResult(
            html: finalHtml,
            lazyLoadingDetected: true,
            lazyLoadType: detectionResult.type,
            scrollCount: scrollCount,
            clickCount: clickCount,
            totalTimeMs: totalTimeMs,
          );
        } finally {
          // Close the browser
          await browser.close();
        }
      } else {
        // If headless browser is disabled but lazy loading is detected,
        // return the original HTML with a warning
        logger?.warning(
          'Lazy loading detected but headless browser is disabled. '
          'Some content may not be available.',
        );
        return LazyLoadResult(
          html: html,
          lazyLoadingDetected: true,
          lazyLoadType: detectionResult.type,
          scrollCount: 0,
          clickCount: 0,
          totalTimeMs: 0,
        );
      }
    } catch (e) {
      logger?.error('Error handling lazy loading: $e');
      throw ScrapingException.lazyLoading(
        'Error handling lazy loading',
        originalException: e,
        isRetryable: true,
      );
    }
  }

  /// Fetches HTML from a URL
  Future<String> _fetchHtml(String url, Map<String, String>? headers) async {
    try {
      // Use a simple HTTP client to fetch the HTML
      final response = await _headlessBrowser.fetchHtml(
        url: url,
        headers: headers,
      );
      return response;
    } catch (e) {
      logger?.error('Error fetching HTML: $e');
      throw ScrapingException.network(
        'Error fetching HTML',
        originalException: e,
        isRetryable: true,
      );
    }
  }
}
