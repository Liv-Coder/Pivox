import 'package:get_it/get_it.dart';

import 'proxy_service.dart';
import 'theme_manager.dart';

/// Global service locator instance
final GetIt serviceLocator = GetIt.instance;

/// Initializes the service locator
Future<void> setupServiceLocator() async {
  // Register services
  serviceLocator.registerSingleton<ThemeManager>(ThemeManager());
  serviceLocator.registerSingleton<ProxyService>(ProxyService());
  
  // Initialize services
  await serviceLocator<ThemeManager>().initialize();
  await serviceLocator<ProxyService>().initialize();
}
