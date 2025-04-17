import 'package:flutter/material.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/app/app_layout.dart';

/// Feature card widget
class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int index;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: () {
        // Close the drawer if it's open
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.of(context).pop();
        }

        // Use the global key to access the AppLayout state
        // This is a safer approach than trying to navigate
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Navigate to the selected tab using the AppLayout state
          appLayoutKey.currentState?.navigateToTab(index);
        });
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
          ),
        ],
      ),
    );
  }
}
