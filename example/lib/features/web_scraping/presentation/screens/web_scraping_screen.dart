import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/widgets/base_screen.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/utils/app_animations.dart';
import '../widgets/scraping_form.dart';
import '../widgets/result_display.dart';
import '../widgets/log_display.dart';
import '../../domain/entities/scraping_config.dart';
import '../../domain/entities/scraping_result.dart';

/// Web scraping screen
class WebScrapingScreen extends StatefulWidget {
  const WebScrapingScreen({super.key});

  @override
  State<WebScrapingScreen> createState() => _WebScrapingScreenState();
}

class _WebScrapingScreenState extends State<WebScrapingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _hasResult = false;

  // Mock result for demonstration
  ScrapingResult? _result;
  final List<LogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _addInitialLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addInitialLogs() {
    _logs.add(LogEntry.info('Web scraper initialized'));
    _logs.add(LogEntry.info('Ready to scrape'));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Web Scraping',
      actions: [
        IconButton(
          icon: const Icon(Ionicons.save_outline),
          onPressed: _hasResult ? _saveResults : null,
          tooltip: 'Save Results',
        ),
        IconButton(
          icon: const Icon(Ionicons.settings_outline),
          onPressed: _showSettings,
          tooltip: 'Settings',
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Scraper'), Tab(text: 'Results')],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withAlpha(179),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildScraperTab(), _buildResultsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScraperTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAnimations.fadeSlideIn(
            child: ScrapingForm(
              onSubmit: _startScraping,
              isLoading: _isLoading,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppAnimations.fadeSlideIn(
            child: LogDisplay(logs: _logs, onClear: _clearLogs),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (!_hasResult) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Ionicons.document_text_outline,
              size: 64,
              color: Color(0xFF3B82F6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Results Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start scraping to see results here',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ActionButton(
              text: 'Go to Scraper',
              icon: Ionicons.code_outline,
              onPressed: () {
                _tabController.animateTo(0);
              },
            ),
          ],
        ),
      );
    }

    return ResultDisplay(
      result: _result!,
      onExport: _exportResults,
      onClear: _clearResults,
    );
  }

  void _startScraping(ScrapingConfig config) {
    setState(() {
      _isLoading = true;
      _logs.add(LogEntry.info('Starting scraping of ${config.url}'));
      _logs.add(LogEntry.info('Using proxy: ${config.useProxy}'));
      _logs.add(
        LogEntry.info('Using headless browser: ${config.useHeadlessBrowser}'),
      );
    });

    // Simulate scraping process
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _logs.add(LogEntry.info('Connecting to ${config.url}...'));
        });
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _logs.add(LogEntry.success('Connected successfully'));
          _logs.add(LogEntry.info('Fetching HTML content...'));
        });
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _logs.add(LogEntry.success('HTML content fetched (24.5 KB)'));
          _logs.add(LogEntry.info('Applying selectors...'));
        });
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _logs.add(LogEntry.success('Extracted data from selectors'));
          _logs.add(LogEntry.info('Processing results...'));
        });
      }
    });

    // Simulate completion after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // Create mock result
        final mockResult = _createMockResult(config);

        setState(() {
          _isLoading = false;
          _hasResult = true;
          _result = mockResult;
          _logs.add(LogEntry.success('Scraping completed successfully'));
          _logs.add(LogEntry.info('Found ${mockResult.itemsScraped} items'));
        });

        // Switch to results tab
        _tabController.animateTo(1);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scraping completed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  ScrapingResult _createMockResult(ScrapingConfig config) {
    // Create mock data based on the selectors
    final mockData = <Map<String, dynamic>>[];

    // Generate 5-10 mock items
    final itemCount = 5 + (DateTime.now().millisecond % 6);

    for (var i = 0; i < itemCount; i++) {
      final item = <String, dynamic>{};

      // Add a field for each selector
      for (final entry in config.selectors.entries) {
        item[entry.key] = 'Sample ${entry.key} ${i + 1}';
      }

      // Add some additional fields
      item['url'] = '${config.url}/item-${i + 1}';
      item['timestamp'] = DateTime.now().toIso8601String();

      mockData.add(item);
    }

    return ScrapingResult.success(
      data: mockData,
      statusCode: 200,
      pagesScraped: config.followPagination ? 3 : 1,
      duration: const Duration(seconds: 5, milliseconds: 234),
      proxyUsed: config.useProxy ? '192.168.1.1:8080' : null,
      usedHeadlessBrowser: config.useHeadlessBrowser,
      logs: _logs.map((log) => log.message).toList(),
    );
  }

  void _saveResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Results saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Results exported'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearResults() {
    setState(() {
      _hasResult = false;
      _result = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Results cleared'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _logs.add(LogEntry.info('Logs cleared'));
    });
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Scraper Settings'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('These settings will be implemented soon.')],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
