import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/utils/formatter_utils.dart';

/// Proxy stats card widget
class ProxyStatsCard extends StatelessWidget {
  final int totalProxies;
  final int validProxies;
  final int invalidProxies;
  final double averageSpeed;
  final double successRate;

  const ProxyStatsCard({
    super.key,
    required this.totalProxies,
    required this.validProxies,
    required this.invalidProxies,
    required this.averageSpeed,
    required this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: null,
      enableHover: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  Ionicons.stats_chart_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Proxy Statistics',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildStatItem(
                context,
                label: 'Total',
                value: totalProxies.toString(),
                icon: Ionicons.server_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              _buildStatItem(
                context,
                label: 'Valid',
                value: validProxies.toString(),
                icon: Ionicons.checkmark_circle_outline,
                color: const Color(0xFF10B981),
              ),
              _buildStatItem(
                context,
                label: 'Invalid',
                value: invalidProxies.toString(),
                icon: Ionicons.close_circle_outline,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildStatItem(
                context,
                label: 'Avg. Speed',
                value: '${averageSpeed.toStringAsFixed(2)} ms',
                icon: Ionicons.speedometer_outline,
                color: const Color(0xFFF59E0B),
              ),
              _buildStatItem(
                context,
                label: 'Success Rate',
                value: FormatterUtils.formatPercentage(successRate * 100),
                icon: Ionicons.trending_up_outline,
                color: const Color(0xFF8B5CF6),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
