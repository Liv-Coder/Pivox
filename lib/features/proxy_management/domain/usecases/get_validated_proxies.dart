import '../entities/proxy.dart';
import '../repositories/proxy_repository.dart';

/// Use case for getting validated proxies
class GetValidatedProxies {
  /// Repository for proxy management
  final ProxyRepository repository;

  /// Creates a new [GetValidatedProxies] use case with the given [repository]
  const GetValidatedProxies(this.repository);

  /// Executes the use case to get validated proxies with advanced filtering options
  ///
  /// [options] contains all the filtering options
  /// [onProgress] is a callback for progress updates during validation
  Future<List<Proxy>> call({
    ProxyFilterOptions options = const ProxyFilterOptions(count: 10),
    void Function(int completed, int total)? onProgress,
  }) {
    return repository.getValidatedProxies(
      options: options,
      onProgress: onProgress,
    );
  }

  /// Executes the use case to get validated proxies with legacy parameters
  ///
  /// This is kept for backward compatibility
  ///
  /// [count] is the number of proxies to return
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  /// [onProgress] is a callback for progress updates during validation
  @Deprecated('Use call with ProxyFilterOptions instead')
  Future<List<Proxy>> callLegacy({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) {
    return repository.getValidatedProxiesLegacy(
      count: count,
      onlyHttps: onlyHttps,
      countries: countries,
      onProgress: onProgress,
    );
  }
}
