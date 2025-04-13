import '../entities/proxy.dart';
import '../repositories/proxy_repository.dart';

/// Use case for getting proxies
class GetProxies {
  /// Repository for proxy management
  final ProxyRepository repository;

  /// Creates a new [GetProxies] use case with the given [repository]
  const GetProxies(this.repository);

  /// Executes the use case to get proxies with advanced filtering options
  ///
  /// [options] contains all the filtering options
  Future<List<Proxy>> call({
    ProxyFilterOptions options = const ProxyFilterOptions(),
  }) {
    return repository.fetchProxies(options: options);
  }

  /// Executes the use case to get proxies with legacy parameters
  ///
  /// This is kept for backward compatibility
  ///
  /// [count] is the number of proxies to fetch
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  @Deprecated('Use call with ProxyFilterOptions instead')
  Future<List<Proxy>> callLegacy({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  }) {
    return repository.fetchProxiesLegacy(
      count: count,
      onlyHttps: onlyHttps,
      countries: countries,
    );
  }
}
