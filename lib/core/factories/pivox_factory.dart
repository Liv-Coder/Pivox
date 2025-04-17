import 'package:http/http.dart' as http;

import '../../features/proxy_management/presentation/managers/proxy_manager.dart';
import '../../features/http_integration/http/http_proxy_client.dart';
import '../../features/web_scraping/web_scraper.dart';
import '../../features/web_scraping/advanced_web_scraper.dart';
import '../../features/web_scraping/concurrent_web_scraper.dart';
import '../../features/web_scraping/streaming_html_parser.dart';
import '../../features/web_scraping/memory_efficient_parser.dart';
import '../../features/web_scraping/scraping_task_queue.dart';
import '../../features/web_scraping/scraping_logger.dart';
import '../../features/web_scraping/robots_txt_handler.dart';
import '../../features/web_scraping/enhanced_rate_limiter.dart';
import '../../features/web_scraping/cookie_manager.dart';
import '../../features/web_scraping/headless_browser/headless_browser_service.dart';
import '../../features/web_scraping/headless_browser/headless_browser_config.dart';

/// Factory class for creating Pivox components
class PivoxFactory {
  /// Creates a new HTTP client with proxy support
  ///
  /// [proxyManager] is the proxy manager to use
  /// [useValidatedProxies] whether to use validated proxies
  /// [rotateProxies] whether to rotate proxies
  static Future<http.Client> createHttpClient({
    required ProxyManager proxyManager,
    bool useValidatedProxies = true,
    bool rotateProxies = true,
  }) async {
    return ProxyHttpClient(
      proxyManager: proxyManager,
      useValidatedProxies: useValidatedProxies,
      rotateProxies: rotateProxies,
    );
  }

  /// Creates a new web scraper
  ///
  /// [proxyManager] is the proxy manager to use
  /// [httpClient] is the HTTP client to use
  /// [defaultUserAgent] is the default user agent to use
  /// [defaultHeaders] are the default headers to use
  /// [defaultTimeout] is the default timeout for requests in milliseconds
  /// [maxRetries] is the maximum number of retry attempts
  /// [respectRobotsTxt] whether to respect robots.txt rules
  static WebScraper createWebScraper({
    required ProxyManager proxyManager,
    ProxyHttpClient? httpClient,
    String? defaultUserAgent,
    Map<String, String>? defaultHeaders,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    bool respectRobotsTxt = true,
  }) {
    final logger = ScrapingLogger();
    final robotsTxtHandler = RobotsTxtHandler(
      proxyManager: proxyManager,
      logger: logger,
      respectRobotsTxt: respectRobotsTxt,
    );
    final streamingParser = StreamingHtmlParser(logger: logger);

    return WebScraper(
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
    );
  }

  /// Creates a new advanced web scraper
  ///
  /// [proxyManager] is the proxy manager to use
  /// [defaultTimeout] is the default timeout for requests in milliseconds
  /// [maxRetries] is the maximum number of retry attempts
  /// [handleCookies] whether to handle cookies
  /// [followRedirects] whether to follow redirects
  /// [respectRobotsTxt] whether to respect robots.txt rules
  /// [maxConcurrentTasks] is the maximum number of concurrent tasks
  static Future<AdvancedWebScraper> createAdvancedWebScraper({
    required ProxyManager proxyManager,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    bool handleCookies = true,
    bool followRedirects = true,
    bool respectRobotsTxt = true,
    int maxConcurrentTasks = 5,
  }) async {
    return AdvancedWebScraper.create(
      proxyManager: proxyManager,
      defaultTimeout: defaultTimeout,
      maxRetries: maxRetries,
      handleCookies: handleCookies,
      followRedirects: followRedirects,
      respectRobotsTxt: respectRobotsTxt,
      maxConcurrentTasks: maxConcurrentTasks,
    );
  }

  /// Creates a new concurrent web scraper
  ///
  /// [proxyManager] is the proxy manager to use
  /// [maxConcurrentTasks] is the maximum number of concurrent tasks
  /// [defaultTimeout] is the default timeout for requests in milliseconds
  /// [maxRetries] is the maximum number of retry attempts
  /// [respectRobotsTxt] whether to respect robots.txt rules
  static Future<ConcurrentWebScraper> createConcurrentWebScraper({
    required ProxyManager proxyManager,
    int maxConcurrentTasks = 5,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    bool respectRobotsTxt = true,
  }) async {
    return ConcurrentWebScraper.create(
      proxyManager: proxyManager,
      maxConcurrentTasks: maxConcurrentTasks,
      defaultTimeout: defaultTimeout,
      maxRetries: maxRetries,
      respectRobotsTxt: respectRobotsTxt,
    );
  }

  /// Creates a new streaming HTML parser
  ///
  /// [logger] is the logger to use
  static StreamingHtmlParser createStreamingHtmlParser({
    ScrapingLogger? logger,
  }) {
    return StreamingHtmlParser(logger: logger);
  }

  /// Creates a new memory-efficient HTML parser
  ///
  /// [logger] is the logger to use
  static MemoryEfficientParser createMemoryEfficientParser({
    ScrapingLogger? logger,
  }) {
    return MemoryEfficientParser(logger: logger);
  }

  /// Creates a new scraping task queue
  ///
  /// [maxConcurrentTasks] is the maximum number of concurrent tasks
  /// [logger] is the logger to use
  static ScrapingTaskQueue createScrapingTaskQueue({
    int maxConcurrentTasks = 5,
    ScrapingLogger? logger,
  }) {
    return ScrapingTaskQueue(
      maxConcurrentTasks: maxConcurrentTasks,
      logger: logger,
    );
  }

  /// Creates a new headless browser service
  ///
  /// [config] is the configuration for the headless browser
  /// [proxyManager] is the proxy manager to use
  /// [useProxies] whether to use proxies
  /// [rotateProxies] whether to rotate proxies
  /// [maxRetries] is the maximum number of retry attempts
  static Future<HeadlessBrowserService> createHeadlessBrowserService({
    HeadlessBrowserConfig? config,
    ProxyManager? proxyManager,
    bool useProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
  }) async {
    final logger = ScrapingLogger();
    final service = HeadlessBrowserService(
      config: config,
      proxyManager: proxyManager,
      logger: logger,
      useProxies: useProxies && proxyManager != null,
      rotateProxies: rotateProxies && proxyManager != null,
      maxRetries: maxRetries,
    );

    await service.initialize();
    return service;
  }

  /// Creates a new enhanced rate limiter
  ///
  /// [defaultDelayMs] is the default delay between requests in milliseconds
  /// [robotsTxtHandler] is the robots.txt handler to use
  /// [maxRetries] is the maximum number of retry attempts
  /// [logger] is the logger to use
  static EnhancedRateLimiter createEnhancedRateLimiter({
    int defaultDelayMs = 1000,
    RobotsTxtHandler? robotsTxtHandler,
    int maxRetries = 3,
    ScrapingLogger? logger,
  }) {
    return EnhancedRateLimiter(
      defaultDelayMs: defaultDelayMs,
      robotsTxtHandler: robotsTxtHandler,
      maxRetries: maxRetries,
      logger: logger,
    );
  }

  /// Creates a new cookie manager
  static Future<CookieManager> createCookieManager() async {
    return CookieManager.create();
  }
}
