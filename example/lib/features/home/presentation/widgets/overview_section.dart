import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/design/design_tokens.dart';
import '../../domain/entities/dashboard_metrics.dart';
import 'dashboard_card.dart';
import 'dashboard_metric.dart';

/// Widget for displaying the overview section
class OverviewSection extends StatelessWidget {
  /// The dashboard metrics
  final DashboardMetrics metrics;

  /// Creates a new [OverviewSection]
  const OverviewSection({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Proxy Metrics',
      icon: Ionicons.stats_chart_outline,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DashboardMetric(
                  title: 'Active Proxies',
                  value: '${metrics.activeProxies}/${metrics.totalProxies}',
                  changePercentage:
                      metrics.totalProxies > 0
                          ? (metrics.activeProxies / metrics.totalProxies) * 100 - 50
                          : 0.0,
                ),
              ),
              Expanded(
                child: DashboardMetric(
                  title: 'Success Rate',
                  value: '${metrics.successRate.toStringAsFixed(1)}%',
                  changePercentage: metrics.successRate - 75.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingLarge),
          Row(
            children: [
              Expanded(
                child: DashboardMetric(
                  title: 'Avg. Response Time',
                  value: '${metrics.avgResponseTime.toStringAsFixed(0)}ms',
                  changePercentage:
                      metrics.avgResponseTime > 0
                          ? (1000 - metrics.avgResponseTime) / 10
                          : 0.0,
                ),
              ),
              Expanded(
                child: DashboardMetric(
                  title: 'Last Updated',
                  value: metrics.lastUpdated.toString().substring(11, 19),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
