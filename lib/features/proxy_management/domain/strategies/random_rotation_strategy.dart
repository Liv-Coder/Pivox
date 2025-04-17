import 'dart:math';

import '../entities/proxy.dart';
import 'proxy_rotation_strategy.dart';

/// Random proxy rotation strategy
class RandomRotationStrategy implements ProxyRotationStrategy {
  /// The list of proxies to rotate through
  final List<Proxy> _proxies;

  /// Random number generator
  final Random _random = Random();

  /// Creates a new [RandomRotationStrategy] with the given proxies
  RandomRotationStrategy({required List<Proxy> proxies})
    : _proxies = List.from(proxies);

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    final index = _random.nextInt(_proxies.length);
    return _proxies[index];
  }

  @override
  void recordSuccess(Proxy proxy) {
    // Random strategy doesn't need to track success
  }

  @override
  void recordFailure(Proxy proxy) {
    // Random strategy doesn't need to track failure
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
  }

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    final index = _random.nextInt(proxies.length);
    return proxies[index];
  }
}
