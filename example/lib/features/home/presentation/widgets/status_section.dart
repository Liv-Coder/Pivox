import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/design/design_tokens.dart';
import 'dashboard_card.dart';

/// Widget for displaying the system status section
class StatusSection extends StatelessWidget {
  /// Whether the system is loading
  final bool isLoading;

  /// The response text
  final String responseText;

  /// Creates a new [StatusSection]
  const StatusSection({
    super.key,
    required this.isLoading,
    required this.responseText,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'System Status',
      icon: Ionicons.pulse_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusItem(
            context,
            'Proxy Service',
            isLoading ? 'Loading' : 'Online',
            isLoading ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildStatusItem(context, 'HTTP Client', 'Ready', Colors.green),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildStatusItem(context, 'Dio Client', 'Ready', Colors.green),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildStatusItem(context, 'Cache', 'Synced', Colors.green),
          if (responseText.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingMedium),
            const Divider(),
            const SizedBox(height: DesignTokens.spacingSmall),
            Text(
              'Last Response:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXSmall),
            Text(
              responseText,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String name,
    String status,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: DesignTokens.spacingSmall),
        Text(name, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          status,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ],
    );
  }
}
