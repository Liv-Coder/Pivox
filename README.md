# Pivox

Pivox: The Free Proxy Rotator for Dart & Flutter

Pivox is a lightweight yet powerful Dart/Flutter package that provides seamless integration with free proxy servers. Designed with developers in mind, Pivox dynamically gathers free proxies—whether by scraping reliable proxy-list websites or tapping into public APIs—and manages them efficiently through robust rotation and health-check mechanisms.

## Key Features

### Dynamic Free Proxy Sourcing

Automatically fetch and update proxies from trusted free sources, including web scraping target sites and free-proxy APIs.

### Smart Proxy Rotation with Advanced Scoring System

Utilize advanced rotation algorithms with intelligent proxy scoring based on comprehensive performance metrics including success rate, response time, uptime, stability, and geographical distance to cycle through a pool of validated proxies, ensuring optimal connectivity and performance.

#### Multiple Rotation Strategies

- **Round Robin**: Simple sequential rotation through available proxies
- **Random**: Random selection from the proxy pool
- **Weighted**: Selection based on proxy performance metrics
- **Geo-based**: Rotation through proxies from different countries or regions
- **Advanced**: Combines multiple factors including failure tracking and usage frequency

### Parallel Proxy Health Validation

Built-in proxy verification system that tests multiple proxies simultaneously using parallel processing, dramatically improving validation speed while maintaining accuracy. Supports authenticated proxies and custom validation parameters.

#### Enhanced Validation Features

- **Isolate-based Parallel Processing**: Utilizes Dart Isolates for true parallel validation
- **Authentication Support**: Basic, Digest, and NTLM authentication methods
- **SOCKS Proxy Support**: Validation for SOCKS4 and SOCKS5 proxies
- **Custom Validation Parameters**: Configure timeout, test URLs, and validation criteria

### Advanced Filtering and Configuration

Powerful filtering options for proxies based on country, region, ISP, speed, protocol support, and more. Configure which proxy sources to use and add custom sources.

#### Comprehensive Filtering Options

```dart
final proxies = await pivox.fetchProxies(
  options: ProxyFilterOptions(
    count: 10,
    onlyHttps: true,
    countries: ['US', 'CA'],
    regions: ['California'],
    isps: ['Comcast'],
    minSpeed: 100,
    requireWebsockets: true,
    requireSocks: false,
    requireAuthentication: false,
    requireAnonymous: true,
  ),
);
```

### Performance Tracking and Analytics

Comprehensive proxy performance tracking with detailed analytics including success rate, response time, uptime, stability, and usage statistics to optimize proxy selection and rotation.

### Seamless HTTP Client Integration

Easily integrate with popular Dart HTTP clients like http and dio using custom interceptors and adapters.

### Advanced Web Scraping Capabilities

Pivox includes powerful web scraping features to handle even the most challenging websites:

- **Headless Browser Integration**: Handle JavaScript-heavy sites and dynamic content with full browser capabilities
- **Dynamic User Agent Management**: Automatically rotate through modern, realistic user agents to avoid detection
- **Specialized Site Handlers**: Custom handlers for problematic websites with anti-scraping measures
- **Structured Data Extraction**: Extract structured data from HTML content using CSS selectors
- **Rate Limiting**: Respect website rate limits to avoid blocking
- **Cookie Management**: Handle cookies for authenticated scraping

### Developer-Friendly & Extensible

Simple configuration, clear documentation, and extensible modules allow you to tailor the package to your unique web scraping or network routing needs.

## Installation

Add Pivox to your `pubspec.yaml` file:

```yaml
dependencies:
  pivox: ^1.1.0
```

Or install it from the command line:

```bash
flutter pub add pivox
```

## What's New in Version 1.1.0

### Performance and Reliability Improvements

#### Streaming HTML Parser

Process HTML incrementally to reduce memory usage for large documents:

```dart
import 'package:pivox/pivox.dart';

// Create a web scraper with streaming capabilities
final proxyManager = await Pivox.createProxyManager();
final webScraper = await Pivox.createWebScraper(proxyManager: proxyManager);

// Extract data using streaming for memory efficiency
final dataStream = webScraper.extractDataStream(
  url: 'https://example.com/large-page',
  selector: '.item',
  chunkSize: 512 * 1024, // Process in 512KB chunks
);

// Process data as it arrives
await for (final item in dataStream) {
  print('Found item: $item');
}
```

#### Concurrent Web Scraping

Process multiple URLs simultaneously with priority-based scheduling:

```dart
import 'package:pivox/pivox.dart';

// Create a concurrent web scraper
final proxyManager = await Pivox.createProxyManager();
final concurrentScraper = await Pivox.createConcurrentWebScraper(
  proxyManager: proxyManager,
  maxConcurrentTasks: 10,
);

// Scrape multiple URLs concurrently
final results = await concurrentScraper.fetchHtmlBatch(
  urls: [
    'https://example.com/page1',
    'https://example.com/page2',
    'https://example.com/page3',
  ],
  onProgress: (completed, total, url) {
    print('Completed $completed of $total: $url');
  },
);

// Extract data from multiple URLs with different priorities
final highPriorityData = concurrentScraper.extractData(
  url: 'https://example.com/important',
  selector: '.data',
  priority: 10, // Higher priority
);

final lowPriorityData = concurrentScraper.extractData(
  url: 'https://example.com/less-important',
  selector: '.data',
  priority: 1, // Lower priority
);

// High priority task will be processed first
final results = await Future.wait([highPriorityData, lowPriorityData]);
```

