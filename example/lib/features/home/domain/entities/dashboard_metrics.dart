/// Entity class for dashboard metrics
class DashboardMetrics {
  /// Number of active proxies
  final int activeProxies;

  /// Total number of proxies
  final int totalProxies;

  /// Success rate percentage
  final double successRate;

  /// Average response time in milliseconds
  final double avgResponseTime;

  /// Last updated timestamp
  final DateTime lastUpdated;

  /// Creates a new [DashboardMetrics] instance
  const DashboardMetrics({
    required this.activeProxies,
    required this.totalProxies,
    required this.successRate,
    required this.avgResponseTime,
    required this.lastUpdated,
  });

  /// Creates a copy of this [DashboardMetrics] with the given fields replaced with new values
  DashboardMetrics copyWith({
    int? activeProxies,
    int? totalProxies,
    double? successRate,
    double? avgResponseTime,
    DateTime? lastUpdated,
  }) {
    return DashboardMetrics(
      activeProxies: activeProxies ?? this.activeProxies,
      totalProxies: totalProxies ?? this.totalProxies,
      successRate: successRate ?? this.successRate,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
