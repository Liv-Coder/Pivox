import 'package:get_it/get_it.dart';
import 'package:pivox/pivox.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// Initialize the service locator
  static Future<void> init() async {
    // External dependencies
    final sharedPreferences = await SharedPreferences.getInstance();
    _getIt.registerSingleton<SharedPreferences>(sharedPreferences);

    // Pivox core services
    final proxyManager = await Pivox.createProxyManager();
    _getIt.registerSingleton<ProxyManager>(proxyManager);

    final webScraper = await Pivox.createWebScraper();
    _getIt.registerSingleton<WebScraper>(webScraper);

    final headlessBrowserService = await Pivox.createHeadlessBrowserService();
    _getIt.registerSingleton<HeadlessBrowserService>(headlessBrowserService);

    // Feature-specific services will be registered in their respective modules
  }

  /// Get a registered instance
  static T get<T extends Object>() => _getIt.get<T>();

  /// Register a singleton instance
  static void registerSingleton<T extends Object>(T instance) {
    _getIt.registerSingleton<T>(instance);
  }

  /// Register a lazy singleton factory
  static void registerLazySingleton<T extends Object>(
    T Function() factoryFunc,
  ) {
    _getIt.registerLazySingleton<T>(factoryFunc);
  }

  /// Register a factory
  static void registerFactory<T extends Object>(T Function() factoryFunc) {
    _getIt.registerFactory<T>(factoryFunc);
  }
}
