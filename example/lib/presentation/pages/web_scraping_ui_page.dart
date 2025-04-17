import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:pivox/features/web_scraping/parallel/scraping_task.dart';
import 'package:pivox/features/web_scraping/parallel/task_scheduler.dart';
import 'package:pivox/features/web_scraping/web_scraper.dart';

import '../widgets/element_inspector.dart';
import '../widgets/notification_system.dart';
import '../widgets/scraping_dashboard.dart';
import '../widgets/selector_builder.dart';
import '../widgets/selector_testing_playground.dart';
import '../widgets/status_indicator.dart';
import '../widgets/task_details_dialog.dart';

/// A page for the web scraping UI
class WebScrapingUIPage extends StatefulWidget {
  /// The web scraper to use
  final WebScraper webScraper;

  /// The task scheduler to use
  final TaskScheduler? scheduler;

  /// Creates a new [WebScrapingUIPage]
  const WebScrapingUIPage({
    super.key,
    required this.webScraper,
    this.scheduler,
  });

  @override
  State<WebScrapingUIPage> createState() => _WebScrapingUIPageState();
}

class _WebScrapingUIPageState extends State<WebScrapingUIPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _selectorController = TextEditingController();
  String _html = '';
  List<String> _extractedData = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedSelector = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize the notification system
    NotificationManager.instance.showInfo(
      title: 'Welcome',
      message:
          'Welcome to the Web Scraping UI. Use the tabs to navigate between different features.',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _selectorController.dispose();
    super.dispose();
  }

  Future<void> _fetchHtml() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      NotificationManager.instance.showWarning(
        title: 'Empty URL',
        message: 'Please enter a URL to fetch.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _html = '';
      _extractedData = [];
    });

    try {
      final html = await widget.webScraper.fetchHtml(url: url);

      setState(() {
        _isLoading = false;
        _html = html;
      });

      NotificationManager.instance.showSuccess(
        title: 'HTML Fetched',
        message: 'Successfully fetched HTML from $url',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      NotificationManager.instance.showError(
        title: 'Error',
        message: 'Failed to fetch HTML: ${e.toString()}',
      );
    }
  }

  Future<void> _extractData() async {
    final selector = _selectorController.text.trim();
    if (selector.isEmpty) {
      NotificationManager.instance.showWarning(
        title: 'Empty Selector',
        message: 'Please enter a CSS selector to extract data.',
      );
      return;
    }

    if (_html.isEmpty) {
      NotificationManager.instance.showWarning(
        title: 'No HTML',
        message: 'Please fetch HTML first.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _extractedData = [];
    });

    try {
      final data = widget.webScraper.extractData(
        html: _html,
        selector: selector,
      );

      setState(() {
        _isLoading = false;
        _extractedData = data;
      });

      NotificationManager.instance.showSuccess(
        title: 'Data Extracted',
        message: 'Successfully extracted ${data.length} items.',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      NotificationManager.instance.showError(
        title: 'Error',
        message: 'Failed to extract data: ${e.toString()}',
      );
    }
  }

  void _onSelectorChanged(String selector) {
    setState(() {
      _selectedSelector = selector;
      _selectorController.text = selector;
    });
  }

  void _onElementSelected(String selector, dom.Element element) {
    setState(() {
      _selectedSelector = selector;
      _selectorController.text = selector;
    });

    NotificationManager.instance.showInfo(
      title: 'Element Selected',
      message:
          'Selected <${element.localName}> element with selector: $selector',
    );
  }

  void _onCancelTask(String taskId) {
    if (widget.scheduler == null) return;

    try {
      widget.scheduler!.cancel(taskId);

      NotificationManager.instance.showSuccess(
        title: 'Task Cancelled',
        message: 'Successfully cancelled task $taskId',
      );
    } catch (e) {
      NotificationManager.instance.showError(
        title: 'Error',
        message: 'Failed to cancel task: ${e.toString()}',
      );
    }
  }

  void _onRetryTask(String taskId) {
    // This is a placeholder - in a real app, you would implement task retry logic
    NotificationManager.instance.showInfo(
      title: 'Task Retry',
      message: 'Retrying task $taskId',
    );
  }

  void _onViewTaskDetails(ScrapingTask task) {
    TaskDetailsDialog.show(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Web Scraping UI'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Selector Builder'),
              Tab(text: 'Element Inspector'),
              Tab(text: 'Testing Playground'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Dashboard tab
            _buildDashboardTab(),

            // Selector Builder tab
            _buildSelectorBuilderTab(),

            // Element Inspector tab
            _buildElementInspectorTab(),

            // Testing Playground tab
            _buildTestingPlaygroundTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL input and fetch button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'Enter a URL to fetch',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Fetch'),
                onPressed: _isLoading ? null : _fetchHtml,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selector input and extract button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _selectorController,
                  decoration: const InputDecoration(
                    labelText: 'CSS Selector',
                    hintText: 'Enter a CSS selector',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Extract'),
                onPressed: _isLoading || _html.isEmpty ? null : _extractData,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status indicators
          Row(
            children: [
              StatusBadge(
                type:
                    _isLoading
                        ? StatusIndicatorType.loading
                        : _errorMessage != null
                        ? StatusIndicatorType.error
                        : _html.isEmpty
                        ? StatusIndicatorType.neutral
                        : StatusIndicatorType.success,
                label:
                    _isLoading
                        ? 'Loading...'
                        : _errorMessage != null
                        ? 'Error'
                        : _html.isEmpty
                        ? 'No HTML'
                        : 'HTML Loaded',
                animate: _isLoading,
              ),
              const SizedBox(width: 8),
              if (_html.isNotEmpty && !_isLoading)
                StatusBadge(
                  type:
                      _extractedData.isEmpty
                          ? StatusIndicatorType.neutral
                          : StatusIndicatorType.success,
                  label:
                      _extractedData.isEmpty
                          ? 'No Data Extracted'
                          : '${_extractedData.length} Items Extracted',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Scraping dashboard
          if (widget.scheduler != null)
            SizedBox(
              height: 400,
              child: ScrapingDashboard(
                scheduler: widget.scheduler!,
                onCancelTask: _onCancelTask,
                onRetryTask: _onRetryTask,
                onViewTaskDetails: _onViewTaskDetails,
              ),
            ),

          // Extracted data
          if (_extractedData.isNotEmpty) ...[
            Text(
              'Extracted Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _extractedData.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      _extractedData[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectorBuilderTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectorBuilder(
        initialSelector: _selectedSelector,
        onSelectorChanged: _onSelectorChanged,
        onTest: (selector) {
          setState(() {
            _selectorController.text = selector;
          });

          if (_html.isNotEmpty) {
            _extractData();
          } else {
            NotificationManager.instance.showWarning(
              title: 'No HTML',
              message: 'Please fetch HTML first to test the selector.',
            );
          }
        },
      ),
    );
  }

  Widget _buildElementInspectorTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL input and fetch button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'Enter a URL to fetch',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Fetch'),
                onPressed: _isLoading ? null : _fetchHtml,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Element inspector
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _html.isEmpty
                    ? const Center(child: Text('No HTML content'))
                    : ElementInspector(
                      html: _html,
                      onElementSelected: _onElementSelected,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingPlaygroundTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectorTestingPlayground(
        initialHtml: _html,
        initialSelector: _selectedSelector,
        onSelectorChanged: (selector, results) {
          setState(() {
            _selectedSelector = selector;
            _selectorController.text = selector;
            _extractedData = results;
          });
        },
      ),
    );
  }
}
