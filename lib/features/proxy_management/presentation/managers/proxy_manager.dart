import '../../../../core/errors/exceptions.dart';
import '../../data/cache/proxy_cache_manager.dart';
import '../../data/models/proxy_model.dart';
import '../../domain/entities/proxy.dart';
import '../../domain/entities/proxy_analytics.dart';
import '../../domain/entities/proxy_filter_options.dart';
import '../../domain/services/proxy_analytics_service.dart';
import '../../domain/services/proxy_preloader_service.dart';
import '../../domain/strategies/proxy_rotation_strategy.dart'
    hide RotationStrategyType;
import '../../domain/strategies/rotation_strategy_factory.dart';
import '../../domain/usecases/get_proxies.dart';
import '../../domain/usecases/get_validated_proxies.dart';
import '../../domain/usecases/validate_proxy.dart';

/// Manager for proxy operations
class ProxyManager {
  /// Use case for getting proxies
  final GetProxies getProxies;

  /// Use case for validating proxies
  final ValidateProxy validateProxy;

  /// Use case for getting validated proxies
  final GetValidatedProxies getValidatedProxies;

  /// List of currently available proxies
  List<Proxy> _proxies = [];

  /// List of currently validated proxies
  List<Proxy> _validatedProxies = [];

  // No longer needed with rotation strategies

  /// Proxy rotation strategy
  ProxyRotationStrategy _rotationStrategy;

  /// Proxy preloader service
  final ProxyPreloaderService? _preloaderService;

  /// Analytics service for tracking proxy usage
  final ProxyAnalyticsService? analyticsService;

  /// Creates a new [ProxyManager] with the given use cases
  ProxyManager({
    required this.getProxies,
    required this.validateProxy,
    required this.getValidatedProxies,
    this.analyticsService,
    ProxyPreloaderService? preloaderService,
    ProxyCacheManager? cacheManager,
    RotationStrategyType strategyType = RotationStrategyType.roundRobin,
  }) : _preloaderService = preloaderService,
       _rotationStrategy = RotationStrategyFactory.createStrategy(
         type: strategyType,
         proxies: [],
       ) {
    // Start the preloader service if provided
    _preloaderService?.start();
  }

