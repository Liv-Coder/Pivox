import 'package:pivox/pivox.dart';

import '../../../../core/services/proxy_service.dart';
import '../../domain/entities/scraping_config.dart';
import '../../domain/entities/scraping_result.dart';
import '../../domain/repositories/scraping_repository.dart';

/// Implementation of [ScrapingRepository]
class ScrapingRepositoryImpl implements ScrapingRepository {
  /// The proxy service
  final ProxyService _proxyService;

  /// The web scraper
  WebScraper? _webScraper;

  /// The scraping logger
  final ScrapingLogger _logger = ScrapingLogger();

  /// Creates a new [ScrapingRepositoryImpl]
  ScrapingRepositoryImpl(this._proxyService);

  @override
  ScrapingLogger get logger => _logger;

  @override
  bool get isInitialized => _webScraper != null;

  @override
  Future<void> initialize() async {
    if (_webScraper != null) {
      return;
    }

    _logger.info('Initializing web scraper...');

    try {
      // Initialize the web scraper with enhanced configuration
      _webScraper = WebScraper(
        proxyManager: _proxyService.proxyManager,
        defaultTimeout: 60000, // 60 seconds timeout
        maxRetries: 5, // 5 retry attempts
        logger: _logger, // Use our logger
        defaultHeaders: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
        // Use a custom HTTP client with better error handling
        httpClient: ProxyHttpClient(
          proxyManager: _proxyService.proxyManager,
          useValidatedProxies: true,
          rotateProxies: true,
          enableLogging: true,
        ),
      );

      _logger.info('Web scraper initialized');

      // Ensure we have validated proxies available
      try {
        // Try to get a proxy to see if any are available
        _proxyService.proxyManager.getNextProxy(validated: true);
      } catch (e) {
        _logger.warning('No validated proxies available, fetching new ones...');

        try {
          // Fetch and validate proxies if none are available
          await _proxyService.proxyManager.fetchValidatedProxies(
            options: ProxyFilterOptions(count: 10, onlyHttps: true),
          );
        } catch (validationError) {
          _logger.error('Failed to validate proxies: $validationError');

          // Try to fetch regular proxies as a fallback
          _logger.warning('Falling back to unvalidated proxies');
          await _proxyService.proxyManager.fetchProxies(
            options: ProxyFilterOptions(count: 20, onlyHttps: true),
          );
        }
      }

      _logger.success('Web scraper initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize web scraper: $e');
      throw Exception('Failed to initialize web scraper: $e');
    }
  }

  @override
  Future<ScrapingResult> scrapeWebsite(ScrapingConfig config) async {
    if (_webScraper == null) {
      throw Exception('Web scraper not initialized');
    }

    var url = config.url;

    // Ensure URL has proper scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    _logger.info('Starting to scrape website: $url');

    // Check if the site is known to be problematic
    final isProblematic = _webScraper!.reputationTracker.isProblematicSite(url);

    // Check for specific problematic sites
    final isKnownProblematicSite =
        url.contains('onlinekhabar.com') || url.contains('vegamovies');

    if (isProblematic || isKnownProblematicSite) {
      _logger.warning('Site is known to be problematic: $url');
    }

    try {
      String html;

      // Use specialized handler for known problematic sites
      if (isKnownProblematicSite) {
        _logger.info('Using specialized handler for problematic site');
        html = await _webScraper!.fetchFromProblematicSite(
          url: url,
          timeout: config.timeout,
          retries: config.retries,
        );
      } else {
        // Use standard fetch with retry for normal sites
        html = await _webScraper!.fetchHtmlWithRetry(
          url: url,
          timeout: config.timeout,
          retries: config.retries,
        );
      }

      List<Map<String, String>> structuredData;

      if (config.useStructuredData) {
        // Define selectors for common elements
        final selectors = {
          'title': 'title',
          'heading': 'h1',
          'subheading': 'h2',
          'paragraph': 'p',
          'link': 'a',
          'image': 'img',
        };

        // Define attributes for certain elements
        final attributes = {'link': 'href', 'image': 'src'};

        // Extract structured data
        try {
          final data = _webScraper!.extractStructuredData(
            html: html,
            selectors: selectors,
            attributes: attributes,
          );

          _logger.info('Raw structured data: ${data.toString()}');

          // Log the first few items for debugging
          for (int i = 0; i < data.length && i < 3; i++) {
            _logger.info('Raw structured data item $i: ${data[i].toString()}');
          }

          structuredData = data;
          _logger.success('Successfully scraped structured data from $url');
          _logger.info('Extracted ${data.length} structured data items');
        } catch (e) {
          _logger.error('Error extracting structured data: $e');
          // Create a fallback structured data item
          structuredData = [
            {'Error': 'Failed to extract structured data: $e'},
          ];
        }
      } else {
        if (config.selector == null) {
          throw Exception(
            'Selector is required for non-structured data scraping',
          );
        }

        // Log the HTML content for debugging
        _logger.info('HTML content length: ${html.length}');
        _logger.info('Using selector: ${config.selector!}');
        if (config.attribute != null) {
          _logger.info('Using attribute: ${config.attribute}');
        }

        // Extract data using the selector
        final data = _webScraper!.extractData(
          html: html,
          selector: config.selector!,
          attribute: config.attribute,
        );

        // Log the extracted data
        _logger.info('Extracted ${data.length} items');
        for (int i = 0; i < data.length && i < 5; i++) {
          _logger.info(
            'Item $i: ${data[i].substring(0, data[i].length > 100 ? 100 : data[i].length)}...',
          );
        }

        // Convert to structured data
        try {
          structuredData = data.map((item) => {'value': item}).toList();
          _logger.success(
            'Successfully scraped ${data.length} items from $url',
          );

          // Log the first few items for debugging
          for (int i = 0; i < structuredData.length && i < 3; i++) {
            _logger.info(
              'Structured data item $i: ${structuredData[i].toString()}',
            );
          }
        } catch (e) {
          _logger.error('Error converting data to structured format: $e');
          // Fallback to a simpler format
          structuredData = [];
          for (int i = 0; i < data.length; i++) {
            structuredData.add({'Item $i': data[i]});
          }
        }
      }

      // Record success in the reputation tracker
      _webScraper!.reputationTracker.recordSuccess(url);

      return ScrapingResult(
        url: url,
        data: structuredData,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Record failure in the reputation tracker
      _webScraper!.reputationTracker.recordFailure(url, e.toString());
      _logger.error('Scraping failed: ${e.toString()}');
      throw Exception('Failed to scrape website: $e');
    }
  }
}
