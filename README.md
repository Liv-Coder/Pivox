# Pivox

Pivox: The Free Proxy Rotator for Dart & Flutter

Pivox is a lightweight yet powerful Dart/Flutter package that provides seamless integration with free proxy servers. Designed with developers in mind, Pivox dynamically gathers free proxies—whether by scraping reliable proxy-list websites or tapping into public APIs—and manages them efficiently through robust rotation and health-check mechanisms.

## Key Features

### Dynamic Free Proxy Sourcing

Automatically fetch and update proxies from trusted free sources, including web scraping target sites and free-proxy APIs.

### Smart Proxy Rotation with Scoring System

Utilize advanced rotation algorithms with intelligent proxy scoring based on performance metrics to cycle through a pool of validated proxies, ensuring optimal connectivity and performance.

### Parallel Proxy Health Validation

Built-in proxy verification system that tests multiple proxies simultaneously using parallel processing, dramatically improving validation speed while maintaining accuracy.

### Performance Tracking and Optimization

Comprehensive proxy performance tracking with metrics like success rate, response time, and usage statistics to optimize proxy selection and rotation.

### Seamless HTTP Client Integration

Easily integrate with popular Dart HTTP clients like http and dio using custom interceptors and adapters.

### Developer-Friendly & Extensible

Simple configuration, clear documentation, and extensible modules allow you to tailor the package to your unique web scraping or network routing needs.

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

## Usage

### Basic Usage

```dart
import 'package:pivox/pivox.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Initialize dependencies
final sharedPreferences = await SharedPreferences.getInstance();
final localDataSource = ProxyLocalDataSourceImpl(
  sharedPreferences: sharedPreferences,
);
final remoteDataSource = ProxyRemoteDataSourceImpl(
  client: http.Client(),
);

// Initialize repository with parallel processing support
final repository = ProxyRepositoryImpl(
  remoteDataSource: remoteDataSource,
  localDataSource: localDataSource,
  client: http.Client(),
  maxConcurrentValidations: 10, // Validate 10 proxies in parallel
);

// Initialize use cases
final getProxies = GetProxies(repository);
final validateProxy = ValidateProxy(repository);
final getValidatedProxies = GetValidatedProxies(repository);

// Initialize proxy manager
final proxyManager = ProxyManager(
  getProxies: getProxies,
  validateProxy: validateProxy,
  getValidatedProxies: getValidatedProxies,
);

// Create an HTTP client with proxy support
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

### Using with HTTP Client

Here's a more detailed example of using Pivox with the standard HTTP client:

```dart
import 'dart:convert';
import 'package:pivox/pivox.dart';
import 'package:http/http.dart' as http;

// Assuming you've already set up the ProxyManager

// Create an HTTP client with proxy support
final httpClient = ProxyHttpClient(
  proxyManager: proxyManager,
  useValidatedProxies: true, // Only use validated proxies
  rotateProxies: true, // Rotate proxies on each request
);

// Example 1: Basic GET request
final response = await httpClient.get(
  Uri.parse('https://api.ipify.org?format=json'),
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  },
);
print('Your IP: ${response.body}');

// Example 2: POST request with JSON body
final postResponse = await httpClient.post(
  Uri.parse('https://jsonplaceholder.typicode.com/posts'),
  headers: {
    'Content-Type': 'application/json; charset=UTF-8',
  },
  body: jsonEncode({
    'title': 'Test Post',
    'body': 'This is a test post sent through a proxy',
    'userId': 1,
  }),
);
print('Post response: ${postResponse.body}');

// Example 3: Manually setting a specific proxy
// Get a proxy from a specific country (if available)
final proxies = await proxyManager.fetchProxies(countries: ['US']);
if (proxies.isNotEmpty) {
  final specificProxy = proxies.first;
  httpClient.setProxy(specificProxy);

  final specificResponse = await httpClient.get(
    Uri.parse('https://httpbin.org/ip'),
  );
  print('Response with specific proxy: ${specificResponse.body}');
}

// Don't forget to close the client when done
httpClient.close();
```

### Using with Dio

Here's a more detailed example of using Pivox with Dio:

```dart
import 'package:pivox/pivox.dart';
import 'package:dio/dio.dart';

// Assuming you've already set up the ProxyManager

// Create a Dio instance with proxy support
final dio = Dio()
  ..options.connectTimeout = const Duration(seconds: 30) // Longer timeout for proxies
  ..options.receiveTimeout = const Duration(seconds: 30)
  ..interceptors.add(
    ProxyInterceptor(
      proxyManager: proxyManager,
      useValidatedProxies: true, // Only use validated proxies
      rotateProxies: true, // Rotate proxies on each request
      maxRetries: 3, // Retry failed requests with different proxies
    ),
  );

// Example 1: Basic GET request
try {
  final response = await dio.get('https://api.ipify.org?format=json');
  print('Your IP: ${response.data}');
} on DioException catch (e) {
  print('Request failed: ${e.message}');
}

// Example 2: POST request with JSON body
try {
  final postResponse = await dio.post(
    'https://jsonplaceholder.typicode.com/posts',
    data: {
      'title': 'Test Post',
      'body': 'This is a test post sent through a proxy',
      'userId': 1,
    },
    options: Options(headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    }),
  );
  print('Post response: ${postResponse.data}');
} on DioException catch (e) {
  print('Post request failed: ${e.message}');
}

// Example 3: Download a file through proxy
try {
  final downloadResponse = await dio.download(
    'https://example.com/file.pdf',
    'path/to/save/file.pdf',
    onReceiveProgress: (received, total) {
      if (total != -1) {
        print('${(received / total * 100).toStringAsFixed(0)}%');
      }
    },
  );
  print('Download complete: ${downloadResponse.statusCode}');
} on DioException catch (e) {
  print('Download failed: ${e.message}');
}

// Don't forget to close Dio when done
dio.close();
```

### Advanced Features

#### Parallel Proxy Validation with Progress Tracking

```dart
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

#### Intelligent Proxy Selection with Scoring

```dart
// Get a proxy based on its performance score
final proxy = proxyManager.getNextProxy(
  validated: true,
  useScoring: true, // Use the scoring system for selection
);

// Get a random proxy with weighted selection based on scores
final randomProxy = proxyManager.getRandomProxy(
  validated: true,
  useScoring: true,
);

// Validate a proxy and update its score
final isValid = await proxyManager.validateSpecificProxy(
  proxy,
  testUrl: 'https://www.google.com',
  timeout: 5000,
  updateScore: true, // Update the proxy's score based on the result
);
```

### Complete Example

For a complete example with a modern UI featuring dark mode support, see the [example](https://github.com/Liv-Coder/Pivox-/tree/main/example) directory.

## Proxy Sources

Pivox fetches proxies from the following free proxy sources:

- [Free Proxy List](https://free-proxy-list.net/)
- [GeoNode](https://geonode.com/free-proxy-list)
- [ProxyScrape](https://proxyscrape.com/free-proxy-list)
- [ProxyNova](https://www.proxynova.com/proxy-server-list/)

## Documentation

Comprehensive documentation is available in the [documentation.md](../docs/documentation.md) file, which includes:

- Detailed API reference
- Advanced usage examples
- Troubleshooting guide
- Best practices

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
