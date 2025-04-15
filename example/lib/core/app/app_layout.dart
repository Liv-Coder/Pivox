import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../features/advanced_filtering/presentation/screens/advanced_filtering_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/rotation_strategies/presentation/screens/rotation_strategies_screen.dart';
import '../../features/web_scraping/presentation/screens/web_scraping_screen.dart';
import '../design/design_tokens.dart';
import '../services/theme_manager.dart';
import '../widgets/app_drawer.dart';

/// Main app layout with bottom navigation
class AppLayout extends StatefulWidget {
  /// Creates a new [AppLayout]
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(title: 'Pivox Dashboard'),
    const RotationStrategiesScreen(),
    const WebScrapingScreen(),
    const AnalyticsScreen(),
  ];
  
  final List<String> _titles = [
    'Dashboard',
    'Rotation Strategies',
    'Web Scraping',
    'Analytics',
  ];
  
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: DesignTokens.durationMedium,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DesignTokens.curveStandard,
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    
    setState(() {
      _animationController.reset();
      _currentIndex = index;
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
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
        ],
      ),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: isDark 
              ? DesignTokens.darkShadowElevation1
              : DesignTokens.shadowElevation1,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Ionicons.home_outline),
              activeIcon: Icon(Ionicons.home),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Ionicons.swap_horizontal_outline),
              activeIcon: Icon(Ionicons.swap_horizontal),
              label: 'Rotation',
            ),
            BottomNavigationBarItem(
              icon: Icon(Ionicons.code_download_outline),
              activeIcon: Icon(Ionicons.code_download),
              label: 'Scraping',
            ),
            BottomNavigationBarItem(
              icon: Icon(Ionicons.analytics_outline),
              activeIcon: Icon(Ionicons.analytics),
              label: 'Analytics',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdvancedFilteringScreen(),
            ),
          );
        },
        tooltip: 'Advanced Filtering',
        child: const Icon(Ionicons.options_outline),
      ) : null,
    );
  }
}
