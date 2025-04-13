# Pivox API Documentation

Pivox is a powerful Dart/Flutter package for free proxy rotation with a clean architecture approach. This document provides comprehensive documentation for the Pivox API.

## Table of Contents

1. [Installation](#installation)
2. [Core Concepts](#core-concepts)
3. [Basic Usage](#basic-usage)
4. [Advanced Usage](#advanced-usage)
5. [API Reference](#api-reference)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)

## Installation

Add Pivox to your `pubspec.yaml` file:

```yaml
dependencies:
  pivox: ^0.0.1
```

Or install it from the command line:

```bash
flutter pub add pivox
```

## Core Concepts

Pivox is built around several core concepts:

### Proxy

A `Proxy` represents a proxy server with its IP address, port, and additional metadata like country code, HTTPS support, and anonymity level.

### ProxyScore

A `ProxyScore` represents the performance metrics of a proxy, including success rate, average response time, and usage statistics. This is used for intelligent proxy selection.

### ProxyManager

The `ProxyManager` is the main entry point for using Pivox. It manages proxy fetching, validation, and rotation.

### HTTP Integration

Pivox provides seamless integration with popular Dart HTTP clients like `http` and `dio`.

## Basic Usage

### Simplified Initialization

Pivox offers a simplified initialization process with sensible defaults:

```dart
import 'package:pivox/pivox.dart';

// One-line initialization with default settings
final httpClient = await Pivox.createHttpClient();

// Make a request using the proxy
final response = await httpClient.get(
  Uri.parse('https://api.ipify.org?format=json'),
);

print('Response: ${response.body}');
```

### Using the Builder Pattern

For more control, use the builder pattern:

```dart
import 'package:pivox/pivox.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Get dependencies if you want to reuse existing instances
final sharedPreferences = await SharedPreferences.getInstance();

// Use the builder pattern for customized setup
final proxyManager = await Pivox.builder()
  .withSharedPreferences(sharedPreferences)
  .withMaxConcurrentValidations(20) // Increase parallel validations
  .buildProxyManager();

// Create an HTTP client with the configured proxy manager
final httpClient = ProxyHttpClient(
  proxyManager: proxyManager,
  useValidatedProxies: true,
  rotateProxies: true,
);

// Make a request using the proxy
final response = await httpClient.get(
  Uri.parse('https://api.ipify.org?format=json'),
);

print('Response: ${response.body}');
```

### Using with Dio

```dart
import 'package:pivox/pivox.dart';
import 'package:dio/dio.dart';

// Quick setup with one line
final proxyInterceptor = await Pivox.createDioInterceptor();

// Create a Dio instance with proxy support
final dio = Dio()
  ..options.connectTimeout = const Duration(seconds: 30)
  ..options.receiveTimeout = const Duration(seconds: 30)
  ..interceptors.add(proxyInterceptor);

// Make a request using the proxy
final response = await dio.get('https://api.ipify.org?format=json');

print('Response: ${response.data}');
```

## Advanced Usage

### Parallel Proxy Validation

Pivox supports parallel proxy validation to speed up the validation process:

```dart
// Get a proxy manager with default settings
final proxyManager = await Pivox.createProxyManager();

// Fetch and validate proxies with progress tracking
final validatedProxies = await proxyManager.fetchValidatedProxies(
  count: 10,
  onlyHttps: true,
  countries: ['US', 'CA'],
  onProgress: (completed, total) {
    print('Validated $completed of $total proxies');
  },
);
```

### Proxy Scoring and Weighted Selection

Pivox includes a sophisticated proxy scoring system that tracks proxy performance:

```dart
// Get a proxy manager with customized settings
final proxyManager = await Pivox.builder()
  .withMaxConcurrentValidations(15)
  .buildProxyManager();

// Get a proxy based on its score
final proxy = proxyManager.getNextProxy(
  validated: true,
  useScoring: true, // Use the scoring system for selection
);

// Get a random proxy with weighted selection based on scores
final randomProxy = proxyManager.getRandomProxy(
  validated: true,
  useScoring: true,
);
```

### Tracking Proxy Performance

Pivox automatically tracks proxy performance when you validate or use proxies:

```dart
// Validate a proxy and update its score
final isValid = await proxyManager.validateSpecificProxy(
  proxy,
  testUrl: 'https://www.google.com',
  timeout: 5000,
  updateScore: true, // Update the proxy's score based on the result
);
```

## API Reference

### Pivox (Factory Methods)

```dart
class Pivox {
  /// Creates a new PivoxBuilder instance
  static PivoxBuilder builder();
  
  /// Creates a ProxyManager with default settings
  static Future<ProxyManager> createProxyManager();
  
  /// Creates an HTTP client with proxy support using default settings
  static Future<ProxyHttpClient> createHttpClient();
  
  /// Creates a Dio interceptor for proxy support using default settings
  static Future<ProxyInterceptor> createDioInterceptor();
}
```

### PivoxBuilder

```dart
class PivoxBuilder {
  /// Sets the HTTP client to use
  PivoxBuilder withHttpClient(http.Client httpClient);
  
  /// Sets the SharedPreferences instance to use
  PivoxBuilder withSharedPreferences(SharedPreferences sharedPreferences);
  
  /// Sets the maximum number of concurrent validations
  PivoxBuilder withMaxConcurrentValidations(int maxConcurrentValidations);
  
  /// Sets whether to use validated proxies by default
  PivoxBuilder withUseValidatedProxies(bool useValidatedProxies);
  
  /// Sets whether to rotate proxies by default
  PivoxBuilder withRotateProxies(bool rotateProxies);
  
  /// Sets the maximum number of retries for Dio requests
  PivoxBuilder withMaxRetries(int maxRetries);
  
  /// Builds a ProxyManager instance
  Future<ProxyManager> buildProxyManager();
  
  /// Builds an HTTP client with proxy support
  Future<ProxyHttpClient> buildHttpClient();
  
  /// Creates a Dio interceptor for proxy support
  Future<ProxyInterceptor> buildDioInterceptor();
}
```

### Proxy

```dart
class Proxy {
  final String ip;
  final int port;
  final String? countryCode;
  final bool isHttps;
  final String? anonymityLevel;
  
  const Proxy({
    required this.ip,
    required this.port,
    this.countryCode,
    this.isHttps = false,
    this.anonymityLevel,
  });
}
```

### ProxyModel

```dart
class ProxyModel extends Proxy {
  final int? lastChecked;
  final int? responseTime;
  final ProxyScore? score;
  
  const ProxyModel({
    required super.ip,
    required super.port,
    super.countryCode,
    super.isHttps,
    super.anonymityLevel,
    this.lastChecked,
    this.responseTime,
    this.score,
  });
  
  // Factory methods and utility functions
  factory ProxyModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  factory ProxyModel.fromEntity(Proxy proxy);
  ProxyModel withSuccessfulRequest(int responseTime);
  ProxyModel withFailedRequest();
}
```

### ProxyScore

```dart
class ProxyScore {
  final double successRate;
  final int averageResponseTime;
  final int successfulRequests;
  final int failedRequests;
  final int lastUsed;
  
  const ProxyScore({
    required this.successRate,
    required this.averageResponseTime,
    required this.successfulRequests,
    required this.failedRequests,
    required this.lastUsed,
  });
  
  // Factory methods and utility functions
  factory ProxyScore.initial();
  ProxyScore recordSuccess(int responseTime);
  ProxyScore recordFailure();
  double calculateScore();
  factory ProxyScore.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### ProxyManager

```dart
class ProxyManager {
  final GetProxies getProxies;
  final ValidateProxy validateProxy;
  final GetValidatedProxies getValidatedProxies;
  
  ProxyManager({
    required this.getProxies,
    required this.validateProxy,
    required this.getValidatedProxies,
  });
  
  // Methods
  Future<List<Proxy>> fetchProxies({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  });
  
  Future<List<Proxy>> fetchValidatedProxies({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  });
  
  Proxy getNextProxy({
    bool validated = true,
    bool useScoring = false,
  });
  
  Proxy getRandomProxy({
    bool validated = true,
    bool useScoring = false,
  });
  
  Future<bool> validateSpecificProxy(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
    bool updateScore = true,
  });
  
  // Properties
  List<Proxy> get proxies;
  List<Proxy> get validatedProxies;
}
```

### ProxyHttpClient

```dart
class ProxyHttpClient extends http.BaseClient {
  ProxyHttpClient({
    http.Client? inner,
    required ProxyManager proxyManager,
    bool useValidatedProxies = true,
    bool rotateProxies = true,
  });
  
  // Methods
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request);
  
  @override
  void close();
  
  // Properties
  Proxy? currentProxy;
  
  // Methods
  void setProxy(Proxy? proxy);
}
```

### ProxyInterceptor

```dart
class ProxyInterceptor extends Interceptor {
  ProxyInterceptor({
    required ProxyManager proxyManager,
    bool useValidatedProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
  });
  
  // Methods
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler);
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler);
  
  // Properties
  Proxy? currentProxy;
  
  // Methods
  void setProxy(Proxy? proxy);
}
```

## Examples

### Web Scraping Example

```dart
import 'package:pivox/pivox.dart';

Future<void> main() async {
  // Create an HTTP client with proxy support using one line
  final httpClient = await Pivox.createHttpClient();
  
  // Scrape a website
  final response = await httpClient.get(
    Uri.parse('https://example.com'),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    },
  );
  
  // Process the response
  if (response.statusCode == 200) {
    print('Successfully scraped the website');
    print('Content length: ${response.body.length}');
  } else {
    print('Failed to scrape the website: ${response.statusCode}');
  }
  
  // Don't forget to close the client
  httpClient.close();
}
```

### API Testing Example

```dart
import 'package:pivox/pivox.dart';
import 'package:dio/dio.dart';

