import '../entities/proxy.dart';

/// Proxy filter options for fetching and filtering proxies
class ProxyFilterOptions {
  /// Maximum number of proxies to return
  final int count;

  /// Whether to only return HTTPS proxies
  final bool onlyHttps;

  /// List of country codes to filter by
  final List<String>? countries;

  /// List of regions to filter by
  final List<String>? regions;

  /// List of ISPs to filter by
  final List<String>? isps;

  /// Minimum speed in Mbps
  final double? minSpeed;

  /// Whether to only return proxies that support websockets
  final bool? requireWebsockets;

  /// Whether to only return proxies that support SOCKS protocol
  final bool? requireSocks;

  /// Specific SOCKS version to filter by
  final int? socksVersion;

  /// Whether to only return authenticated proxies
  final bool? requireAuthentication;

  /// Whether to only return anonymous proxies
  final bool? requireAnonymous;

  /// Creates a new [ProxyFilterOptions] instance
  const ProxyFilterOptions({
    this.count = 20,
    this.onlyHttps = false,
    this.countries,
    this.regions,
    this.isps,
    this.minSpeed,
    this.requireWebsockets,
    this.requireSocks,
    this.socksVersion,
    this.requireAuthentication,
    this.requireAnonymous,
  });
}

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
