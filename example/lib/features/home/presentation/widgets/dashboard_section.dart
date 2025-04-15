import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';

/// A section widget for the dashboard
class DashboardSection extends StatelessWidget {
  /// The title of the section
  final String title;
  
  /// The child widget
  final Widget child;
  
  /// Creates a new [DashboardSection]
  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: DesignTokens.spacingMedium,
            right: DesignTokens.spacingMedium,
            bottom: DesignTokens.spacingSmall,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
