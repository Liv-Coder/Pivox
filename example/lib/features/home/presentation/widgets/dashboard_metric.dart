import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';

/// A metric widget for the dashboard
class DashboardMetric extends StatelessWidget {
  /// The title of the metric
  final String title;

  /// The value of the metric
  final String value;

  /// The change percentage
  final double? changePercentage;

  /// Creates a new [DashboardMetric]
  const DashboardMetric({
    super.key,
    required this.title,
    required this.value,
    this.changePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXSmall),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                letterSpacing: DesignTokens.letterSpacingTight,
              ),
            ),
            if (changePercentage != null) ...[
              const SizedBox(width: DesignTokens.spacingSmall),
              _buildChangeIndicator(context, changePercentage!),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildChangeIndicator(BuildContext context, double percentage) {
    final isPositive = percentage >= 0;
    final color =
        isPositive ? DesignTokens.successColor : DesignTokens.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSmall,
        vertical: DesignTokens.spacingXXSmall,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 opacity
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: DesignTokens.spacingXXSmall),
          Text(
            '${percentage.abs().toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }
}
