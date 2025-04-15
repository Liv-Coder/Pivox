import 'package:pivox/features/proxy_management/presentation/managers/proxy_manager.dart';
import 'package:pivox/features/web_scraping/dynamic_user_agent_manager.dart';
import 'package:pivox/features/web_scraping/headless_browser/headless_browser_config.dart';
import 'package:pivox/features/web_scraping/headless_browser/headless_browser_service.dart';
import 'package:pivox/features/web_scraping/headless_browser/specialized_headless_handlers.dart';
import 'package:pivox/features/web_scraping/scraping_logger.dart';
import 'package:pivox/features/web_scraping/site_reputation_tracker.dart';

/// Factory for creating headless browser instances
class HeadlessBrowserFactory {
  /// Creates a new headless browser service with default configuration
  static Future<HeadlessBrowserService> createService({
    ProxyManager? proxyManager,
    DynamicUserAgentManager? userAgentManager,
    SiteReputationTracker? reputationTracker,
    ScrapingLogger? logger,
    HeadlessBrowserConfig? config,
    bool useProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
  }) async {
    final service = HeadlessBrowserService(
      proxyManager: proxyManager,
      userAgentManager: userAgentManager,
      reputationTracker: reputationTracker,
      logger: logger,
      config: config ?? HeadlessBrowserConfig.defaultConfig(),
      useProxies: useProxies,
      rotateProxies: rotateProxies,
      maxRetries: maxRetries,
    );

    await service.initialize();
    return service;
  }

  /// Creates a new headless browser service optimized for performance
  static Future<HeadlessBrowserService> createPerformanceService({
    ProxyManager? proxyManager,
    DynamicUserAgentManager? userAgentManager,
    SiteReputationTracker? reputationTracker,
    ScrapingLogger? logger,
    bool useProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
  }) async {
    return await createService(
      proxyManager: proxyManager,
      userAgentManager: userAgentManager,
      reputationTracker: reputationTracker,
      logger: logger,
      config: HeadlessBrowserConfig.performance(),
      useProxies: useProxies,
      rotateProxies: rotateProxies,
      maxRetries: maxRetries,
    );
  }

  /// Creates a new headless browser service optimized for stealth
  static Future<HeadlessBrowserService> createStealthService({
    ProxyManager? proxyManager,
    DynamicUserAgentManager? userAgentManager,
    SiteReputationTracker? reputationTracker,
    ScrapingLogger? logger,
    bool useProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
  }) async {
    return await createService(
      proxyManager: proxyManager,
      userAgentManager: userAgentManager,
      reputationTracker: reputationTracker,
      logger: logger,
      config: HeadlessBrowserConfig.stealth(),
      useProxies: useProxies,
      rotateProxies: rotateProxies,
      maxRetries: maxRetries,
    );
  }

  /// Creates specialized handlers for problematic sites
  static Future<SpecializedHeadlessHandlers> createSpecializedHandlers({
    HeadlessBrowserService? service,
    ProxyManager? proxyManager,
    DynamicUserAgentManager? userAgentManager,
    SiteReputationTracker? reputationTracker,
    ScrapingLogger? logger,
    HeadlessBrowserConfig? config,
    bool useProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
  }) async {
    HeadlessBrowserService browserService;

    if (service != null) {
      browserService = service;
    } else {
      browserService = await createService(
        proxyManager: proxyManager,
        userAgentManager: userAgentManager,
        reputationTracker: reputationTracker,
        logger: logger,
        config: config ?? HeadlessBrowserConfig.stealth(),
        useProxies: useProxies,
        rotateProxies: rotateProxies,
        maxRetries: maxRetries,
      );
    }

    final handlers = SpecializedHeadlessHandlers(
      service: browserService,
      logger: logger,
    );

    await handlers.initialize();
    return handlers;
  }
}
