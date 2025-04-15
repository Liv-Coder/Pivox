import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pivox/pivox.dart';

import '../../../../../core/design/design_tokens.dart';
import '../../../../../core/services/proxy_service.dart';
import '../../../../../core/services/service_locator.dart';
import '../../../../../core/widgets/action_button.dart';
import '../../../../../core/widgets/status_card.dart';
import '../widgets/log_display.dart';
import '../widgets/error_dialog.dart';

/// Screen for demonstrating web scraping capabilities
class WebScrapingScreen extends StatefulWidget {
  /// Creates a new [WebScrapingScreen]
  const WebScrapingScreen({super.key});

  @override
  State<WebScrapingScreen> createState() => _WebScrapingScreenState();
}

class _WebScrapingScreenState extends State<WebScrapingScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  List<Map<String, String>> _scrapedData = [];

  // Get services from service locator
  final _proxyService = serviceLocator<ProxyService>();

  // Web scraper
  WebScraper? _webScraper;

  // Scraping logger
  ScrapingLogger? _logger;

  // Form controllers
  final _urlController = TextEditingController();
  final _selectorController = TextEditingController();
  final _attributeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initWebScraper();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _selectorController.dispose();
    _attributeController.dispose();
    super.dispose();
  }

  Future<void> _initWebScraper() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing web scraper...';
    });

    try {
      // Create a logger
      _logger = ScrapingLogger();

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
      );

      _logger?.info('Web scraper initialized');

      // Ensure we have validated proxies available
      try {
        // Try to get a proxy to see if any are available
        _proxyService.proxyManager.getNextProxy(validated: true);
      } catch (e) {
        setState(() {
          _statusMessage = 'Fetching and validating proxies...';
        });

        // Fetch and validate proxies if none are available
        await _proxyService.proxyManager.fetchValidatedProxies(
          options: ProxyFilterOptions(count: 10, onlyHttps: true),
        );
      }

      setState(() {
        _statusMessage = 'Web scraper initialized successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize web scraper: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scrapeWebsite() async {
    var url = _urlController.text.trim();
    final selector = _selectorController.text.trim();
    final attribute = _attributeController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a URL';
      });
      return;
    }

    if (selector.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a CSS selector';
      });
      return;
    }

    _logger?.info('Starting to scrape website: $url');

    // Check if the site is known to be problematic
    final isProblematic =
        _webScraper?.reputationTracker.isProblematicSite(url) ?? false;

    // Check for specific problematic sites
    final isKnownProblematicSite =
        url.contains('onlinekhabar.com') || url.contains('vegamovies');

    if (isProblematic || isKnownProblematicSite) {
      _logger?.warning('Site is known to be problematic: $url');
      setState(() {
        _statusMessage =
            'Note: This site may have anti-scraping measures. Using specialized approach...';
      });
    }

    // Ensure URL has proper scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Scraping website...';
      _scrapedData = [];
    });

    _logger?.info('Starting scraping process with timeout=60000ms, retries=5');

    try {
      String html;

      // Use specialized handler for known problematic sites
      if (isKnownProblematicSite) {
        _logger?.info('Using specialized handler for problematic site');
        html = await _webScraper!.fetchFromProblematicSite(
          url: url,
          timeout: 60000, // Increase timeout to 60 seconds
          retries: 5, // Try up to 5 times
        );
      } else {
        // Use standard fetch with retry for normal sites
        html = await _webScraper!.fetchHtmlWithRetry(
          url: url,
          timeout: 60000, // Increase timeout to 60 seconds
          retries: 5, // Try up to 5 times
        );
      }

      // Extract data using the selector
      final data = _webScraper!.extractData(
        html: html,
        selector: selector,
        attribute: attribute.isNotEmpty ? attribute : null,
      );

      // Convert to structured data
      final structuredData = data.map((item) => {'value': item}).toList();

      // Record success in the reputation tracker
      _webScraper?.reputationTracker.recordSuccess(url);
      _logger?.success('Successfully scraped ${data.length} items from $url');

      setState(() {
        _scrapedData = structuredData;
        _statusMessage = 'Successfully scraped ${structuredData.length} items';
      });
    } catch (e) {
      // Record failure in the reputation tracker
      _webScraper?.reputationTracker.recordFailure(url, e.toString());
      _logger?.error('Scraping failed: ${e.toString()}');

      setState(() {
        _statusMessage = 'Failed to scrape website: $e';
      });

      // Show error dialog
      if (mounted) {
        showScrapingErrorDialog(
          context: context,
          title: 'Scraping Failed',
          errorMessage: e.toString(),
          logger: _logger!,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scrapeStructuredData() async {
    var url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a URL';
      });
      return;
    }

    _logger?.info('Starting to scrape structured data from: $url');

    // Check if the site is known to be problematic
    final isProblematic =
        _webScraper?.reputationTracker.isProblematicSite(url) ?? false;

    // Check for specific problematic sites
    final isKnownProblematicSite =
        url.contains('onlinekhabar.com') || url.contains('vegamovies');

    if (isProblematic || isKnownProblematicSite) {
      _logger?.warning('Site is known to be problematic: $url');
      setState(() {
        _statusMessage =
            'Note: This site may have anti-scraping measures. Using specialized approach...';
      });
    }

    // Ensure URL has proper scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Scraping structured data...';
      _scrapedData = [];
    });

    _logger?.info(
      'Starting structured data scraping process with timeout=60000ms, retries=5',
    );

    try {
      String html;

      // Use specialized handler for known problematic sites
      if (isKnownProblematicSite) {
        _logger?.info('Using specialized handler for problematic site');
        html = await _webScraper!.fetchFromProblematicSite(
          url: url,
          timeout: 60000, // Increase timeout to 60 seconds
          retries: 5, // Try up to 5 times
        );
      } else {
        // Use standard fetch with retry for normal sites
        html = await _webScraper!.fetchHtmlWithRetry(
          url: url,
          timeout: 60000, // Increase timeout to 60 seconds
          retries: 5, // Try up to 5 times
        );
      }

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
      final structuredData = _webScraper!.extractStructuredData(
        html: html,
        selectors: selectors,
        attributes: attributes,
      );

      // Record success in the reputation tracker
      _webScraper?.reputationTracker.recordSuccess(url);
      _logger?.success('Successfully scraped structured data from $url');
      _logger?.info('Extracted ${structuredData.length} structured data items');

      setState(() {
        _scrapedData = structuredData;
        _statusMessage = 'Successfully scraped structured data';
      });
    } catch (e) {
      // Record failure in the reputation tracker
      _webScraper?.reputationTracker.recordFailure(url, e.toString());
      _logger?.error('Structured data scraping failed: ${e.toString()}');

      setState(() {
        _statusMessage = 'Failed to scrape structured data: $e';
      });

      // Show error dialog
      if (mounted) {
        showScrapingErrorDialog(
          context: context,
          title: 'Structured Data Scraping Failed',
          errorMessage: e.toString(),
          logger: _logger!,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Web Scraping'), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status card
              StatusCard(message: _statusMessage),
              const SizedBox(height: DesignTokens.spacingMedium),

              // Log display
              if (_logger != null) ...[
                const Text(
                  'Scraping Logs',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeLarge,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSmall),
                LogDisplay(logger: _logger!, maxHeight: 150),
                const SizedBox(height: DesignTokens.spacingMedium),
              ],

              // Input form
              Card(
                elevation: DesignTokens.elevationSmall,
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Web Scraping Settings',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeLarge,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingMedium),

                      // URL input
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL',
                          hintText: 'https://example.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingMedium),

                      // CSS selector input
                      TextField(
                        controller: _selectorController,
                        decoration: const InputDecoration(
                          labelText: 'CSS Selector',
                          hintText: 'h1, .class-name, #id-name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingMedium),

                      // Attribute input
                      TextField(
                        controller: _attributeController,
                        decoration: const InputDecoration(
                          labelText: 'Attribute (optional)',
                          hintText: 'href, src, alt',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingMedium),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              onPressed: _scrapeWebsite,
                              icon: Ionicons.code_outline,
                              text: 'Scrape Website',
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingMedium),
                          Expanded(
                            child: ActionButton(
                              onPressed: _scrapeStructuredData,
                              icon: Ionicons.layers_outline,
                              text: 'Scrape Structured Data',
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingMedium),

              // Results
              if (_scrapedData.isNotEmpty) ...[
                const Text(
                  'Scraped Data',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeLarge,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingMedium),
                Card(
                  elevation: DesignTokens.elevationSmall,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _scrapedData.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _scrapedData[index];
                      return ListTile(
                        title: Text(
                          item.keys.first,
                          style: const TextStyle(
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                        ),
                        subtitle: Text(
                          item.values.first,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          // Show the full data in a dialog
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(item.keys.first),
                                  content: SingleChildScrollView(
                                    child: Text(item.values.first),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
