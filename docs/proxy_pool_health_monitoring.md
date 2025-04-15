# Proxy Pool Health Monitoring

The Proxy Pool Health Monitoring system provides real-time insights into the health and performance of your proxy pool, allowing you to detect and address issues proactively.

## Overview

The monitoring system tracks various metrics about your proxy pool:

- **Overall Health**: Percentage of healthy proxies
- **Success Rates**: Average success rate across all proxies
- **Response Times**: Average response time across all proxies
- **Uptime**: Average uptime across all proxies
- **Top Performers**: Proxies with the highest scores
- **Poor Performers**: Proxies with the lowest scores

## Health Status

The `ProxyPoolHealthStatus` class encapsulates the current health state of the proxy pool:

```dart
class ProxyPoolHealthStatus {
  final int totalProxies;
  final int healthyProxies;
  final int unhealthyProxies;
  final double averageSuccessRate;
  final double averageResponseTime;
  final double averageUptime;
  final DateTime timestamp;
  final List<Proxy> topProxies;
  final List<Proxy> bottomProxies;
  
  double get healthPercentage => 
      totalProxies > 0 ? (healthyProxies / totalProxies) * 100 : 0.0;
  
  bool get isHealthy => healthPercentage >= 50.0;
  
  String get healthStatus {
    if (healthPercentage >= 80.0) return 'Excellent';
    else if (healthPercentage >= 60.0) return 'Good';
    else if (healthPercentage >= 40.0) return 'Fair';
    else if (healthPercentage >= 20.0) return 'Poor';
    else return 'Critical';
  }
}
```

## Health Monitor

The `ProxyPoolHealthMonitor` class provides the monitoring functionality:

```dart
class ProxyPoolHealthMonitor {
  final ProxyManager proxyManager;
  final Duration checkInterval;
  final double healthySuccessRateThreshold;
  final double healthyResponseTimeThreshold;
  final double healthyUptimeThreshold;
  
  Stream<ProxyPoolHealthStatus> get healthStatus => 
      _healthStatusController.stream;
  
  void startMonitoring() { ... }
  void stopMonitoring() { ... }
}
```

## Usage

### Basic Monitoring

```dart
// Create a health monitor
final monitor = ProxyPoolHealthMonitor(
  proxyManager: proxyManager,
  checkInterval: Duration(minutes: 5),
);

// Start monitoring
monitor.startMonitoring();

// Listen for health status updates
monitor.healthStatus.listen((status) {
  print('Proxy Pool Health: ${status.healthStatus}');
  print('Health Percentage: ${status.healthPercentage.toStringAsFixed(1)}%');
  print('Healthy Proxies: ${status.healthyProxies}/${status.totalProxies}');
});
```

### Custom Health Thresholds

```dart
final monitor = ProxyPoolHealthMonitor(
  proxyManager: proxyManager,
  checkInterval: Duration(minutes: 10),
  healthySuccessRateThreshold: 0.8,  // 80% success rate
  healthyResponseTimeThreshold: 1000, // 1 second response time
  healthyUptimeThreshold: 0.9,        // 90% uptime
);
```

### Monitoring UI Integration

```dart
StreamBuilder<ProxyPoolHealthStatus>(
  stream: monitor.healthStatus,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }
    
    final status = snapshot.data!;
    
    return Card(
      color: _getColorForHealth(status.healthPercentage),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Proxy Pool Health: ${status.healthStatus}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${status.healthyProxies}/${status.totalProxies} proxies healthy'),
            LinearProgressIndicator(value: status.healthPercentage / 100),
            // Additional metrics...
          ],
        ),
      ),
    );
  },
)
```

## Benefits

- **Proactive Monitoring**: Detect issues before they impact your application
- **Performance Insights**: Understand how your proxy pool is performing
- **Trend Analysis**: Track changes in proxy health over time
- **Automatic Identification**: Easily identify top and bottom performing proxies
- **Real-time Updates**: Get notified of health changes as they happen

## Integration with Other Features

The health monitoring system works well with other Pivox features:

- **Adaptive Rotation Strategy**: Use health data to inform proxy selection
- **Proxy Quality Scoring**: Health metrics are derived from proxy scores
- **Error Handling**: Monitor the impact of errors on overall pool health
