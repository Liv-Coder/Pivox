import '../entities/proxy.dart';
import '../entities/proxy_filter_options.dart';
import '../entities/proxy_validation_options.dart';

/// Repository interface for proxy management
abstract class ProxyRepository {
  /// Fetches a list of proxies from various sources
  ///
  /// [options] contains all the filtering options
  Future<List<Proxy>> fetchProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(),
  });

  /// Fetches a list of proxies with legacy parameters
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
  }) {
    return fetchProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
    );
  }

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

  /// Validates a proxy with advanced options
  ///
  /// [proxy] is the proxy to validate
  /// [options] contains all the validation options
  Future<bool> validateProxyWithOptions(
    Proxy proxy, {
    ProxyValidationOptions options = const ProxyValidationOptions(),
  });

  /// Validates multiple proxies in parallel
  ///
  /// [proxies] is the list of proxies to validate
  /// [options] contains all the validation options
  /// [onProgress] is a callback for progress updates during validation
  Future<List<bool>> validateProxies(
    List<Proxy> proxies, {
    ProxyValidationOptions options = const ProxyValidationOptions(),
    void Function(int completed, int total)? onProgress,
  });

  /// Gets a list of validated proxies
  ///
  /// [options] contains all the filtering options
  /// [onProgress] is a callback for progress updates during validation
  Future<List<Proxy>> getValidatedProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(count: 10),
    void Function(int completed, int total)? onProgress,
  });

  /// Gets a list of validated proxies with legacy parameters
  ///
  /// This is kept for backward compatibility
  ///
  /// [count] is the number of proxies to return
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  /// [onProgress] is a callback for progress updates during validation
  @Deprecated('Use getValidatedProxies with ProxyFilterOptions instead')
  Future<List<Proxy>> getValidatedProxiesLegacy({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) {
    return getValidatedProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
      onProgress: onProgress,
    );
  }
}
