# Pivox Documentation

Pivox is a powerful Dart/Flutter package for free proxy rotation with a clean architecture. This documentation covers the core features and advanced capabilities of the package.

## Core Features

- **Dynamic Proxy Sourcing**: Fetch proxies from multiple free sources
- **Smart Proxy Rotation**: Multiple strategies for rotating through proxies
- **Health Validation**: Validate proxies before using them
- **HTTP Client Integration**: Seamless integration with both `http` and `dio` packages
- **Local Caching**: Cache proxies for offline use with SharedPreferences

## Advanced Features

- [**Proxy Quality Scoring System**](proxy_quality_scoring.md): Track and evaluate proxy performance over time
- [**Adaptive Proxy Rotation Strategy**](adaptive_rotation_strategy.md): Intelligent proxy selection that learns and adapts
- [**Enhanced Error Handling and Retry Logic**](error_handling.md): Robust error handling with sophisticated retry mechanisms
- [**Proxy Pool Health Monitoring**](proxy_pool_health_monitoring.md): Real-time insights into proxy pool health

## Getting Started

### Installation

Add Pivox to your `pubspec.yaml`:

```yaml
dependencies:
  pivox: ^1.0.0
```

### Basic Usage

```dart
import 'package:pivox/pivox.dart';

void main() async {
  // Initialize Pivox
  final pivox = Pivox.initialize();
  
  // Fetch and validate proxies
  final proxies = await pivox.fetchValidatedProxies();
  
  // Create an HTTP client with proxy rotation
  final client = pivox.createHttpClient();
  
  // Make a request
  final response = await client.get(Uri.parse('https://example.com'));
  print(response.body);
}
```

### Advanced Usage

```dart
import 'package:pivox/pivox.dart';

void main() async {
  // Initialize with custom configuration
  final pivox = Pivox.builder()
    .withProxySources(['free-proxy-list', 'geonode'])
    .withRotationStrategy(RotationStrategyType.adaptive)
    .withRetryPolicy(ProxyRetryPolicy.exponentialBackoff())
    .withHealthMonitoring(checkInterval: Duration(minutes: 5))
    .build();
  
  // Start health monitoring
  pivox.startHealthMonitoring();
  
  // Listen for health status updates
  pivox.healthStatus.listen((status) {
    print('Proxy Pool Health: ${status.healthStatus}');
  });
  
  // Create a client with the adaptive rotation strategy
  final client = pivox.createHttpClient(
    rotationStrategy: RotationStrategyType.adaptive,
  );
  
  // Make requests with automatic retry and rotation
  try {
    final response = await client.get(Uri.parse('https://example.com'));
    print(response.body);
  } catch (e) {
    print('Error: $e');
  }
}
```

## Architecture

Pivox follows a clean architecture with:

- **Domain Layer**: Entities, repositories, use cases
- **Data Layer**: Models, data sources
- **Presentation Layer**: Proxy manager, HTTP integration

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Pivox is available under the MIT license. See the LICENSE file for more info.
