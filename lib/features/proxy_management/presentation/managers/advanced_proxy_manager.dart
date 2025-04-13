import '../../data/cache/proxy_cache_manager.dart';
import '../../domain/entities/proxy.dart';
import '../../domain/entities/proxy_filter_options.dart';
import '../../domain/entities/proxy_protocol.dart';
import '../../domain/repositories/proxy_repository.dart';
import '../../domain/services/proxy_analytics_service.dart';
import '../../domain/services/proxy_preloader_service.dart';
import '../../domain/strategies/proxy_rotation_strategy.dart'
    hide RotationStrategyType;
import '../../domain/strategies/rotation_strategy_factory.dart';

/// Advanced proxy manager with additional features
class AdvancedProxyManager {
  /// Repository for proxy operations
  final ProxyRepository _repository;

  /// Analytics service for tracking proxy usage
  final ProxyAnalyticsService? _analyticsService;

  /// Preloader service for preloading proxies
  final ProxyPreloaderService? _preloaderService;

  /// List of currently available proxies
  List<Proxy> _proxies = [];

  /// List of currently validated proxies
  List<Proxy> _validatedProxies = [];

  /// Current rotation strategy
  ProxyRotationStrategy _rotationStrategy;

  /// Current rotation strategy type
  RotationStrategyType _strategyType;

  /// Whether to use preloaded proxies
  bool _usePreloadedProxies = false;

  /// Creates a new [AdvancedProxyManager] with the given parameters
  AdvancedProxyManager({
    required ProxyRepository repository,
    ProxyAnalyticsService? analyticsService,
    ProxyPreloaderService? preloaderService,
    ProxyCacheManager? cacheManager,
    RotationStrategyType strategyType = RotationStrategyType.roundRobin,
  }) : _repository = repository,
       _analyticsService = analyticsService,
       _preloaderService = preloaderService,
       _strategyType = strategyType,
       _rotationStrategy = RotationStrategyFactory.createStrategy(
         type: strategyType,
         proxies: [],
       ) {
    // Start the preloader service if provided
    _preloaderService?.start();
  }

