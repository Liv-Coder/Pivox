import 'package:flutter/material.dart';
import 'package:pivox/pivox.dart';

class HeadlessBrowserExample extends StatefulWidget {
  const HeadlessBrowserExample({super.key});

  @override
  State<HeadlessBrowserExample> createState() => _HeadlessBrowserExampleState();
}

class _HeadlessBrowserExampleState extends State<HeadlessBrowserExample> {
  final _urlController = TextEditingController();
  final _selectorController = TextEditingController();
  
  HeadlessBrowserService? _browserService;
  SpecializedHeadlessHandlers? _handlers;
  
  bool _isLoading = false;
  String _resultText = '';
  Map<String, dynamic>? _resultData;
  
  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://quotes.toscrape.com/js/';
    _selectorController.text = '.quote';
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
      _resultText = 'Initializing headless browser...';
    });
    
    try {
      // Create a proxy manager
      final proxyManager = await Pivox.createProxyManager();
      
      // Create a headless browser service with proxy support
      _browserService = await HeadlessBrowserFactory.createService(
        proxyManager: proxyManager,
        config: HeadlessBrowserConfig(
          blockImages: true,
          timeoutMillis: 60000,
          loggingEnabled: true,
        ),
      );
      
      // Create specialized handlers
      _handlers = await HeadlessBrowserFactory.createSpecializedHandlers(
        service: _browserService,
      );
      
      setState(() {
        _isLoading = false;
        _resultText = 'Headless browser initialized. Ready to scrape.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultText = 'Error initializing headless browser: $e';
      });
    }
  }
  
  Future<void> _scrapeWithHeadlessBrowser() async {
    if (_browserService == null) {
      setState(() {
        _resultText = 'Headless browser not initialized. Please try again.';
      });
      return;
    }
    
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _resultText = 'Please enter a URL to scrape.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _resultText = 'Scraping $url...';
      _resultData = null;
    });
    
    try {
      final result = await _browserService!.scrapeUrl(
        url,
        selectors: {
          'quotes': _selectorController.text.trim(),
        },
      );
      
      if (result.success) {
        setState(() {
          _isLoading = false;
          _resultText = 'Successfully scraped $url';
          _resultData = result.data;
        });
      } else {
        setState(() {
          _isLoading = false;
          _resultText = 'Error scraping $url: ${result.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultText = 'Exception while scraping: $e';
      });
    }
  }
  
  Future<void> _scrapeJavaScriptSite() async {
    if (_handlers == null) {
      setState(() {
        _resultText = 'Specialized handlers not initialized. Please try again.';
      });
      return;
    }
    
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _resultText = 'Please enter a URL to scrape.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _resultText = 'Scraping JavaScript site $url...';
      _resultData = null;
    });
    
    try {
      final result = await _handlers!.handleJavaScriptSite(
        url,
        selectors: {
          'quotes': _selectorController.text.trim(),
        },
      );
      
      if (result.success) {
        setState(() {
          _isLoading = false;
          _resultText = 'Successfully scraped JavaScript site $url';
          _resultData = result.data;
        });
      } else {
        setState(() {
          _isLoading = false;
          _resultText = 'Error scraping JavaScript site $url: ${result.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultText = 'Exception while scraping JavaScript site: $e';
      });
    }
  }
  
  Future<void> _scrapeLazyLoadingSite() async {
    if (_handlers == null) {
      setState(() {
        _resultText = 'Specialized handlers not initialized. Please try again.';
      });
      return;
    }
    
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _resultText = 'Please enter a URL to scrape.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _resultText = 'Scraping lazy loading site $url...';
      _resultData = null;
    });
    
    try {
      final result = await _handlers!.handleLazyLoadingSite(
        url,
        selectors: {
          'items': _selectorController.text.trim(),
        },
        scrollCount: 5,
        scrollDelay: 1000,
      );
      
      if (result.success) {
        setState(() {
          _isLoading = false;
          _resultText = 'Successfully scraped lazy loading site $url';
          _resultData = result.data;
        });
      } else {
        setState(() {
          _isLoading = false;
          _resultText = 'Error scraping lazy loading site $url: ${result.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultText = 'Exception while scraping lazy loading site: $e';
      });
    }
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    _selectorController.dispose();
    _browserService?.dispose();
    _handlers?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Headless Browser Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL to Scrape',
                hintText: 'Enter a URL to scrape',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _selectorController,
              decoration: const InputDecoration(
                labelText: 'CSS Selector',
                hintText: 'Enter a CSS selector (e.g., .quote)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _scrapeWithHeadlessBrowser,
                    child: const Text('Scrape with Headless Browser'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _scrapeJavaScriptSite,
                    child: const Text('Scrape JavaScript Site'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _scrapeLazyLoadingSite,
                    child: const Text('Scrape Lazy Loading Site'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _initializeServices,
                    child: const Text('Reinitialize Browser'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Results:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_resultText),
                            if (_resultData != null) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Extracted Data:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._buildResultDataWidgets(),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildResultDataWidgets() {
    final widgets = <Widget>[];
    
    _resultData?.forEach((key, value) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$key:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (value is List) ...[
                Text('Found ${value.length} items'),
                ...value.take(10).map((item) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                  child: Text('• $item'),
                )),
                if (value.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: Text('... and ${value.length - 10} more'),
                  ),
              ] else
                Text(value?.toString() ?? 'null'),
            ],
          ),
        ),
      );
    });
    
    return widgets;
  }
}
