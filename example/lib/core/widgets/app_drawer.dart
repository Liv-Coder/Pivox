import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../utils/theme_manager.dart';

/// App drawer widget
class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Ionicons.home_outline,
                  selectedIcon: Ionicons.home,
                  title: 'Home',
                  index: 0,
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.server_outline,
                  selectedIcon: Ionicons.server,
                  title: 'Proxy Management',
                  index: 1,
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.code_outline,
                  selectedIcon: Ionicons.code,
                  title: 'Web Scraping',
                  index: 2,
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.globe_outline,
                  selectedIcon: Ionicons.globe,
                  title: 'Headless Browser',
                  index: 3,
                ),
                _buildDrawerItem(
                  context,
                  icon: Ionicons.analytics_outline,
                  selectedIcon: Ionicons.analytics,
                  title: 'Analytics',
                  index: 4,
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    isDarkMode ? Ionicons.sunny_outline : Ionicons.moon_outline,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    isDarkMode ? 'Light Mode' : 'Dark Mode',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () {
                    themeManager.toggleTheme();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Ionicons.information_circle_outline,
                    color: AppColors.info,
                  ),
                  title: Text(
                    'About',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          _buildVersionInfo(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withAlpha(204)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: const Icon(
                  Ionicons.globe,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Pivox',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Proxy Rotation & Web Scraping',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white.withAlpha(230)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Example App',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return AnimatedContainer(
      duration: AppSpacing.shortAnimation,
      color:
          isSelected
              ? Theme.of(context).colorScheme.primary.withAlpha(25)
              : Colors.transparent,
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withAlpha(179),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => onItemSelected(index),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        'Version 1.2.0',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About Pivox'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pivox is a comprehensive proxy rotation and web scraping package for Flutter.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Features:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildFeatureItem(context, 'Dynamic proxy sourcing'),
                _buildFeatureItem(context, 'Smart proxy rotation'),
                _buildFeatureItem(context, 'Health validation'),
                _buildFeatureItem(context, 'Advanced web scraping'),
                _buildFeatureItem(context, 'Headless browser integration'),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Version: 1.2.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Ionicons.checkmark_circle,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
