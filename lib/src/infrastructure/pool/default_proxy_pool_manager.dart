import 'dart:async';

import 'package:pivox/pivox.dart';

/// Default implementation of the [ProxyPoolManager] interface.
///
/// This class manages a pool of proxies, handling the addition, removal,
/// and rotation of proxies. It can be configured with multiple proxy sources
/// and a rotation strategy.
class DefaultProxyPoolManager implements ProxyPoolManager {
  final List<ProxySource> _sources;
  final ProxyRotationStrategy _rotationStrategy;
  final Duration _refreshInterval;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  /// Creates a new [DefaultProxyPoolManager].
  ///
  /// [sources] is a list of [ProxySource] implementations that will be used to fetch proxies.
  /// [rotationStrategy] defines how proxies are rotated when retrieving the next proxy.
  /// [refreshInterval] defines how often the proxy pool should be refreshed from the sources.
  DefaultProxyPoolManager({
    required List<ProxySource> sources,
    required ProxyRotationStrategy rotationStrategy,
    Duration refreshInterval = const Duration(hours: 1),
  })  : _sources = sources,
        _rotationStrategy = rotationStrategy,
        _refreshInterval = refreshInterval {
    // Initial fetch of proxies
    _refreshProxies();

    // Set up periodic refresh
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshProxies());
  }

  /// Refreshes the proxy pool by fetching new proxies from all sources.
  Future<void> _refreshProxies() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    try {
      for (final source in _sources) {
        try {
          final proxies = await source.fetchProxies();
          for (final proxy in proxies) {
            await _rotationStrategy.addProxy(proxy);
          }
          source.updateLastFetchedTime();
        } catch (e) {
          // Log error but continue with other sources
          print('Error fetching proxies from ${source.sourceName}: $e');
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Future<Proxy?> getNextProxy() async {
    return _rotationStrategy.getNextProxy();
  }

  @override
  Future<void> addProxy(Proxy proxy) async {
    await _rotationStrategy.addProxy(proxy);
  }

  @override
  Future<void> removeProxy(Proxy proxy) async {
    await _rotationStrategy.removeProxy(proxy);
  }

  @override
  Future<void> markProxyAsInactive(Proxy proxy) async {
    await _rotationStrategy.markProxyAsInactive(proxy);
  }

  @override
  Future<List<Proxy>> getActiveProxies() async {
    return _rotationStrategy.getActiveProxies();
  }

  /// Manually triggers a refresh of the proxy pool.
  Future<void> refreshProxies() async {
    await _refreshProxies();
  }

  /// Disposes of resources used by this manager.
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
