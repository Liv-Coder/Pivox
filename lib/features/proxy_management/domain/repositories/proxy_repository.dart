import '../entities/proxy.dart';

/// Repository interface for proxy management
abstract class ProxyRepository {
  /// Fetches a list of proxies from various sources
  /// 
  /// [count] is the number of proxies to fetch
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  Future<List<Proxy>> fetchProxies({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  });
  
  /// Validates a proxy by testing its connectivity
  /// 
  /// [proxy] is the proxy to validate
  /// [testUrl] is the URL to use for testing
  /// [timeout] is the timeout in milliseconds
  Future<bool> validateProxy(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
  });
  
  /// Gets a list of validated proxies
  /// 
  /// [count] is the number of proxies to return
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  Future<List<Proxy>> getValidatedProxies({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
  });
}
