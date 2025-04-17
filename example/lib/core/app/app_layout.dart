import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../design/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/proxy_management/presentation/screens/proxy_management_screen.dart';
import '../../features/web_scraping/presentation/screens/web_scraping_screen.dart';
import '../../features/headless_browser/presentation/screens/headless_browser_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';

/// Global key for accessing AppLayout state
final GlobalKey<AppLayoutState> appLayoutKey = GlobalKey<AppLayoutState>();

/// Main app layout with bottom navigation and drawer
class AppLayout extends StatefulWidget {
  const AppLayout({super.key = const Key('app_layout')});

  @override
  State<AppLayout> createState() => AppLayoutState();
}

class AppLayoutState extends State<AppLayout>
    with SingleTickerProviderStateMixin {
  /// Navigate to a specific tab
  void navigateToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      _onItemTapped(index);
    }
  }

  int _currentIndex = 0;
  late final TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const HomeScreen(),
    const ProxyManagementScreen(),
    const WebScrapingScreen(),
    const HeadlessBrowserScreen(),
    const AnalyticsScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Ionicons.home_outline),
      activeIcon: Icon(Ionicons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Ionicons.server_outline),
      activeIcon: Icon(Ionicons.server),
      label: 'Proxies',
    ),
    BottomNavigationBarItem(
      icon: Icon(Ionicons.code_outline),
      activeIcon: Icon(Ionicons.code),
      label: 'Scraping',
    ),
    BottomNavigationBarItem(
      icon: Icon(Ionicons.globe_outline),
      activeIcon: Icon(Ionicons.globe),
      label: 'Headless',
    ),
    BottomNavigationBarItem(
      icon: Icon(Ionicons.analytics_outline),
      activeIcon: Icon(Ionicons.analytics),
      label: 'Analytics',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _screens.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          _onItemTapped(index);
          Navigator.pop(context);
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          items: _navItems,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          elevation: 8,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
