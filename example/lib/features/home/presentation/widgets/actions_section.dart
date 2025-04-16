import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/design/design_tokens.dart';
import 'dashboard_card.dart';

/// Widget for displaying the actions section
class ActionsSection extends StatelessWidget {
  /// Whether the system is loading
  final bool isLoading;

  /// Callback for refreshing proxies
  final VoidCallback onRefresh;

  /// Callback for validating proxies
  final VoidCallback onValidate;

  /// Callback for clearing cache
  final VoidCallback onClearCache;

  /// Creates a new [ActionsSection]
  const ActionsSection({
    super.key,
    required this.isLoading,
    required this.onRefresh,
    required this.onValidate,
    required this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Actions',
      icon: Ionicons.options_outline,
      child: Column(
        children: [
          _buildActionButton(
            context,
            'Refresh Proxies',
            Ionicons.refresh_outline,
            onRefresh,
            isLoading: isLoading,
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildActionButton(
            context,
            'Validate Proxies',
            Ionicons.checkmark_circle_outline,
            onValidate,
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildActionButton(
            context,
            'Clear Cache',
            Ionicons.trash_outline,
            onClearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed, {
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(icon),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}
