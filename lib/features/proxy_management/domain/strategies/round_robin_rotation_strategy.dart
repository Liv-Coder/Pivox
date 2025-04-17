import '../entities/proxy.dart';
import 'proxy_rotation_strategy.dart';

/// Round-robin proxy rotation strategy
class RoundRobinRotationStrategy implements ProxyRotationStrategy {
  /// The list of proxies to rotate through
  final List<Proxy> _proxies;

  /// The current index in the proxy list
  int _currentIndex = 0;

  /// Creates a new [RoundRobinRotationStrategy] with the given proxies
  RoundRobinRotationStrategy({required List<Proxy> proxies})
    : _proxies = List.from(proxies);

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    final proxy = _proxies[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _proxies.length;
    return proxy;
  }

  @override
  void recordSuccess(Proxy proxy) {
    // Round-robin strategy doesn't need to track success
  }

  @override
  void recordFailure(Proxy proxy) {
    // Round-robin strategy doesn't need to track failure
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
    _currentIndex = 0;
  }

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    final proxy = proxies[_currentIndex];
    _currentIndex = (_currentIndex + 1) % proxies.length;
    return proxy;
  }
}
