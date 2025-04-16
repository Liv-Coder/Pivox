import 'dart:developer' as developer;

import '../../domain/entities/proxy.dart';
import '../../domain/entities/proxy_analytics.dart';
import '../../domain/entities/proxy_filter_options.dart';
import '../../domain/services/proxy_analytics_service.dart';
import '../../domain/strategies/rotation_strategy_factory.dart';
import '../../domain/usecases/get_proxies.dart';
import '../../domain/usecases/get_validated_proxies.dart';
import '../../domain/usecases/validate_proxy.dart';
import 'advanced_proxy_manager.dart';
import 'proxy_manager.dart';

/// Adapter for using [AdvancedProxyManager] as a [ProxyManager]
class AdvancedProxyManagerAdapter implements ProxyManager {
  /// The wrapped advanced proxy manager
  final AdvancedProxyManager _advancedProxyManager;

  /// Creates a new [AdvancedProxyManagerAdapter] with the given advanced proxy manager
  AdvancedProxyManagerAdapter(this._advancedProxyManager);

  @override
  GetProxies get getProxies =>
      throw UnimplementedError(
        'GetProxies use case is not directly accessible in AdvancedProxyManagerAdapter',
      );

  @override
  GetValidatedProxies get getValidatedProxies =>
      throw UnimplementedError(
        'GetValidatedProxies use case is not directly accessible in AdvancedProxyManagerAdapter',
      );

  @override
  ValidateProxy get validateProxy =>
      throw UnimplementedError(
        'ValidateProxy use case is not directly accessible in AdvancedProxyManagerAdapter',
      );

  @override
  Future<List<Proxy>> fetchProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(),
  }) async {
    return _advancedProxyManager.fetchProxies(options: options);
  }

  @override
  Future<List<Proxy>> fetchProxiesLegacy({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
  }) async {
    return _advancedProxyManager.fetchProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
    );
  }

  @override
  Future<List<Proxy>> fetchValidatedProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(),
    void Function(int completed, int total)? onProgress,
  }) async {
    return _advancedProxyManager.getValidatedProxies(
      options: options,
      onProgress: onProgress,
    );
  }

  @override
  Future<List<Proxy>> fetchValidatedProxiesLegacy({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) async {
    return _advancedProxyManager.getValidatedProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
      onProgress: onProgress,
    );
  }

  @override
  Proxy getNextProxy({
    RotationStrategyType? strategyType,
    bool useScoring = false,
    bool validated = true,
  }) {
    // This is a synchronous method in the interface but the advanced manager uses async
    // We'll have to return a placeholder proxy and log a warning
    developer.log(
      'Warning: getNextProxy in AdvancedProxyManagerAdapter is not fully compatible with ProxyManager',
    );
    return Proxy(ip: '0.0.0.0', port: 0);
  }

  /// Gets the next proxy asynchronously
  Future<Proxy?> getNextProxyAsync() async {
    return _advancedProxyManager.getNextProxy();
  }

  // This is a custom method, not part of the ProxyManager interface
  Future<bool> validateSingleProxy(Proxy proxy) async {
    return _advancedProxyManager.validateProxy(proxy);
  }

  @override
  Proxy getLeastRecentlyUsedProxy({bool validated = true}) {
    // Not directly supported in AdvancedProxyManager
    developer.log(
      'Warning: getLeastRecentlyUsedProxy in AdvancedProxyManagerAdapter is not fully compatible with ProxyManager',
    );
    return Proxy(ip: '0.0.0.0', port: 0);
  }

  @override
  Proxy getRandomProxy({bool useScoring = false, bool validated = true}) {
    // Not directly supported in AdvancedProxyManager
    developer.log(
      'Warning: getRandomProxy in AdvancedProxyManagerAdapter is not fully compatible with ProxyManager',
    );
    return Proxy(ip: '0.0.0.0', port: 0);
  }

  @override
  Future<ProxyAnalytics?> getAnalytics() async {
    // Not directly supported in AdvancedProxyManager
    return null;
  }

  @override
  ProxyAnalyticsService? get analyticsService => null;

  @override
  List<Proxy> get proxies => [];

  @override
  List<Proxy> get validatedProxies => [];

  @override
  Future<void> resetAnalytics() async {
    // Not directly supported in AdvancedProxyManager
  }

  @override
  Future<bool> validateSpecificProxy(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
    bool updateScore = true,
  }) async {
    return _advancedProxyManager.validateProxy(proxy);
  }

  @override
  Future<void> recordSuccess(Proxy proxy, [int? responseTimeMs]) async {
    _advancedProxyManager.recordSuccess(proxy);
  }

  @override
  Future<void> recordFailure(Proxy proxy) async {
    _advancedProxyManager.recordFailure(proxy);
  }

  @override
  void setRotationStrategy(dynamic strategyType) {
    if (strategyType is RotationStrategyType) {
      _advancedProxyManager.setRotationStrategy(strategyType);
    }
  }

  // This is a custom method, not part of the ProxyManager interface
  void dispose() {
    _advancedProxyManager.dispose();
  }
}