#### Memory-Efficient Parsing

Process large HTML documents without loading them entirely into memory:

```dart
import 'package:pivox/pivox.dart';

// Create an advanced web scraper
final proxyManager = await Pivox.createProxyManager();
final advancedScraper = await Pivox.createAdvancedWebScraper(
  proxyManager: proxyManager,
);

// Fetch a large HTML document
final html = await advancedScraper.fetchHtml(
  url: 'https://example.com/very-large-page',
);

// Extract data using memory-efficient parsing
final data = advancedScraper.extractDataEfficient(
  html: html,
  selector: '.item',
  chunkSize: 1024 * 1024, // Process in 1MB chunks
);

print('Extracted ${data.length} items');
```

#### Factory Methods

Simplified component creation with the new `PivoxFactory` class:

```dart
import 'package:pivox/pivox.dart';

// Create components with factory methods
final proxyManager = await Pivox.createProxyManager();
final webScraper = await Pivox.createWebScraper(proxyManager: proxyManager);
final advancedScraper = await Pivox.createAdvancedWebScraper(proxyManager: proxyManager);
final concurrentScraper = await Pivox.createConcurrentWebScraper(proxyManager: proxyManager);

// Or use the PivoxFactory directly for more control
final customScraper = PivoxFactory.createWebScraper(
  proxyManager: proxyManager,
  defaultTimeout: 60000,
  maxRetries: 5,
  respectRobotsTxt: true,
);
```

## Usage

### Quick Start

Pivox now offers a simplified initialization process with sensible defaults:

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

### Customized Setup

For more control, use the builder pattern:

```dart
import 'package:pivox/pivox.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Get dependencies if you want to reuse existing instances
final sharedPreferences = await SharedPreferences.getInstance();
final httpClient = http.Client();

// Use the builder pattern for customized setup
final proxyManager = await Pivox.builder()
  .withHttpClient(httpClient)
  .withSharedPreferences(sharedPreferences)
  .withMaxConcurrentValidations(20) // Increase parallel validations
  .withAnalytics(true) // Enable analytics tracking
  .withRotationStrategy(RotationStrategyType.weighted) // Use weighted rotation
  .withProxySourceConfig(ProxySourceConfig.only(
    freeProxyList: true,
    geoNode: true,
    proxyScrape: false,
    proxyNova: false,
    custom: ['https://my-custom-proxy-source.com'],
  )) // Configure proxy sources
  .buildProxyManager();

// Create an HTTP client with the configured proxy manager
final proxyHttpClient = ProxyHttpClient(
  proxyManager: proxyManager,
  useValidatedProxies: true,
  rotateProxies: true,
);

// Make a request using the proxy
final response = await proxyHttpClient.get(
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
// Get a proxy from a specific country with advanced filtering
final proxies = await proxyManager.fetchProxies(
  options: ProxyFilterOptions(
    count: 5,
    onlyHttps: true,
    countries: ['US'],
    regions: ['California'],
    minSpeed: 10.0, // Minimum 10 Mbps
    requireAnonymous: true,
  ),
);

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

// Quick setup with one line
final proxyInterceptor = await Pivox.createDioInterceptor();

// Create a Dio instance with proxy support
final dio = Dio()
  ..options.connectTimeout = const Duration(seconds: 30) // Longer timeout for proxies
  ..options.receiveTimeout = const Duration(seconds: 30)
  ..interceptors.add(proxyInterceptor);

// For more customization:
// final customInterceptor = await Pivox.builder()
//   .withMaxRetries(5)
//   .withUseValidatedProxies(true)
//   .withRotateProxies(true)
//   .buildDioInterceptor();

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

#### Advanced Rotation Strategies

```dart
import 'package:pivox/pivox.dart';

// Create a proxy manager with weighted rotation strategy
final proxyManager = await Pivox.builder()
  .withRotationStrategy(RotationStrategyType.weighted)
  .build();

// Get the next proxy using weighted selection based on performance
final proxy = proxyManager.getNextProxy();

// Create a proxy manager with geo-based rotation strategy
final geoProxyManager = await Pivox.builder()
  .withRotationStrategy(RotationStrategyType.geoBased)
  .build();

// Get the next proxy from a different country than the previous one
final geoProxy = geoProxyManager.getNextProxy();

// Create a proxy manager with advanced rotation strategy
final advancedProxyManager = await Pivox.builder()
  .withRotationStrategy(RotationStrategyType.advanced)
  .build();

// Get the next proxy using advanced selection criteria
final advancedProxy = advancedProxyManager.getNextProxy();
```

#### Parallel Proxy Validation with Progress Tracking

```dart
import 'package:pivox/pivox.dart';

// Get a proxy manager with default settings
final proxyManager = await Pivox.createProxyManager();

