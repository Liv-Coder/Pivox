import 'package:flutter/material.dart';
import 'package:pivox/core/utils/logger.dart';
import 'package:pivox/features/proxy_management/domain/usecases/get_proxies.dart';
import 'package:pivox/features/proxy_management/domain/usecases/get_validated_proxies.dart';
import 'package:pivox/features/proxy_management/domain/usecases/validate_proxy.dart';
import 'package:pivox/features/proxy_management/presentation/managers/proxy_manager.dart';
import 'package:pivox/features/web_scraping/parallel/resource_monitor.dart';
import 'package:pivox/features/web_scraping/parallel/task_scheduler.dart';
import 'package:pivox/features/web_scraping/web_scraper.dart';
import 'package:pivox/features/web_scraping/web_scraper_performance.dart';

import 'presentation/pages/web_scraping_ui_page.dart';
import 'core/mock_proxy_repository.dart';

void main() {
  runApp(const UIExample());
}

class UIExample extends StatefulWidget {
  const UIExample({super.key});

  @override
  State<UIExample> createState() => _UIExampleState();
}

class _UIExampleState extends State<UIExample> {
  late ProxyManager _proxyManager;
  late WebScraper _webScraper;
  late TaskScheduler _taskScheduler;
  late ResourceMonitor _resourceMonitor;
  final Logger _logger = Logger('UIExample');

  bool _isInitialized = false;
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  @override
  void dispose() {
    _taskScheduler.stop();
    _resourceMonitor.stop();
    super.dispose();
  }

  Future<void> _initializeComponents() async {
    try {
      // Create a mock repository
      final mockRepository = MockProxyRepository();

      // Create the use cases
      final getProxies = GetProxies(mockRepository);
      final getValidatedProxies = GetValidatedProxies(mockRepository);
      final validateProxy = ValidateProxy(mockRepository);

      // Initialize the proxy manager
      _proxyManager = ProxyManager(
        getProxies: getProxies,
        getValidatedProxies: getValidatedProxies,
        validateProxy: validateProxy,
      );

      // Initialize the web scraper
      _webScraper = WebScraper(proxyManager: _proxyManager);

      // Initialize the resource monitor
      _resourceMonitor = ResourceMonitor(logger: _logger);
      _resourceMonitor.start();

      // Initialize the task scheduler
      _taskScheduler = _webScraper.createTaskScheduler(
        config: TaskSchedulerConfig.conservative(),
        resourceMonitor: _resourceMonitor,
        logger: _logger,
      );

      setState(() {
        _isInitialized = true;
        _statusText = 'Ready';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pivox UI Example',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Inter'),
      home:
          _isInitialized
              ? WebScrapingUIPage(
                webScraper: _webScraper,
                scheduler: _taskScheduler,
              )
              : Scaffold(
                appBar: AppBar(title: const Text('Pivox UI Example')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_statusText),
                    ],
                  ),
                ),
              ),
    );
  }
}
