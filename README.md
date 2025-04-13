# Pivox: HTTP Proxy Manager for Dart & Flutter

Pivox is a lightweight yet powerful Dart/Flutter package that provides seamless integration with HTTP proxies. It dynamically gathers free proxies from various sources and makes them easy to use with standard HTTP clients.

## Features

- **Free Proxy Sourcing**: Automatically fetch and update proxies from multiple free sources (free-proxy-list.net, geonode.com, proxyscrape.com, proxynova.com)
- **Proxy Rotation**: Cycle through a pool of validated proxies for better reliability
- **Proxy Validation**: Test proxies before using them to ensure they work
- **Simple HTTP Integration**: Easy to use with standard Dart HTTP clients

## Installation

```yaml
dependencies:
  pivox: ^0.0.1
```

## Quick Start

### Basic Usage

```dart
// Create a Pivox client with default settings
final pivoxClient = PivoxClient(
  poolManager: DefaultProxyPoolManager(
    sources: [
      FreeProxyListScraper(),
      GeoNodeProxySource(),
      ProxyScrapeSource(),
      ProxyNovaSource(),
    ],
    rotationStrategy: RoundRobinRotation(),
  ),
  validator: HttpProxyValidator(),
);

// Get a validated proxy
final proxy = await pivoxClient.getProxy();

// Use the proxy with your HTTP client
if (proxy != null) {
  final proxyUrl = PivoxClient.formatProxyUrl(proxy);
  print('Using proxy: $proxyUrl');

  // Your HTTP request code here
}
```

### Using with HTTP Client

#### Method 1: Using PivoxHttpClient (Automatic Rotation)

```dart
// Create a Pivox HTTP client
final httpClient = pivoxClient.createHttpClient();

// Use it like a regular HTTP client
try {
  final response = await httpClient.get(Uri.parse('https://example.com'));
  print(response.body);
} finally {
  httpClient.close();
}
```

#### Method 2: Manual Proxy Configuration

```dart
// Get a proxy
final proxy = await pivoxClient.getProxy();
if (proxy != null) {
  // Create a regular HTTP client
  final client = http.Client();

  try {
    // Create a request
    final request = http.Request('GET', Uri.parse('https://example.com'));

    // Add proxy headers if needed
    request.headers.addAll(PivoxClient.createProxyAuthHeaders(proxy));

    // Send the request
    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    print(response.body);
  } finally {
    client.close();
  }
}
```

## Advanced Usage

### Adding Custom Proxy Sources

```dart
// Add your own proxies
final myProxy = Proxy(
  host: '192.168.1.1',
  port: 8080,
  type: ProxyType.http,
  lastChecked: DateTime.now(),
  responseTime: 100,
  isActive: true,
);

await pivoxClient.addProxy(myProxy);
```

### Handling Proxy Failures

```dart
// Mark a proxy as inactive if it fails
try {
  // Your code using the proxy
} catch (e) {
  await pivoxClient.markProxyAsInactive(proxy);
  // Get a new proxy and retry
}
```

## Example App

Check out the example app in the `example` directory for a complete demonstration of how to use Pivox with HTTP clients.