// Fetch and validate proxies with progress tracking and advanced filtering
final validatedProxies = await proxyManager.fetchValidatedProxies(
  options: ProxyFilterOptions(
    count: 10,
    onlyHttps: true,
    countries: ['US', 'CA'],
    requireWebsockets: true,
    requireAnonymous: true,
  ),
  onProgress: (completed, total) {
    print('Validated $completed of $total proxies');
  },
);
```

#### Intelligent Proxy Selection with Advanced Scoring

```dart
import 'package:pivox/pivox.dart';

// Get a proxy manager with customized settings
final proxyManager = await Pivox.builder()
  .withMaxConcurrentValidations(15)
  .withAnalytics(true)
  .buildProxyManager();

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

// Get analytics data
final analytics = await proxyManager.getAnalytics();
print('Total proxies fetched: ${analytics?.totalProxiesFetched}');
print('Success rate: ${analytics?.averageSuccessRate}');
print('Average response time: ${analytics?.averageResponseTime} ms');
```

#### Advanced Web Scraping with Specialized Site Handlers

```dart
import 'package:pivox/pivox.dart';

// Create a web scraper with proxy support
final proxyManager = await Pivox.createProxyManager();
final webScraper = WebScraper(
  proxyManager: proxyManager,
  defaultTimeout: 60000,
  maxRetries: 5,
);

// Create a dynamic user agent manager
final userAgentManager = DynamicUserAgentManager();

// Check if the site is known to be problematic
final url = 'https://onlinekhabar.com';
final isProblematic = webScraper.reputationTracker.isProblematicSite(url);

String html;
if (isProblematic || url.contains('onlinekhabar.com') || url.contains('vegamovies')) {
  // Use specialized approach for problematic sites
  print('Using specialized handler for problematic site');
  html = await webScraper.fetchFromProblematicSite(
    url: url,
    headers: {
      'User-Agent': userAgentManager.getRandomUserAgentForSite(url),
    },
    timeout: 60000,
    retries: 5,
  );
} else {
  // Use standard approach
  html = await webScraper.fetchHtml(
    url: url,
    headers: {
      'User-Agent': userAgentManager.getRandomUserAgent(),
    },
  );
}

// Extract structured data
final selectors = {
  'title': 'title',
  'heading': 'h1',
  'article': '.article-body',
  'links': 'a',
};

final attributes = {
  'links': 'href',
};

final data = webScraper.extractStructuredData(
  html: html,
  selectors: selectors,
  attributes: attributes,
);

print('Extracted ${data.length} items');
data.forEach((item) {
  print('Title: ${item['title']}');
  print('Heading: ${item['heading']}');
});
```

#### Headless Browser for JavaScript-Heavy Sites

```dart
import 'package:pivox/pivox.dart';

// Create a headless browser service with default settings
final browserService = await Pivox.createHeadlessBrowserService();

// Scrape a JavaScript-heavy website
final result = await browserService.scrapeUrl(
  'https://example.com/js-heavy-site',
  selectors: {
    'title': 'h1',
    'content': '.dynamic-content',
    'items': '.item',
  },
);

if (result.success) {
  print('Title: ${result.data?['title']}');
  print('Content: ${result.data?['content']}');

  final items = result.data?['items'] as List<dynamic>?;
  print('Found ${items?.length} items');

  // You can also access the full HTML
  print('HTML length: ${result.html?.length}');
} else {
  print('Error: ${result.errorMessage}');
}

// For sites with lazy loading or infinite scrolling
final handlers = await Pivox.createSpecializedHeadlessHandlers();

final lazyResult = await handlers.handleLazyLoadingSite(
  'https://example.com/lazy-loading-page',
  selectors: {
    'products': '.product-card',
    'prices': '.price',
  },
  scrollCount: 5,  // Scroll 5 times to load more content
  scrollDelay: 1000,  // Wait 1 second between scrolls
);

// Don't forget to dispose when done
await browserService.dispose();
await handlers.dispose();
```

### Complete Example

For a complete example with a modern UI featuring dark mode support, see the [example](https://github.com/Liv-Coder/Pivox-/tree/main/example) directory.

## Proxy Sources

Pivox fetches proxies from the following free proxy sources:

- [Free Proxy List](https://free-proxy-list.net/)
- [GeoNode](https://geonode.com/free-proxy-list)
- [ProxyScrape](https://proxyscrape.com/free-proxy-list)
- [ProxyNova](https://www.proxynova.com/proxy-server-list/)

You can configure which sources to use and add your own custom sources using the `ProxySourceConfig` class.

## Documentation

Comprehensive documentation is available in the following files:

- [Main Documentation](../doc/documentation.md): Detailed API reference, usage examples, and troubleshooting guide
- [Web Scraping Documentation](../doc/web_scraping.md): Specialized documentation for web scraping features
- [Headless Browser Documentation](../doc/headless_browser.md): Guide to using the headless browser integration

The documentation includes:

- Detailed API reference
- Advanced usage examples
- Web scraping techniques
- Dynamic user agent management
- Specialized site handlers
- Troubleshooting guide
- Best practices

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
