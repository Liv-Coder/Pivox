import 'package:pivox/pivox.dart';

/// A round-robin implementation of the [ProxyRotationStrategy] interface.
///
/// This strategy rotates through proxies in a sequential manner, cycling back
/// to the beginning after reaching the end of the list. It only returns active proxies.
class RoundRobinRotation implements ProxyRotationStrategy {
  final List<Proxy> _proxies = [];
  int _currentIndex = 0;

  @override
  Future<Proxy?> getNextProxy() async {
    // Filter for active proxies
    final activeProxies = _proxies.where((proxy) => proxy.isActive).toList();

    if (activeProxies.isEmpty) return null;

    // Ensure the index is within bounds of active proxies
    if (_currentIndex >= activeProxies.length) {
      _currentIndex = 0;
    }

    final proxy = activeProxies[_currentIndex];
    _currentIndex = (_currentIndex + 1) % activeProxies.length;
    return proxy;
  }

  @override
  Future<void> addProxy(Proxy proxy) async {
    if (!_proxies.contains(proxy)) {
      _proxies.add(proxy);
    }
  }

  @override
  Future<void> removeProxy(Proxy proxy) async {
    _proxies.removeWhere(
      (p) =>
          p.host == proxy.host && p.port == proxy.port && p.type == proxy.type,
    );

    // Reset index if we've removed all proxies
    if (_proxies.isEmpty) {
      _currentIndex = 0;
    }
    // Adjust index if we removed a proxy before the current index
    else if (_currentIndex >= _proxies.length) {
      _currentIndex = _proxies.length - 1;
    }
  }

  @override
  Future<void> markProxyAsInactive(Proxy proxy) async {
    final index = _proxies.indexWhere(
      (p) =>
          p.host == proxy.host && p.port == proxy.port && p.type == proxy.type,
    );

    if (index != -1) {
      // Create a new proxy with isActive set to false
      final updatedProxy = Proxy(
        host: proxy.host,
        port: proxy.port,
        username: proxy.username,
        password: proxy.password,
        type: proxy.type,
        lastChecked: DateTime.now(),
        responseTime: proxy.responseTime,
        isActive: false,
      );

      // Replace the old proxy with the updated one
      _proxies[index] = updatedProxy;
    }
  }

  @override
  Future<List<Proxy>> getActiveProxies() async {
    return _proxies.where((proxy) => proxy.isActive).toList();
  }
}
