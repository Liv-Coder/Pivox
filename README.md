# Pivox

Pivox: The Free Proxy Rotator for Dart & Flutter

Pivox is a lightweight yet powerful Dart/Flutter package that provides seamless integration with free proxy servers. Designed with developers in mind, Pivox dynamically gathers free proxies—whether by scraping reliable proxy-list websites or tapping into public APIs—and manages them efficiently through robust rotation and health-check mechanisms.

## Key Features

### Dynamic Free Proxy Sourcing

Automatically fetch and update proxies from trusted free sources, including web scraping target sites and free-proxy APIs.

### Smart Proxy Rotation

Utilize advanced rotation algorithms to cycle through a pool of validated proxies, ensuring optimal connectivity and performance.

### Proxy Health Validation

Built-in proxy verification system that tests each proxy’s responsiveness and removes those that fail to meet quality standards.

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
final repository = ProxyRepositoryImpl(
  remoteDataSource: remoteDataSource,
  localDataSource: localDataSource,
  client: http.Client(),
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

### Using with Dio

```dart
import 'package:pivox/pivox.dart';
import 'package:dio/dio.dart';

// Initialize proxy manager (see above)

// Create a Dio instance with proxy support
final dio = Dio()
  ..interceptors.add(
    ProxyInterceptor(
      proxyManager: proxyManager,
      useValidatedProxies: true,
      rotateProxies: true,
    ),
  );

// Make a request using the proxy
final response = await dio.get('https://api.ipify.org?format=json');

print('Response: ${response.data}');
```

### Complete Example

For a complete example, see the [example](https://github.com/Liv-Coder/Pivox-/tree/main/example) directory.

## Proxy Sources

Pivox fetches proxies from the following free proxy sources:

- [Free Proxy List](https://free-proxy-list.net/)
- [GeoNode](https://geonode.com/free-proxy-list)
- [ProxyScrape](https://proxyscrape.com/free-proxy-list)
- [ProxyNova](https://www.proxynova.com/proxy-server-list/)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
