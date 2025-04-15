import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';

/// A card widget for the dashboard
class DashboardCard extends StatelessWidget {
  /// The title of the card
  final String title;

  /// The icon to display
  final IconData icon;

  /// The child widget
  final Widget child;

  /// Whether to show the action button
  final bool showAction;

  /// The action button text
  final String? actionText;

  /// The action button callback
  final VoidCallback? onAction;

  /// Creates a new [DashboardCard]
  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.showAction = false,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        side: BorderSide(
          color:
              isDark
                  ? DesignTokens.darkBorderColor.withAlpha(128) // 0.5 opacity
                  : DesignTokens.borderColor,
          width: DesignTokens.borderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingMedium),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(
                      26,
                    ), // 0.1 opacity
                    borderRadius: BorderRadius.circular(
                      DesignTokens.borderRadiusCircular,
                    ),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: DesignTokens.spacingMedium),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ),
                if (showAction && actionText != null)
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(actionText!),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingMedium,
                        vertical: DesignTokens.spacingXSmall,
                      ),
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacingMedium,
              0,
              DesignTokens.spacingMedium,
              DesignTokens.spacingMedium,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
