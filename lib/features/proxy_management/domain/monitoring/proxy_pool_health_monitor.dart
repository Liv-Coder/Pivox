import 'dart:async';

import 'package:pivox/features/proxy_management/presentation/managers/proxy_manager.dart';

import '../entities/proxy.dart';
import '../../data/models/proxy_model.dart';

/// Status of the proxy pool health
class ProxyPoolHealthStatus {
  /// The total number of proxies in the pool
  final int totalProxies;

  /// The number of healthy proxies in the pool
  final int healthyProxies;

  /// The number of unhealthy proxies in the pool
  final int unhealthyProxies;

  /// The average success rate of all proxies
  final double averageSuccessRate;

  /// The average response time of all proxies
  final double averageResponseTime;

  /// The average uptime of all proxies
  final double averageUptime;

  /// The timestamp when the status was generated
  final DateTime timestamp;

  /// The proxies with the highest scores
  final List<Proxy> topProxies;

  /// The proxies with the lowest scores
  final List<Proxy> bottomProxies;

  /// Creates a new [ProxyPoolHealthStatus]
  ProxyPoolHealthStatus({
    required this.totalProxies,
    required this.healthyProxies,
    required this.unhealthyProxies,
    required this.averageSuccessRate,
    required this.averageResponseTime,
    required this.averageUptime,
    required this.timestamp,
    required this.topProxies,
    required this.bottomProxies,
  });

  /// Gets the health percentage of the proxy pool
  double get healthPercentage =>
      totalProxies > 0 ? (healthyProxies / totalProxies) * 100 : 0.0;

  /// Gets whether the proxy pool is healthy
  bool get isHealthy => healthPercentage >= 50.0;

  /// Gets the health status as a string
  String get healthStatus {
    if (healthPercentage >= 80.0) {
      return 'Excellent';
    } else if (healthPercentage >= 60.0) {
      return 'Good';
    } else if (healthPercentage >= 40.0) {
      return 'Fair';
    } else if (healthPercentage >= 20.0) {
      return 'Poor';
    } else {
      return 'Critical';
    }
  }

  @override
  String toString() {
    return 'ProxyPoolHealthStatus('
        'health: $healthStatus (${healthPercentage.toStringAsFixed(1)}%), '
        'proxies: $healthyProxies/$totalProxies, '
        'avgSuccess: ${(averageSuccessRate * 100).toStringAsFixed(1)}%, '
        'avgResponse: ${averageResponseTime.toStringAsFixed(0)}ms, '
        'avgUptime: ${(averageUptime * 100).toStringAsFixed(1)}%)';
  }
}

/// A monitor for the health of the proxy pool
class ProxyPoolHealthMonitor {
  /// The proxy manager to monitor
  final ProxyManager proxyManager;

  /// The interval at which to check the health of the proxy pool
  final Duration checkInterval;

  /// The minimum success rate for a proxy to be considered healthy
  final double healthySuccessRateThreshold;

  /// The maximum response time for a proxy to be considered healthy
  final double healthyResponseTimeThreshold;

  /// The minimum uptime for a proxy to be considered healthy
  final double healthyUptimeThreshold;

  /// The number of top proxies to include in the health status
  final int topProxiesCount;

  /// The number of bottom proxies to include in the health status
  final int bottomProxiesCount;

  /// The controller for the health status stream
  final _healthStatusController =
      StreamController<ProxyPoolHealthStatus>.broadcast();

  /// The timer for periodic health checks
  Timer? _timer;

  /// Whether the monitor is running
  bool _isRunning = false;

  /// Creates a new [ProxyPoolHealthMonitor]
  ProxyPoolHealthMonitor({
    required this.proxyManager,
    this.checkInterval = const Duration(minutes: 5),
    this.healthySuccessRateThreshold = 0.7,
    this.healthyResponseTimeThreshold = 2000.0,
    this.healthyUptimeThreshold = 0.8,
    this.topProxiesCount = 5,
    this.bottomProxiesCount = 5,
  });

  /// Gets the stream of health status updates
  Stream<ProxyPoolHealthStatus> get healthStatus =>
      _healthStatusController.stream;

  /// Starts monitoring the proxy pool
  void startMonitoring() {
    if (_isRunning) {
      return;
    }

    _isRunning = true;
    _checkHealth();
    _timer = Timer.periodic(checkInterval, (_) => _checkHealth());
  }

  /// Stops monitoring the proxy pool
  void stopMonitoring() {
    if (!_isRunning) {
      return;
    }

    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Checks the health of the proxy pool
  Future<ProxyPoolHealthStatus> _checkHealth() async {
    final proxies = await proxyManager.getProxies();
    final status = _calculateHealthStatus(proxies);
    _healthStatusController.add(status);
    return status;
  }

  /// Calculates the health status of the proxy pool
  ProxyPoolHealthStatus _calculateHealthStatus(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      return ProxyPoolHealthStatus(
        totalProxies: 0,
        healthyProxies: 0,
        unhealthyProxies: 0,
        averageSuccessRate: 0.0,
        averageResponseTime: 0.0,
        averageUptime: 0.0,
        timestamp: DateTime.now(),
        topProxies: [],
        bottomProxies: [],
      );
    }

    int healthyCount = 0;
    double totalSuccessRate = 0.0;
    double totalResponseTime = 0.0;
    double totalUptime = 0.0;
    int scoredProxiesCount = 0;

    // Calculate health metrics
    for (final proxy in proxies) {
      if (proxy is ProxyModel && proxy.score != null) {
        final score = proxy.score!;
        scoredProxiesCount++;

        totalSuccessRate += score.successRate;
        totalResponseTime += score.averageResponseTime.toDouble();
        totalUptime += score.uptime;

        if (score.successRate >= healthySuccessRateThreshold &&
            score.averageResponseTime <= healthyResponseTimeThreshold &&
            score.uptime >= healthyUptimeThreshold) {
          healthyCount++;
        }
      }
    }

    // Calculate averages
    final averageSuccessRate =
        scoredProxiesCount > 0 ? totalSuccessRate / scoredProxiesCount : 0.0;
    final averageResponseTime =
        scoredProxiesCount > 0 ? totalResponseTime / scoredProxiesCount : 0.0;
    final averageUptime =
        scoredProxiesCount > 0 ? totalUptime / scoredProxiesCount : 0.0;

    // Sort proxies by score
    final scoredProxies =
        proxies
            .where((p) => p is ProxyModel && p.score != null)
            .cast<ProxyModel>()
            .toList();
    scoredProxies.sort((a, b) {
      final aScore = a.score!.compositeScore;
      final bScore = b.score!.compositeScore;
      return bScore.compareTo(aScore); // Descending order
    });

    // Get top and bottom proxies
    final topProxies = scoredProxies.take(topProxiesCount).toList();
    final bottomProxies =
        scoredProxies.reversed.take(bottomProxiesCount).toList();

    return ProxyPoolHealthStatus(
      totalProxies: proxies.length,
      healthyProxies: healthyCount,
      unhealthyProxies: proxies.length - healthyCount,
      averageSuccessRate: averageSuccessRate,
      averageResponseTime: averageResponseTime,
      averageUptime: averageUptime,
      timestamp: DateTime.now(),
      topProxies: topProxies,
      bottomProxies: bottomProxies,
    );
  }

  /// Disposes the monitor
  void dispose() {
    stopMonitoring();
    _healthStatusController.close();
  }
}
