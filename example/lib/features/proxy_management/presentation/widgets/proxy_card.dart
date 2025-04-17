import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/utils/formatter_utils.dart';
import '../../domain/entities/proxy_entity.dart';

/// Proxy card widget
class ProxyCard extends StatelessWidget {
  final ProxyEntity proxy;
  final VoidCallback? onTap;
  final VoidCallback? onTest;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  const ProxyCard({
    super.key,
    required this.proxy,
    this.onTap,
    this.onTest,
    this.onCopy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProxyIcon(context),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${proxy.ip}:${proxy.port}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (proxy.country != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${proxy.country}${proxy.city != null ? ', ${proxy.city}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildProxyDetails(context),
          const SizedBox(height: AppSpacing.md),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildProxyIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color:
            proxy.isValid
                ? const Color(0xFF10B981).withAlpha(25)
                : const Color(0xFFEF4444).withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Icon(
        Ionicons.server_outline,
        color:
            proxy.isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        size: 20,
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (proxy.isValid) {
      return const StatusBadge(
        type: StatusType.success,
        text: 'Valid',
        icon: Ionicons.checkmark_circle,
      );
    } else {
      return const StatusBadge(
        type: StatusType.error,
        text: 'Invalid',
        icon: Ionicons.close_circle,
      );
    }
  }

  Widget _buildProxyDetails(BuildContext context) {
    return Row(
      children: [
        _buildDetailItem(
          context,
          label: 'Type',
          value: proxy.type ?? 'HTTP',
          icon: Ionicons.git_network_outline,
        ),
        _buildDetailItem(
          context,
          label: 'Speed',
          value:
              proxy.speed != null
                  ? '${proxy.speed!.toStringAsFixed(2)} ms'
                  : 'Unknown',
          icon: Ionicons.speedometer_outline,
        ),
        _buildDetailItem(
          context,
          label: 'Success',
          value: FormatterUtils.formatPercentage(proxy.successRate * 100),
          icon: Ionicons.trending_up_outline,
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          context,
          icon: Ionicons.copy_outline,
          label: 'Copy',
          onTap: onCopy,
        ),
        _buildActionButton(
          context,
          icon: Ionicons.play_outline,
          label: 'Test',
          onTap: onTest,
        ),
        _buildActionButton(
          context,
          icon: Ionicons.trash_outline,
          label: 'Delete',
          onTap: onDelete,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
