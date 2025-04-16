import 'package:flutter/foundation.dart';
import 'package:pivox/pivox.dart';

import '../../domain/entities/dashboard_metrics.dart';
import '../../domain/usecases/fetch_proxies.dart';
import '../../domain/usecases/test_proxy.dart';

/// Controller for the home screen
class HomeController extends ChangeNotifier {
  /// Use case for fetching proxies
  final FetchProxies _fetchProxiesUseCase;

  /// Use case for testing proxies
  final TestProxy _testProxyUseCase;

  /// List of proxies
  List<ProxyModel> _proxies = [];

  /// Dashboard metrics
  DashboardMetrics _metrics = DashboardMetrics(
    activeProxies: 0,
    totalProxies: 0,
    successRate: 0.0,
    avgResponseTime: 0.0,
    lastUpdated: DateTime.now(),
  );

  /// Loading state
  bool _isLoading = false;

  /// Response text
  String _responseText = '';

  /// Creates a new [HomeController]
  HomeController({
    required FetchProxies fetchProxiesUseCase,
    required TestProxy testProxyUseCase,
  })  : _fetchProxiesUseCase = fetchProxiesUseCase,
        _testProxyUseCase = testProxyUseCase;

  /// Gets the list of proxies
  List<ProxyModel> get proxies => _proxies;

  /// Gets the dashboard metrics
  DashboardMetrics get metrics => _metrics;

  /// Gets the loading state
  bool get isLoading => _isLoading;

  /// Gets the response text
  String get responseText => _responseText;

  /// Fetches proxies
  Future<void> fetchProxies() async {
    _isLoading = true;
    _responseText = '';
    notifyListeners();

    try {
      final result = await _fetchProxiesUseCase(
        options: ProxyFilterOptions(count: 20, onlyHttps: true),
      );

      _proxies = result.$1;
      _metrics = result.$2;
      _responseText = 'Successfully fetched ${_proxies.length} proxies';
    } catch (e) {
      _responseText = 'Error fetching proxies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tests a proxy connection
  Future<void> testProxy() async {
    _isLoading = true;
    _responseText = '';
    notifyListeners();

    try {
      final response = await _testProxyUseCase('https://api.ipify.org?format=json');
      _responseText = 'HTTP Response: $response';
    } catch (e) {
      _responseText = 'Error with HTTP request: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
