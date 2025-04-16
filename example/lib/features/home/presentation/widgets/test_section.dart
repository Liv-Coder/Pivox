import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/design/design_tokens.dart';
import 'dashboard_card.dart';

/// Widget for displaying the test section
class TestSection extends StatelessWidget {
  /// Whether the system is loading
  final bool isLoading;

  /// Callback for testing proxy
  final VoidCallback onTest;

  /// Creates a new [TestSection]
  const TestSection({
    super.key,
    required this.isLoading,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Test Proxy',
      icon: Ionicons.flask_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test your proxy connection with a real request',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildActionButton(
            context,
            'Test HTTP Connection',
            Ionicons.globe_outline,
            onTest,
            isLoading: isLoading,
            isPrimary: true,
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
