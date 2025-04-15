import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../features/advanced_filtering/presentation/screens/advanced_filtering_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/headless_browser/headless_browser_example.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/rotation_strategies/presentation/screens/rotation_strategies_screen.dart';
import '../../features/web_scraping/presentation/screens/web_scraping_screen.dart';
import '../design/design_tokens.dart';
import '../services/theme_manager.dart';

/// App drawer for navigation
class AppDrawer extends StatelessWidget {
  /// Creates a new [AppDrawer]
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager.of(context);

    return Drawer(
      elevation: 0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacingMedium,
              DesignTokens.spacingLarge,
              DesignTokens.spacingMedium,
              DesignTokens.spacingMedium,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.borderRadiusCircular,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Ionicons.globe_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMedium),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pivox',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                          ),
                          Text(
                            'Free Proxy Rotator',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withAlpha(204), // 0.8 opacity
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  Row(
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: DesignTokens.spacingSmall),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            icon: Icon(Ionicons.sunny_outline, size: 16),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            icon: Icon(Ionicons.contrast_outline, size: 16),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            icon: Icon(Ionicons.moon_outline, size: 16),
                          ),
                        ],
                        selected: {themeManager.themeMode},
                        onSelectionChanged: (Set<ThemeMode> selection) {
                          themeManager.setThemeMode(selection.first);
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: WidgetStateProperty.resolveWith<
                            Color
                          >((Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.white.withAlpha(51); // 0.2 opacity
                          }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return Theme.of(context).colorScheme.primary;
                                }
                                return Colors.white;
                              }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  'Dashboard',
                  Ionicons.home_outline,
                  () => _navigateTo(
                    context,
                    const HomeScreen(title: 'Pivox Dashboard'),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  'Rotation Strategies',
                  Ionicons.swap_horizontal_outline,
                  () => _navigateTo(context, const RotationStrategiesScreen()),
                ),
                _buildDrawerItem(
                  context,
                  'Web Scraping',
                  Ionicons.code_download_outline,
                  () => _navigateTo(context, const WebScrapingScreen()),
                ),
                _buildDrawerItem(
                  context,
                  'Analytics',
                  Ionicons.analytics_outline,
                  () => _navigateTo(context, const AnalyticsScreen()),
                ),
                _buildDrawerItem(
                  context,
                  'Advanced Filtering',
                  Ionicons.options_outline,
                  () => _navigateTo(context, const AdvancedFilteringScreen()),
                ),
                _buildDrawerItem(
                  context,
                  'Headless Browser',
                  Ionicons.browsers_outline,
                  () => _navigateTo(context, const HeadlessBrowserExample()),
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  'Documentation',
                  Ionicons.document_text_outline,
                  () {
                    // Open documentation
                  },
                ),
                _buildDrawerItem(
                  context,
                  'Settings',
                  Ionicons.settings_outline,
                  () {
                    // Open settings
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingMedium),
            child: Text(
              'Pivox v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}
