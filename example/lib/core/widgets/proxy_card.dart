import 'package:flutter/material.dart';
import 'package:pivox/pivox.dart';
import 'package:ionicons/ionicons.dart';
import '../design/design_tokens.dart';

/// A card widget that displays proxy information
class ProxyCard extends StatelessWidget {
  /// The proxy to display
  final ProxyModel proxy;

  /// Creates a new [ProxyCard] with the given [proxy]
  const ProxyCard({super.key, required this.proxy});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: DesignTokens.spacingSmall),
                Text(
                  '${proxy.ip}:${proxy.port}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                const Spacer(),
                _buildHttpsChip(),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingSmall),
            const Divider(),
            const SizedBox(height: DesignTokens.spacingSmall),
            Row(
              children: [
                _buildInfoItem(
                  context,
                  'Country',
                  proxy.countryCode ?? 'Unknown',
                  Ionicons.earth_outline,
                ),
                const SizedBox(width: DesignTokens.spacingLarge),
                _buildInfoItem(
                  context,
                  'Anonymity',
                  proxy.anonymityLevel ?? 'Unknown',
                  Ionicons.shield_outline,
                ),
              ],
            ),
            if (proxy.responseTime != null) ...[
              const SizedBox(height: DesignTokens.spacingMedium),
              _buildResponseTime(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the status indicator based on the proxy's response time
  Widget _buildStatusIndicator() {
    Color statusColor;

    if (proxy.responseTime == null) {
      statusColor = DesignTokens.textTertiaryColor;
    } else if (proxy.responseTime! < 500) {
      statusColor = DesignTokens.successColor;
    } else if (proxy.responseTime! < 1000) {
      statusColor = DesignTokens.warningColor;
    } else {
      statusColor = DesignTokens.errorColor;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
    );
  }

  /// Builds the HTTPS chip
  Widget _buildHttpsChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSmall,
        vertical: DesignTokens.spacingXXSmall,
      ),
      decoration: BoxDecoration(
        color:
            proxy.isHttps
                ? DesignTokens.successColor.withAlpha(25)
                : DesignTokens.errorColor.withAlpha(25),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusCircular),
      ),
      child: Text(
        proxy.isHttps ? 'HTTPS' : 'HTTP',
        style: TextStyle(
          fontSize: DesignTokens.fontSizeXSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color:
              proxy.isHttps
                  ? DesignTokens.successColor
                  : DesignTokens.errorColor,
        ),
      ),
    );
  }

  /// Builds an info item with a label and value
  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DesignTokens.textSecondaryColor),
        const SizedBox(width: DesignTokens.spacingXSmall),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  /// Builds the response time indicator
  Widget _buildResponseTime(BuildContext context) {
    final responseTime = proxy.responseTime!;

    Color barColor;
    if (responseTime < 500) {
      barColor = DesignTokens.successColor;
    } else if (responseTime < 1000) {
      barColor = DesignTokens.warningColor;
    } else {
      barColor = DesignTokens.errorColor;
    }

    // Calculate width percentage (max 2000ms)
    final widthPercentage = (responseTime / 2000).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Response Time', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text(
              '${responseTime}ms',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: barColor,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingXSmall),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: DesignTokens.dividerColor,
            borderRadius: BorderRadius.circular(
              DesignTokens.borderRadiusCircular,
            ),
          ),
          child: FractionallySizedBox(
            widthFactor: widthPercentage,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(
                  DesignTokens.borderRadiusCircular,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
