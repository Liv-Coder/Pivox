import 'package:flutter/material.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/proxy_management/presentation/screens/proxy_management_screen.dart';
import '../../features/web_scraping/presentation/screens/web_scraping_screen.dart';
import '../../features/headless_browser/presentation/screens/headless_browser_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';

/// App routes
class AppRoutes {
  static const String home = '/';
  static const String proxyManagement = '/proxy-management';
  static const String webScraping = '/web-scraping';
  static const String headlessBrowser = '/headless-browser';
  static const String analytics = '/analytics';

  /// Get app routes
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      proxyManagement: (context) => const ProxyManagementScreen(),
      webScraping: (context) => const WebScrapingScreen(),
      headlessBrowser: (context) => const HeadlessBrowserScreen(),
      analytics: (context) => const AnalyticsScreen(),
    };
  }
}
