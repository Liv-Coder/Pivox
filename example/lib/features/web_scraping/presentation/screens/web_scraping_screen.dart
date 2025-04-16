import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/status_card.dart';
import '../controllers/scraping_controller.dart';
import '../widgets/error_dialog.dart';
import '../widgets/log_display.dart';

/// Screen for demonstrating web scraping capabilities
class WebScrapingScreen extends StatefulWidget {
  /// Creates a new [WebScrapingScreen]
  const WebScrapingScreen({super.key});

  @override
  State<WebScrapingScreen> createState() => _WebScrapingScreenState();
}

class _WebScrapingScreenState extends State<WebScrapingScreen> {
  late final ScrapingController _controller;

  // Form controllers
  final _urlController = TextEditingController();
  final _selectorController = TextEditingController();
  final _attributeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<ScrapingController>();
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _urlController.dispose();
    _selectorController.dispose();
    _attributeController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  Future<void> _scrapeWebsite() async {
    try {
      final url = _urlController.text.trim();
      final selector = _selectorController.text.trim();
      final attribute = _attributeController.text.trim();

      developer.log(
        'Scraping website: $url with selector: $selector and attribute: $attribute',
        name: 'WebScrapingScreen',
      );

      await _controller.scrapeWebsite(
        url: url,
        selector: selector,
        attribute: attribute,
      );

      developer.log(
        'Scraping completed, data count: ${_controller.scrapedData.length}',
        name: 'WebScrapingScreen',
      );
    } catch (e) {
      if (mounted) {
        showScrapingErrorDialog(
          context: context,
          title: 'Scraping Failed',
          errorMessage: e.toString(),
          logger: _controller.logger,
        );
      }
    }
  }

  Future<void> _scrapeStructuredData() async {
    try {
      await _controller.scrapeStructuredData(url: _urlController.text.trim());
    } catch (e) {
      if (mounted) {
        showScrapingErrorDialog(
          context: context,
          title: 'Structured Data Scraping Failed',
          errorMessage: e.toString(),
          logger: _controller.logger,
        );
      }
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
              StatusCard(message: _controller.statusMessage),
              const SizedBox(height: DesignTokens.spacingMedium),

              // Log display
              const Text(
                'Scraping Logs',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeLarge,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingSmall),
              LogDisplay(logger: _controller.logger, maxHeight: 150),
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
                              isLoading: _controller.isLoading,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingMedium),
                          Expanded(
                            child: ActionButton(
                              onPressed: _scrapeStructuredData,
                              icon: Ionicons.layers_outline,
                              text: 'Scrape Structured Data',
                              isLoading: _controller.isLoading,
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
              Builder(
                builder: (context) {
                  // Debug log for scraped data
                  if (_controller.scrapedData.isNotEmpty) {
                    developer.log(
                      'Displaying ${_controller.scrapedData.length} scraped items',
                      name: 'WebScrapingScreen',
                    );
                  } else {
                    developer.log(
                      'No scraped data to display',
                      name: 'WebScrapingScreen',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Display scraped data if available
              if (_controller.scrapedData.isNotEmpty) ...[
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
                    itemCount: _controller.scrapedData.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _controller.scrapedData[index];
                      developer.log(
                        'Rendering item $index: ${item.toString()}',
                        name: 'WebScrapingScreen',
                      );
                      // Handle potential errors with the data structure
                      String title = 'Item $index';
                      String content = 'No content';

                      try {
                        if (item.isNotEmpty) {
                          title = item.keys.first;
                          content = item.values.first;
                        }
                      } catch (e) {
                        developer.log(
                          'Error displaying item $index: $e',
                          name: 'WebScrapingScreen',
                        );
                      }

                      return ListTile(
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                        ),
                        subtitle: Text(
                          content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          // Show the full data in a dialog
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(title),
                                  content: SingleChildScrollView(
                                    child: Text(content),
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
