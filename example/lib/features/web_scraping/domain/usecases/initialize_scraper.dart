import '../repositories/scraping_repository.dart';

/// Use case for initializing the web scraper
class InitializeScraper {
  /// The repository for web scraping operations
  final ScrapingRepository repository;

  /// Creates a new [InitializeScraper] use case
  InitializeScraper(this.repository);

  /// Executes the use case
  Future<void> call() async {
    if (!repository.isInitialized) {
      await repository.initialize();
    }
  }
}