  /// Fetches proxies from various sources
  Future<List<Proxy>> fetchProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(),
  }) async {
    _proxies = await _repository.fetchProxies(options: options);
    return _proxies;
  }

  /// Validates a proxy
  Future<bool> validateProxy(Proxy proxy) async {
    return await _repository.validateProxy(proxy);
  }

  /// Gets validated proxies
  Future<List<Proxy>> getValidatedProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(count: 10),
    void Function(int completed, int total)? onProgress,
  }) async {
    _validatedProxies = await _repository.getValidatedProxies(
      options: options,
      onProgress: onProgress,
    );

    // Update the rotation strategy with the new proxies
    _rotationStrategy.updateProxies(_validatedProxies);

    return _validatedProxies;
  }

  /// Gets the next proxy from the rotation strategy
  Future<Proxy?> getNextProxy() async {
    if (_validatedProxies.isEmpty) {
      if (_usePreloadedProxies && _preloaderService != null) {
        // Try to get preloaded proxies
        final preloadedProxies = _preloaderService.getPreloadedProxies();
        if (preloadedProxies.isNotEmpty) {
          _validatedProxies = preloadedProxies;
          _rotationStrategy.updateProxies(_validatedProxies);
        } else {
          // If no preloaded proxies, try to get validated proxies
          try {
            await getValidatedProxies();
          } catch (e) {
            // If we can't get validated proxies, return null
            return null;
          }
        }
      } else {
        // If not using preloaded proxies, try to get validated proxies
        try {
          await getValidatedProxies();
        } catch (e) {
          // If we can't get validated proxies, return null
          return null;
        }
      }
    }

    if (_validatedProxies.isEmpty) {
      return null;
    }

    final proxy = _rotationStrategy.getNextProxy();

    // Track proxy usage
    if (proxy != null && _analyticsService != null) {
      await _analyticsService.recordRequest(proxy, true, null, 'usage');
    }

    return proxy;
  }

  /// Records a successful request with a proxy
  void recordSuccess(Proxy proxy) {
    _rotationStrategy.recordSuccess(proxy);
  }

  /// Records a failed request with a proxy
  void recordFailure(Proxy proxy) {
    _rotationStrategy.recordFailure(proxy);
  }

  /// Sets the proxy rotation strategy
  void setRotationStrategy(RotationStrategyType strategyType) {
    _strategyType = strategyType;
    _rotationStrategy = RotationStrategyFactory.createStrategy(
      type: strategyType,
      proxies: _validatedProxies,
    );
  }

  /// Gets the current rotation strategy type
  RotationStrategyType getRotationStrategyType() {
    return _strategyType;
  }

  /// Gets the name of the current rotation strategy
  String getRotationStrategyName() {
    return RotationStrategyFactory.getStrategyName(_strategyType);
  }

  /// Gets the description of the current rotation strategy
  String getRotationStrategyDescription() {
    return RotationStrategyFactory.getStrategyDescription(_strategyType);
  }

  /// Enables or disables the use of preloaded proxies
  void setUsePreloadedProxies(bool usePreloadedProxies) {
    _usePreloadedProxies = usePreloadedProxies;

    if (_usePreloadedProxies && _preloaderService != null) {
      final preloadedProxies = _preloaderService.getPreloadedProxies();
      if (preloadedProxies.isNotEmpty) {
        _validatedProxies = preloadedProxies;
        _rotationStrategy.updateProxies(_validatedProxies);
      }
    }
  }

  /// Gets whether preloaded proxies are being used
  bool getUsePreloadedProxies() {
    return _usePreloadedProxies;
  }

  /// Gets the cache statistics
  Map<String, dynamic>? getCacheStats() {
    return _preloaderService?.getCacheStats();
  }

  /// Gets a proxy with the specified protocol
  Future<Proxy?> getProxyWithProtocol(ProxyProtocol protocol) async {
    if (_validatedProxies.isEmpty) {
      try {
        await getValidatedProxies();
      } catch (e) {
        // If we can't get validated proxies, return null
        return null;
      }
    }

    // Find a proxy with the specified protocol
    final matchingProxies =
        _validatedProxies.where((p) => p.protocol == protocol).toList();
    if (matchingProxies.isEmpty) {
      return null;
    }

    // Use the rotation strategy to select from the matching proxies
    final tempStrategy = RotationStrategyFactory.createStrategy(
      type: _strategyType,
      proxies: matchingProxies,
    );

    final proxy = tempStrategy.getNextProxy();

    // Track proxy usage
    if (proxy != null && _analyticsService != null) {
      await _analyticsService.recordRequest(proxy, true, null, 'usage');
    }

    return proxy;
  }

  /// Gets a proxy from a specific country
  Future<Proxy?> getProxyFromCountry(String countryCode) async {
    if (_validatedProxies.isEmpty) {
      try {
        await getValidatedProxies();
      } catch (e) {
        // If we can't get validated proxies, return null
        return null;
      }
    }

    // Find a proxy from the specified country
    final matchingProxies =
        _validatedProxies
            .where(
              (p) => p.countryCode?.toLowerCase() == countryCode.toLowerCase(),
            )
            .toList();

    if (matchingProxies.isEmpty) {
      return null;
    }

    // Use the rotation strategy to select from the matching proxies
    final tempStrategy = RotationStrategyFactory.createStrategy(
      type: _strategyType,
      proxies: matchingProxies,
    );

    final proxy = tempStrategy.getNextProxy();

    // Track proxy usage
    if (proxy != null && _analyticsService != null) {
      await _analyticsService.recordRequest(proxy, true, null, 'usage');
    }

    return proxy;
  }

  /// Disposes the proxy manager
  void dispose() {
    _preloaderService?.stop();
  }
}
