import 'package:get_it/get_it.dart';

import '../../features/home/data/repositories/proxy_repository_impl.dart';
import '../../features/home/domain/repositories/proxy_repository.dart';
import '../../features/home/domain/usecases/fetch_proxies.dart';
import '../../features/home/domain/usecases/test_proxy.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/web_scraping/data/repositories/scraping_repository_impl.dart';
import '../../features/web_scraping/domain/repositories/scraping_repository.dart';
import '../../features/web_scraping/domain/usecases/initialize_scraper.dart';
import '../../features/web_scraping/domain/usecases/scrape_website.dart';
import '../../features/web_scraping/presentation/controllers/scraping_controller.dart';
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

  // Register home feature components
  serviceLocator.registerFactory<HomeProxyRepository>(
    () => HomeProxyRepositoryImpl(serviceLocator<ProxyService>()),
  );

  serviceLocator.registerFactory<FetchProxies>(
    () => FetchProxies(serviceLocator<HomeProxyRepository>()),
  );

  serviceLocator.registerFactory<TestProxy>(
    () => TestProxy(serviceLocator<HomeProxyRepository>()),
  );

  serviceLocator.registerFactory<HomeController>(
    () => HomeController(
      fetchProxiesUseCase: serviceLocator<FetchProxies>(),
      testProxyUseCase: serviceLocator<TestProxy>(),
    ),
  );

  // Register web scraping feature components
  serviceLocator.registerFactory<ScrapingRepository>(
    () => ScrapingRepositoryImpl(serviceLocator<ProxyService>()),
  );

  serviceLocator.registerFactory<InitializeScraper>(
    () => InitializeScraper(serviceLocator<ScrapingRepository>()),
  );

  serviceLocator.registerFactory<ScrapeWebsite>(
    () => ScrapeWebsite(serviceLocator<ScrapingRepository>()),
  );

  serviceLocator.registerFactory<ScrapingController>(
    () => ScrapingController(
      initializeScraperUseCase: serviceLocator<InitializeScraper>(),
      scrapeWebsiteUseCase: serviceLocator<ScrapeWebsite>(),
    ),
  );
}