  /// Fetches proxies from various sources with advanced filtering options
  ///
  /// [options] contains all the filtering options
  Future<List<Proxy>> fetchProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(),
  }) async {
    _proxies = await getProxies(options: options);
    return _proxies;
  }

  /// Fetches proxies from various sources with legacy parameters
  ///
  /// This is kept for backward compatibility
  ///
  /// [count] is the number of proxies to fetch
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  @Deprecated('Use fetchProxies with ProxyFilterOptions instead')
  Future<List<Proxy>> fetchProxiesLegacy({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  }) async {
    return fetchProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
    );
  }

  /// Gets a list of validated proxies with advanced filtering options
  ///
  /// [options] contains all the filtering options
  /// [onProgress] is a callback for progress updates during validation
  Future<List<Proxy>> fetchValidatedProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(count: 10),
    void Function(int completed, int total)? onProgress,
  }) async {
    _validatedProxies = await getValidatedProxies(
      options: options,
      onProgress: onProgress,
    );

    return _validatedProxies;
  }

  /// Gets a list of validated proxies with legacy parameters
  ///
  /// This is kept for backward compatibility
  ///
  /// [count] is the number of proxies to return
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  /// [onProgress] is a callback for progress updates during validation
  @Deprecated('Use fetchValidatedProxies with ProxyFilterOptions instead')
  Future<List<Proxy>> fetchValidatedProxiesLegacy({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) async {
    return fetchValidatedProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
      onProgress: onProgress,
    );
  }

  /// Gets the next proxy in the rotation
  ///
  /// [validated] determines whether to use validated proxies
  /// [useScoring] determines whether to use the scoring system for selection
  /// [strategyType] determines the rotation strategy to use
  Proxy getNextProxy({
    bool validated = true,
    bool useScoring = false,
    RotationStrategyType strategyType = RotationStrategyType.roundRobin,
  }) {
    final proxies = validated ? _validatedProxies : _proxies;

    if (proxies.isEmpty) {
      throw NoValidProxiesException();
    }

    if (useScoring) {
      // Use weighted selection based on proxy scores
      final proxyModels = proxies.whereType<ProxyModel>().toList();
      if (proxyModels.isEmpty) {
        // Fall back to the specified strategy if no models with scores are available
        _rotationStrategy = RotationStrategyFactory.createStrategy(
          type: strategyType,
          proxies: proxies,
        );
        return _rotationStrategy.selectProxy(proxies);
      }

      // Use weighted strategy for scoring
      _rotationStrategy = RotationStrategyFactory.createStrategy(
        type: RotationStrategyType.weighted,
        proxies: proxyModels,
      );
      return _rotationStrategy.selectProxy(proxyModels);
    } else {
      // Use the specified strategy
      _rotationStrategy = RotationStrategyFactory.createStrategy(
        type: strategyType,
        proxies: proxies,
      );
      return _rotationStrategy.selectProxy(proxies);
    }
  }

  /// Gets a random proxy
  ///
  /// [validated] determines whether to use validated proxies
  /// [useScoring] determines whether to use the scoring system for weighted selection
  Proxy getRandomProxy({bool validated = true, bool useScoring = false}) {
    final proxies = validated ? _validatedProxies : _proxies;

    if (proxies.isEmpty) {
      throw NoValidProxiesException();
    }

    if (useScoring) {
      // Use weighted selection based on proxy scores
      return getNextProxy(
        validated: validated,
        useScoring: true,
        strategyType: RotationStrategyType.weighted,
      );
    } else {
      // Use simple random selection
      _rotationStrategy = RotationStrategyFactory.createStrategy(
        type: RotationStrategyType.random,
        proxies: proxies,
      );
      return _rotationStrategy.selectProxy(proxies);
    }
  }

  // No longer needed with rotation strategies

  /// Validates a specific proxy
  ///
  /// [proxy] is the proxy to validate
  /// [testUrl] is the URL to use for testing
  /// [timeout] is the timeout in milliseconds
  /// [updateScore] determines whether to update the proxy's score
  Future<bool> validateSpecificProxy(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
    bool updateScore = true,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final isValid = await validateProxy(
      proxy,
      testUrl: testUrl,
      timeout: timeout,
    );
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final responseTime = endTime - startTime;

    // Update the proxy's score if requested and it's a ProxyModel
    if (updateScore && proxy is ProxyModel) {
      final updatedProxy =
          isValid
              ? proxy.withSuccessfulRequest(responseTime)
              : proxy.withFailedRequest();

      // Update the proxy in the lists
      _updateProxyInLists(proxy, updatedProxy);
    }

    return isValid;
  }

  /// Updates a proxy in the internal lists
  void _updateProxyInLists(Proxy oldProxy, Proxy newProxy) {
    // Update in the proxies list
    final proxyIndex = _proxies.indexWhere(
      (p) => p.ip == oldProxy.ip && p.port == oldProxy.port,
    );

    if (proxyIndex >= 0) {
      _proxies[proxyIndex] = newProxy;
    }

    // Update in the validated proxies list
    final validatedProxyIndex = _validatedProxies.indexWhere(
      (p) => p.ip == oldProxy.ip && p.port == oldProxy.port,
    );

    if (validatedProxyIndex >= 0) {
      _validatedProxies[validatedProxyIndex] = newProxy;
    }
  }

  /// Gets the current list of proxies
  List<Proxy> get proxies => List.unmodifiable(_proxies);

  /// Gets the current list of validated proxies
  List<Proxy> get validatedProxies => List.unmodifiable(_validatedProxies);

  /// Gets the current analytics data
  ///
  /// Returns null if analytics is not enabled
  Future<ProxyAnalytics?> getAnalytics() async {
    if (analyticsService == null) {
      return null;
    }

    return analyticsService!.getAnalytics();
  }

  /// Resets the analytics data
  ///
  /// Does nothing if analytics is not enabled
  Future<void> resetAnalytics() async {
    if (analyticsService != null) {
      await analyticsService!.resetAnalytics();
    }
  }

  /// Sets the proxy rotation strategy
  ///
  /// [strategyType] is the type of rotation strategy to use
  void setRotationStrategy(RotationStrategyType strategyType) {
    _rotationStrategy = RotationStrategyFactory.createStrategy(
      type: strategyType,
      proxies: _validatedProxies,
    );
  }

  /// Gets the least recently used proxy
  ///
  /// [validated] determines whether to use validated proxies
  Proxy getLeastRecentlyUsedProxy({bool validated = true}) {
    final proxies = validated ? _validatedProxies : _proxies;

    if (proxies.isEmpty) {
      throw NoValidProxiesException();
    }

    _rotationStrategy = RotationStrategyFactory.createStrategy(
      type: RotationStrategyType.geoBased,
      proxies: proxies,
    );
    return _rotationStrategy.selectProxy(proxies);
  }
}
