import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pivox/pivox.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/widgets/proxy_card.dart';
import 'dashboard_card.dart';

/// Widget for displaying the proxy list section
class ProxyListSection extends StatelessWidget {
  /// The list of proxies
  final List<ProxyModel> proxies;

  /// Whether the system is loading
  final bool isLoading;

  /// Callback for refreshing proxies
  final VoidCallback onRefresh;

  /// Creates a new [ProxyListSection]
  const ProxyListSection({
    super.key,
    required this.proxies,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingLarge),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (proxies.isEmpty) {
      return DashboardCard(
        title: 'No Proxies Available',
        icon: Ionicons.warning_outline,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Ionicons.cloud_offline_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: DesignTokens.spacingMedium),
                Text(
                  'No proxies available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: DesignTokens.spacingSmall),
                Text(
                  'Tap the refresh button to fetch proxies',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingLarge),
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Ionicons.refresh_outline),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < min(5, proxies.length); i++)
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  i < min(5, proxies.length) - 1
                      ? DesignTokens.spacingMedium
                      : 0,
            ),
            child: ProxyCard(proxy: proxies[i]),
          ),
        if (proxies.length > 5) ...[
          const SizedBox(height: DesignTokens.spacingMedium),
          OutlinedButton(
            onPressed: () {
              // Show all proxies
            },
            child: Text('View All ${proxies.length} Proxies'),
          ),
        ],
      ],
    );
  }
}
