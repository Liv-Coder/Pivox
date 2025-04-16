import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:pivox/features/web_scraping/scraping_logger.dart';

import '../../domain/entities/scraping_config.dart';
import '../../domain/usecases/initialize_scraper.dart';
import '../../domain/usecases/scrape_website.dart';

/// Controller for the web scraping screen
class ScrapingController extends ChangeNotifier {
  /// Use case for initializing the web scraper
  final InitializeScraper _initializeScraperUseCase;

  /// Use case for scraping a website
  final ScrapeWebsite _scrapeWebsiteUseCase;

  /// Loading state
  bool _isLoading = false;

  /// Status message
  String _statusMessage = '';

  /// Scraped data
  List<Map<String, String>> _scrapedData = [];

  /// Creates a new [ScrapingController]
  ScrapingController({
    required InitializeScraper initializeScraperUseCase,
    required ScrapeWebsite scrapeWebsiteUseCase,
  }) : _initializeScraperUseCase = initializeScraperUseCase,
       _scrapeWebsiteUseCase = scrapeWebsiteUseCase;

  /// Gets the loading state
  bool get isLoading => _isLoading;

  /// Gets the status message
  String get statusMessage => _statusMessage;

  /// Gets the scraped data
  List<Map<String, String>> get scrapedData => _scrapedData;

  /// Gets the logger
  ScrapingLogger get logger => _scrapeWebsiteUseCase.repository.logger;

  /// Initializes the web scraper
  Future<void> initialize() async {
    _isLoading = true;
    _statusMessage = 'Initializing web scraper...';
    notifyListeners();

    try {
      await _initializeScraperUseCase();
      _statusMessage = 'Web scraper initialized successfully';
    } catch (e) {
      _statusMessage = 'Failed to initialize web scraper: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Scrapes a website
  Future<void> scrapeWebsite({
    required String url,
    required String selector,
    String attribute = '',
  }) async {
    if (url.isEmpty) {
      _statusMessage = 'Please enter a URL';
      notifyListeners();
      return;
    }

    if (selector.isEmpty) {
      _statusMessage = 'Please enter a CSS selector';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _statusMessage = 'Scraping website...';
    _scrapedData = [];
    notifyListeners();

    try {
      final config = ScrapingConfig(
        url: url,
        selector: selector,
        attribute: attribute.isNotEmpty ? attribute : null,
      );

      final result = await _scrapeWebsiteUseCase(config);
      developer.log(
        'Received result with ${result.data.length} items',
        name: 'ScrapingController',
      );

      if (result.data.isEmpty) {
        developer.log(
          'Warning: Received empty data from scraping',
          name: 'ScrapingController',
        );
        _scrapedData = [];
        _statusMessage = 'No data found with the provided selector';
      } else {
        // Log the first few items for debugging
        for (int i = 0; i < result.data.length && i < 3; i++) {
          final item = result.data[i];
          developer.log(
            'Item $i: ${item.toString()}',
            name: 'ScrapingController',
          );
        }

        _scrapedData = result.data;
        _statusMessage = 'Successfully scraped ${result.data.length} items';
      }
    } catch (e) {
      _statusMessage = 'Failed to scrape website: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Scrapes structured data from a website
  Future<void> scrapeStructuredData({required String url}) async {
    if (url.isEmpty) {
      _statusMessage = 'Please enter a URL';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _statusMessage = 'Scraping structured data...';
    _scrapedData = [];
    notifyListeners();

    try {
      final config = ScrapingConfig.forStructuredData(url: url);
      final result = await _scrapeWebsiteUseCase(config);

      developer.log(
        'Received structured data result with ${result.data.length} items',
        name: 'ScrapingController',
      );

      if (result.data.isEmpty) {
        developer.log(
          'Warning: Received empty structured data',
          name: 'ScrapingController',
        );
        _scrapedData = [];
        _statusMessage = 'No structured data found on the page';
      } else {
        // Log the first few items for debugging
        for (int i = 0; i < result.data.length && i < 3; i++) {
          final item = result.data[i];
          developer.log(
            'Structured data item $i: ${item.toString()}',
            name: 'ScrapingController',
          );
        }

        _scrapedData = result.data;
        _statusMessage =
            'Successfully scraped ${result.data.length} structured data items';
      }
    } catch (e) {
      _statusMessage = 'Failed to scrape structured data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
