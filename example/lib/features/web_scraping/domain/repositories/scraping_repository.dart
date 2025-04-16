import 'package:pivox/features/web_scraping/scraping_logger.dart';

import '../entities/scraping_config.dart';
import '../entities/scraping_result.dart';

/// Repository interface for web scraping operations
abstract class ScrapingRepository {
  /// Initializes the web scraper
  Future<void> initialize();

  /// Scrapes a website with the given configuration
  Future<ScrapingResult> scrapeWebsite(ScrapingConfig config);

  /// Gets the scraping logger
  ScrapingLogger get logger;

  /// Checks if the web scraper is initialized
  bool get isInitialized;
}
