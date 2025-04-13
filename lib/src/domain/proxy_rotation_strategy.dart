import 'package:pivox/pivox.dart';

/// Interface for proxy rotation strategies.
/// 
/// Implementations of this interface define how proxies are rotated
/// when retrieving the next proxy from a pool.
abstract class ProxyRotationStrategy {
  /// Retrieves the next proxy according to the rotation strategy.
  /// 
  /// Returns null if no proxies are available.
  Future<Proxy?> getNextProxy();

  /// Adds a proxy to the rotation pool.
  /// 
  /// If the proxy already exists in the pool (based on equality),
  /// it will not be added again.
  Future<void> addProxy(Proxy proxy);
  
  /// Removes a proxy from the rotation pool.
  Future<void> removeProxy(Proxy proxy);
  
  /// Marks a proxy as inactive, excluding it from rotation.
  Future<void> markProxyAsInactive(Proxy proxy);
  
  /// Returns a list of all active proxies in the rotation pool.
  Future<List<Proxy>> getActiveProxies();
}
