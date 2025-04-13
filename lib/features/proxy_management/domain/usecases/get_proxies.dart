import '../entities/proxy.dart';
import '../repositories/proxy_repository.dart';

/// Use case for getting proxies
class GetProxies {
  /// Repository for proxy management
  final ProxyRepository repository;

  /// Creates a new [GetProxies] use case with the given [repository]
  const GetProxies(this.repository);

  /// Executes the use case to get proxies
  /// 
  /// [count] is the number of proxies to fetch
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  Future<List<Proxy>> call({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  }) {
    return repository.fetchProxies(
      count: count,
      onlyHttps: onlyHttps,
      countries: countries,
    );
  }
}
