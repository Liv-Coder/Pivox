import '../entities/proxy.dart';
import '../repositories/proxy_repository.dart';

/// Use case for getting validated proxies
class GetValidatedProxies {
  /// Repository for proxy management
  final ProxyRepository repository;

  /// Creates a new [GetValidatedProxies] use case with the given [repository]
  const GetValidatedProxies(this.repository);

  /// Executes the use case to get validated proxies
  ///
  /// [count] is the number of proxies to return
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  /// [onProgress] is a callback for progress updates during validation
  Future<List<Proxy>> call({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) {
    return repository.getValidatedProxies(
      count: count,
      onlyHttps: onlyHttps,
      countries: countries,
      onProgress: onProgress,
    );
  }
}
