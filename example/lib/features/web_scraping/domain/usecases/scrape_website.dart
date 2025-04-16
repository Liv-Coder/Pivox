import '../entities/scraping_config.dart';
import '../entities/scraping_result.dart';
import '../repositories/scraping_repository.dart';

/// Use case for scraping a website
class ScrapeWebsite {
  /// The repository for web scraping operations
  final ScrapingRepository repository;

  /// Creates a new [ScrapeWebsite] use case
  ScrapeWebsite(this.repository);

  /// Executes the use case
  Future<ScrapingResult> call(ScrapingConfig config) async {
    if (!repository.isInitialized) {
      await repository.initialize();
    }
    
    return repository.scrapeWebsite(config);
  }
}
