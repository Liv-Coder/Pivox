import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/widgets/base_screen.dart';
import '../../../../core/design/app_spacing.dart';
import '../widgets/feature_card.dart';
import '../widgets/stats_card.dart';

/// Home screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Pivox Demo',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: AppSpacing.lg),
            _buildStatsSection(context),
            const SizedBox(height: AppSpacing.xl),
            _buildFeaturesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Icon(
                  Ionicons.globe,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Pivox',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Proxy Rotation & Web Scraping Package',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This demo app showcases the features and capabilities of the Pivox package. Explore the different sections to see how Pivox can help you with proxy management and web scraping.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          children: const [
            StatsCard(
              title: 'Available Proxies',
              value: '250+',
              icon: Ionicons.server_outline,
              color: Color(0xFF3B82F6),
            ),
            StatsCard(
              title: 'Validated Proxies',
              value: '180+',
              icon: Ionicons.checkmark_circle_outline,
              color: Color(0xFF10B981),
            ),
            StatsCard(
              title: 'Scraping Jobs',
              value: '15',
              icon: Ionicons.code_outline,
              color: Color(0xFFF59E0B),
            ),
            StatsCard(
              title: 'Success Rate',
              value: '95%',
              icon: Ionicons.trending_up_outline,
              color: Color(0xFF8B5CF6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        const FeatureCard(
          title: 'Proxy Management',
          description: 'Manage and rotate proxies with advanced strategies',
          icon: Ionicons.server_outline,
          color: Color(0xFF3B82F6),
          index: 1,
        ),
        const FeatureCard(
          title: 'Web Scraping',
          description: 'Extract data from websites with powerful selectors',
          icon: Ionicons.code_outline,
          color: Color(0xFF10B981),
          index: 2,
        ),
        const FeatureCard(
          title: 'Headless Browser',
          description: 'Handle JavaScript-heavy sites with headless browser',
          icon: Ionicons.globe_outline,
          color: Color(0xFFF59E0B),
          index: 3,
        ),
        const FeatureCard(
          title: 'Analytics',
          description: 'Track performance metrics and success rates',
          icon: Ionicons.analytics_outline,
          color: Color(0xFF8B5CF6),
          index: 4,
        ),
      ],
    );
  }
}