Future<void> main() async {
  // Create a Dio instance with proxy support using one line
  final proxyInterceptor = await Pivox.createDioInterceptor();
  
  final dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 30)
    ..interceptors.add(proxyInterceptor);
  
  // Test an API
  try {
    final response = await dio.get(
      'https://api.example.com/data',
      options: Options(
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY',
        },
      ),
    );
    
    print('API response: ${response.data}');
  } on DioException catch (e) {
    print('API request failed: ${e.message}');
  }
  
  // Don't forget to close Dio
  dio.close();
}
```

## Troubleshooting

### No Valid Proxies Available

If you encounter a `NoValidProxiesException`, it means that no valid proxies were found. Try the following:

1. Increase the number of proxies to fetch:
   ```dart
   final proxyManager = await Pivox.builder()
     .buildProxyManager();
   
   await proxyManager.fetchProxies(count: 50);
   ```

2. Relax the filtering criteria:
   ```dart
   await proxyManager.fetchProxies(onlyHttps: false);
   ```

3. Check your internet connection.

### Slow Proxy Validation

If proxy validation is taking too long, try:

1. Increase the number of concurrent validations:
   ```dart
   final proxyManager = await Pivox.builder()
     .withMaxConcurrentValidations(20)
     .buildProxyManager();
   ```

2. Reduce the validation timeout:
   ```dart
   await proxyManager.validateSpecificProxy(
     proxy,
     timeout: 5000, // 5 seconds
   );
   ```

### Proxy Connection Failures

If you're experiencing connection failures with proxies:

1. Make sure the proxies support the protocol you're using (HTTP/HTTPS).
2. Try using validated proxies only:
   ```dart
   final httpClient = await Pivox.builder()
     .withUseValidatedProxies(true)
     .buildHttpClient();
   ```

3. Implement retry logic with Dio:
   ```dart
   final proxyInterceptor = await Pivox.builder()
     .withMaxRetries(5)
     .buildDioInterceptor();
   ```
