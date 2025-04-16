import 'package:pivox/pivox.dart';

import '../entities/dashboard_metrics.dart';
import '../repositories/proxy_repository.dart';

/// Use case for fetching proxies and calculating metrics
class FetchProxies {
  /// The repository for proxy operations
  final HomeProxyRepository repository;

  /// Creates a new [FetchProxies] use case
  FetchProxies(this.repository);

  /// Executes the use case
  ///
  /// Returns a tuple of (proxies, metrics)
  Future<(List<ProxyModel>, DashboardMetrics)> call({
    ProxyFilterOptions? options,
  }) async {
    final proxies = await repository.fetchProxies(options: options);
    final metrics = repository.calculateMetrics(proxies);
    return (proxies, metrics);
  }
}
