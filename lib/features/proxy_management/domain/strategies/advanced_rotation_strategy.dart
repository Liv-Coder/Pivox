import '../entities/proxy.dart';
import 'proxy_rotation_strategy.dart';

/// Advanced proxy rotation strategy that uses multiple factors to select the next proxy
class AdvancedRotationStrategy implements ProxyRotationStrategy {
  /// The list of proxies to rotate through
  final List<Proxy> _proxies;

  /// The current index in the proxy list
  int _currentIndex = 0;

  /// The number of consecutive failures for each proxy
  final Map<String, int> _failureCount = {};

  /// The last time each proxy was used
  final Map<String, int> _lastUsedTime = {};

  /// The maximum number of consecutive failures before a proxy is skipped
  final int maxConsecutiveFailures;

  /// The minimum time in milliseconds between uses of the same proxy
  final int minTimeBetweenUses;

  /// Creates a new [AdvancedRotationStrategy] with the given parameters
  AdvancedRotationStrategy({
    required List<Proxy> proxies,
    this.maxConsecutiveFailures = 3,
    this.minTimeBetweenUses = 5000,
  }) : _proxies = List.from(proxies);

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Try to find a suitable proxy
    for (int i = 0; i < proxies.length; i++) {
      final index = (_currentIndex + i) % proxies.length;
      final proxy = proxies[index];
      final proxyKey = '${proxy.ip}:${proxy.port}';

      // Check if the proxy has too many consecutive failures
      final failures = _failureCount[proxyKey] ?? 0;
      if (failures >= maxConsecutiveFailures) {
        continue;
      }

      // Check if the proxy was used too recently
      final lastUsed = _lastUsedTime[proxyKey] ?? 0;
      if (now - lastUsed < minTimeBetweenUses) {
        continue;
      }

      // Update the current index and last used time
      _currentIndex = (index + 1) % proxies.length;
      _lastUsedTime[proxyKey] = now;

      return proxy;
    }

    // If no suitable proxy was found, reset failure counts and try again
    if (_allProxiesHaveTooManyFailures()) {
      _failureCount.clear();
      return selectProxy(proxies);
    }

    // If all proxies were used too recently, use the least recently used one
    final leastRecentlyUsed = _getLeastRecentlyUsedProxy();
    if (leastRecentlyUsed != null) {
      final proxyKey = '${leastRecentlyUsed.ip}:${leastRecentlyUsed.port}';
      _lastUsedTime[proxyKey] = now;
      return leastRecentlyUsed;
    }

    // Fallback to the first proxy
    return proxies.first;
  }

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Try to find a suitable proxy
    for (int i = 0; i < _proxies.length; i++) {
      final index = (_currentIndex + i) % _proxies.length;
      final proxy = _proxies[index];
      final proxyKey = '${proxy.ip}:${proxy.port}';

      // Check if the proxy has too many consecutive failures
      final failures = _failureCount[proxyKey] ?? 0;
      if (failures >= maxConsecutiveFailures) {
        continue;
      }

      // Check if the proxy was used too recently
      final lastUsed = _lastUsedTime[proxyKey] ?? 0;
      if (now - lastUsed < minTimeBetweenUses) {
        continue;
      }

      // Update the current index and last used time
      _currentIndex = (index + 1) % _proxies.length;
      _lastUsedTime[proxyKey] = now;

      return proxy;
    }

    // If no suitable proxy was found, reset failure counts and try again
    if (_allProxiesHaveTooManyFailures()) {
      _failureCount.clear();
      return getNextProxy();
    }

    // If all proxies were used too recently, use the least recently used one
    final leastRecentlyUsed = _getLeastRecentlyUsedProxy();
    if (leastRecentlyUsed != null) {
      final proxyKey = '${leastRecentlyUsed.ip}:${leastRecentlyUsed.port}';
      _lastUsedTime[proxyKey] = now;
      return leastRecentlyUsed;
    }

    return null;
  }

  @override
  void recordSuccess(Proxy proxy) {
    final proxyKey = '${proxy.ip}:${proxy.port}';
    _failureCount[proxyKey] = 0;
  }

  @override
  void recordFailure(Proxy proxy) {
    final proxyKey = '${proxy.ip}:${proxy.port}';
    _failureCount[proxyKey] = (_failureCount[proxyKey] ?? 0) + 1;
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
    _currentIndex = 0;

    // Remove failure counts and last used times for proxies that are no longer in the list
    final validKeys = proxies.map((p) => '${p.ip}:${p.port}').toSet();
    _failureCount.removeWhere((key, _) => !validKeys.contains(key));
    _lastUsedTime.removeWhere((key, _) => !validKeys.contains(key));
  }

  /// Returns true if all proxies have too many consecutive failures
  bool _allProxiesHaveTooManyFailures() {
    for (final proxy in _proxies) {
      final proxyKey = '${proxy.ip}:${proxy.port}';
      final failures = _failureCount[proxyKey] ?? 0;
      if (failures < maxConsecutiveFailures) {
        return false;
      }
    }
    return true;
  }

  /// Returns the least recently used proxy
  Proxy? _getLeastRecentlyUsedProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    Proxy? leastRecentlyUsed;
    int? leastRecentTime;

    for (final proxy in _proxies) {
      final proxyKey = '${proxy.ip}:${proxy.port}';
      final lastUsed = _lastUsedTime[proxyKey] ?? 0;

      if (leastRecentTime == null || lastUsed < leastRecentTime) {
        leastRecentlyUsed = proxy;
        leastRecentTime = lastUsed;
      }
    }

    return leastRecentlyUsed;
  }
}
