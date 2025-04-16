import 'package:pivox/pivox.dart';

import '../../../../core/services/proxy_service.dart';
import '../../domain/entities/dashboard_metrics.dart';
import '../../domain/repositories/proxy_repository.dart';

/// Implementation of [HomeProxyRepository]
class HomeProxyRepositoryImpl implements HomeProxyRepository {
  /// The proxy service
  final ProxyService _proxyService;

  /// Creates a new [HomeProxyRepositoryImpl]
  HomeProxyRepositoryImpl(this._proxyService);

  @override
  Future<List<ProxyModel>> fetchProxies({
    ProxyFilterOptions? options,
  }) async {
    final proxies = await _proxyService.fetchProxies(
      options: options ?? ProxyFilterOptions(count: 20, onlyHttps: true),
    );

    return proxies.map(
      (p) => ProxyModel(
        ip: p.ip,
        port: p.port,
        countryCode: p.countryCode,
        isHttps: p.isHttps,
        anonymityLevel: p.anonymityLevel,
        responseTime: p is ProxyModel ? p.responseTime : null,
      ),
    ).toList();
  }

  @override
  Future<String> testProxyConnection(String url) async {
    return _proxyService.makeHttpRequest(url);
  }

  @override
  DashboardMetrics calculateMetrics(List<ProxyModel> proxies) {
    final totalProxies = proxies.length;
    final activeProxies = proxies
        .where(
          (p) => p.responseTime != null && p.responseTime! < 2000,
        )
        .length;

    // Calculate success rate and average response time
    int validProxies = 0;
    double totalResponseTime = 0.0;

    for (final proxy in proxies) {
      if (proxy.responseTime != null) {
        validProxies++;
        totalResponseTime += proxy.responseTime!.toDouble();
      }
    }

    final successRate =
        validProxies > 0 ? (validProxies / totalProxies) * 100 : 0.0;
    final avgResponseTime =
        validProxies > 0 ? totalResponseTime / validProxies : 0.0;

    return DashboardMetrics(
      activeProxies: activeProxies,
      totalProxies: totalProxies,
      successRate: successRate,
      avgResponseTime: avgResponseTime,
      lastUpdated: DateTime.now(),
    );
  }
}
