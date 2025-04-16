import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../services/theme_manager.dart';
import 'app_drawer.dart';

/// A base screen widget that provides consistent AppBar with back button support
class BaseScreen extends StatelessWidget {
  /// The title of the screen
  final String title;

  /// The body of the screen
  final Widget body;

  /// Whether to show a back button
  final bool showBackButton;

  /// Additional actions to show in the AppBar
  final List<Widget>? actions;

  /// Floating action button
  final Widget? floatingActionButton;

  /// Bottom navigation bar
  final Widget? bottomNavigationBar;

  /// Whether this is a root screen (part of bottom navigation)
  final bool isRootScreen;

  /// Whether to show the theme toggle button
  final bool showThemeToggle;

  /// Creates a new [BaseScreen]
  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.isRootScreen = false,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager.of(context);

    // Combine default actions with provided actions
    final appBarActions = <Widget>[
      if (actions != null) ...actions!,
      if (showThemeToggle)
        IconButton(
          icon: Icon(
            themeManager.themeMode == ThemeMode.light
                ? Ionicons.sunny_outline
                : themeManager.themeMode == ThemeMode.dark
                ? Ionicons.moon_outline
                : Ionicons.contrast_outline,
          ),
          onPressed: () {
            themeManager.toggleTheme();
          },
          tooltip: 'Toggle theme',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        scrolledUnderElevation: 2,
        // Show back button only if not a root screen and showBackButton is true
        automaticallyImplyLeading: isRootScreen ? true : showBackButton,
        // If it's a root screen, we want the drawer icon
        // If not a root screen and showBackButton is true, show back button
        // Otherwise, don't show any leading icon
        leading:
            isRootScreen
                ? null // Use default drawer icon for root screens
                : showBackButton
                ? IconButton(
                  icon: const Icon(Ionicons.arrow_back_outline),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : const SizedBox.shrink(),
        actions: appBarActions,
      ),
      // Only show drawer for root screens
      drawer: isRootScreen ? const AppDrawer() : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
