import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pivox/pivox.dart';

import '../../../../../core/design/design_tokens.dart';
import '../../../../../core/services/proxy_service.dart';
import '../../../../../core/services/service_locator.dart';
import '../../../../../core/widgets/action_button.dart';
import '../../../../../core/widgets/status_card.dart';

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
      // Initialize the web scraper
      _webScraper = WebScraper(proxyManager: _proxyService.proxyManager);

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
    final url = _urlController.text.trim();
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

    setState(() {
      _isLoading = true;
      _statusMessage = 'Scraping website...';
      _scrapedData = [];
    });

    try {
      // Fetch the HTML content
      final html = await _webScraper!.fetchHtml(url: url);

      // Extract data using the selector
      final data = _webScraper!.extractData(
        html: html,
        selector: selector,
        attribute: attribute.isNotEmpty ? attribute : null,
      );

      // Convert to structured data
      final structuredData = data.map((item) => {'value': item}).toList();

      setState(() {
        _scrapedData = structuredData;
        _statusMessage = 'Successfully scraped ${structuredData.length} items';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to scrape website: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scrapeStructuredData() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Scraping structured data...';
      _scrapedData = [];
    });

    try {
      // Fetch the HTML content
      final html = await _webScraper!.fetchHtml(url: url);

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

      setState(() {
        _scrapedData = structuredData;
        _statusMessage = 'Successfully scraped structured data';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to scrape structured data: $e';
      });
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
