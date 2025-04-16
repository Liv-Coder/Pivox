import 'package:pivox/pivox.dart';

import '../entities/dashboard_metrics.dart';

/// Repository interface for proxy operations in the home feature
abstract class HomeProxyRepository {
  /// Fetches proxies with the given options
  Future<List<ProxyModel>> fetchProxies({
    ProxyFilterOptions? options,
  });

  /// Tests a proxy connection with the given URL
  Future<String> testProxyConnection(String url);

  /// Calculates dashboard metrics from the given proxies
  DashboardMetrics calculateMetrics(List<ProxyModel> proxies);
}
