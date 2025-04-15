# Pivox API Documentation

Pivox is a powerful Dart/Flutter package for free proxy rotation with a clean architecture approach. This document provides comprehensive documentation for the Pivox API.

## Table of Contents

1. [Installation](#installation)
2. [Core Concepts](#core-concepts)
3. [Basic Usage](#basic-usage)
4. [Advanced Usage](#advanced-usage)
5. [Web Scraping](#web-scraping)
6. [API Reference](#api-reference)
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)

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

A `Proxy` represents a proxy server with its IP address, port, and additional metadata like country code, HTTPS support, anonymity level, region, ISP, speed, protocol support, and authentication credentials.

### ProxyScore

A `ProxyScore` represents the performance metrics of a proxy, including success rate, response time, uptime, stability, age, geographical distance, and consecutive success/failure counts. This is used for intelligent proxy selection.

### ProxyFilterOptions

A `ProxyFilterOptions` provides advanced filtering capabilities for proxies based on various criteria like country, region, ISP, speed, protocol support, and more.

### ProxySourceConfig

A `ProxySourceConfig` allows you to configure which proxy sources to use and add custom sources.

### ProxyAnalytics

A `ProxyAnalytics` tracks and reports proxy usage statistics, including success rates, response times, and usage patterns.

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
  .withAnalytics(true) // Enable analytics tracking
  .withProxySourceConfig(ProxySourceConfig.only(
    freeProxyList: true,
    geoNode: true,
    proxyScrape: false,
    proxyNova: false,
    custom: ['https://my-custom-proxy-source.com'],
  )) // Configure proxy sources
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

### Advanced Proxy Filtering

Pivox provides powerful filtering options for proxies:

```dart
// Get a proxy manager with default settings
final proxyManager = await Pivox.createProxyManager();

// Fetch proxies with advanced filtering
final proxies = await proxyManager.fetchProxies(
  options: ProxyFilterOptions(
    count: 20,
    onlyHttps: true,
    countries: ['US', 'CA'],
    regions: ['California', 'New York'],
    isps: ['Comcast', 'AT&T'],
    minSpeed: 10.0, // Minimum 10 Mbps
    requireWebsockets: true,
    requireSocks: false,
    requireAuthentication: false,
    requireAnonymous: true,
  ),
);
```

### Parallel Proxy Validation

Pivox supports parallel proxy validation to speed up the validation process:

```dart
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

### Proxy Scoring and Weighted Selection

Pivox includes a sophisticated proxy scoring system that tracks proxy performance:

```dart
// Get a proxy manager with customized settings
final proxyManager = await Pivox.builder()
  .withMaxConcurrentValidations(15)
  .withAnalytics(true)
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

### Proxy Analytics

Pivox provides detailed analytics for proxy usage:

```dart
// Get analytics data
final analytics = await proxyManager.getAnalytics();

// Print analytics information
print('Total proxies fetched: ${analytics?.totalProxiesFetched}');
print('Total proxies validated: ${analytics?.totalProxiesValidated}');
print('Validation success rate: ${analytics?.totalSuccessfulValidations / analytics?.totalProxiesValidated}');
print('Average response time: ${analytics?.averageResponseTime} ms');
print('Average success rate: ${analytics?.averageSuccessRate}');

// Get proxies by country
analytics?.proxiesByCountry.forEach((country, count) {
  print('$country: $count proxies');
});

// Reset analytics if needed
await proxyManager.resetAnalytics();
```

### Proxy Source Configuration

Pivox allows you to configure which proxy sources to use:

```dart
// Use all sources (default)
final allSourcesConfig = ProxySourceConfig.all();

// Use no sources (add your own custom sources)
final noSourcesConfig = ProxySourceConfig.none();

// Use only specific sources
final customConfig = ProxySourceConfig.only(
  freeProxyList: true,
  geoNode: true,
  proxyScrape: false,
  proxyNova: false,
  custom: ['https://my-custom-proxy-source.com'],
);

// Use the configuration
final proxyManager = await Pivox.builder()
  .withProxySourceConfig(customConfig)
  .buildProxyManager();
```

## Web Scraping

Pivox provides advanced web scraping capabilities with robust features to handle challenging websites and avoid detection.

### Basic Web Scraping

```dart
// Create a web scraper
final webScraper = await Pivox.createWebScraper();

// Fetch HTML content
final html = await webScraper.fetchHtml(
  url: 'https://example.com',
);

// Extract data using CSS selectors
final titles = webScraper.extractData(
  html: html,
  selector: 'h1',
);

print('Extracted ${titles.length} titles:');
titles.forEach(print);
```

### Dynamic User Agent Management

Pivox includes a powerful `DynamicUserAgentManager` that provides realistic, up-to-date user agents to help avoid detection:

```dart
// Create a dynamic user agent manager
final userAgentManager = DynamicUserAgentManager();

// Get a random user agent
final userAgent = userAgentManager.getRandomUserAgent();

// Get a user agent for a specific browser type
final chromeAgent = userAgentManager.getUserAgentByType(BrowserType.chrome);
final mobileAgent = userAgentManager.getUserAgentByType(BrowserType.mobile);

// Get a user agent specifically for a problematic site
final siteSpecificAgent = userAgentManager.getRandomUserAgentForSite('https://difficult-site.com');

// Get a sequence of user agents to try for a problematic site
final userAgentSequence = userAgentManager.getUserAgentSequenceForProblematicSite('https://difficult-site.com');
```

### Specialized Site Handlers

Pivox includes specialized handlers for websites that are particularly difficult to scrape:

```dart
// Check if a site is known to be problematic
final isProblematic = webScraper.reputationTracker.isProblematicSite(url);

// Use specialized handler for problematic sites
if (isProblematic || url.contains('onlinekhabar.com') || url.contains('vegamovies')) {
  // Use specialized approach
  final html = await webScraper.fetchFromProblematicSite(
    url: url,
    timeout: 60000, // 60 seconds
    retries: 5,
  );
} else {
  // Use standard approach
  final html = await webScraper.fetchHtml(
    url: url,
  );
}
```

### Structured Data Extraction

Pivox can extract structured data from HTML content:

```dart
// Define selectors for structured data
final selectors = {
  'title': '.product-title',
  'price': '.product-price',
  'description': '.product-description',
  'image': '.product-image',
};

// Define attributes for certain elements
final attributes = {
  'image': 'src',
};

// Extract structured data
final products = webScraper.extractStructuredData(
  html: html,
  selectors: selectors,
  attributes: attributes,
);

print('Extracted ${products.length} products:');
products.forEach((product) {
  print('Title: ${product['title']}');
  print('Price: ${product['price']}');
});
```

### Advanced Web Scraping Features

Pivox provides additional advanced features for web scraping:

```dart
// Create an advanced web scraper
final advancedScraper = AdvancedWebScraper(
  proxyManager: proxyManager,
  rateLimiter: RateLimiter(defaultDelayMs: 1000),
  userAgentRotator: UserAgentRotator(),
  cookieManager: await CookieManager.create(),
);

// Scrape with rate limiting
await advancedScraper.scrapeWithRateLimit(
  url: 'https://example.com',
  delayMs: 2000, // 2 seconds between requests
);

// Scrape with cookies
final html = await advancedScraper.scrapeWithCookies(
  url: 'https://example.com/login',
  cookies: {
    'session': 'abc123',
    'user': 'example',
  },
);
```

For more detailed information about web scraping features, see the [Web Scraping Documentation](web_scraping.md).

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

  /// Sets the proxy source configuration
  PivoxBuilder withProxySourceConfig(ProxySourceConfig sourceConfig);

  /// Enables or disables analytics tracking
  PivoxBuilder withAnalytics(bool enableAnalytics);

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
  final String? region;
  final String? isp;
  final double? speed;
  final bool? supportsWebsockets;
  final bool? supportsSocks;
  final int? socksVersion;
  final String? username;
  final String? password;

  const Proxy({
    required this.ip,
    required this.port,
    this.countryCode,
    this.isHttps = false,
    this.anonymityLevel,
    this.region,
    this.isp,
    this.speed,
    this.supportsWebsockets,
    this.supportsSocks,
    this.socksVersion,
    this.username,
    this.password,
  });

  /// Returns true if this proxy requires authentication
  bool get isAuthenticated => username != null && password != null;
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
    super.region,
    super.isp,
    super.speed,
    super.supportsWebsockets,
    super.supportsSocks,
    super.socksVersion,
    super.username,
    super.password,
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
  final double uptime;
  final double stability;
  final int ageHours;
  final double geoDistanceScore;
  final int consecutiveSuccesses;
  final int consecutiveFailures;

  const ProxyScore({
    required this.successRate,
    required this.averageResponseTime,
    required this.successfulRequests,
    required this.failedRequests,
    required this.lastUsed,
    this.uptime = 1.0,
    this.stability = 1.0,
    this.ageHours = 0,
    this.geoDistanceScore = 0.5,
    this.consecutiveSuccesses = 0,
    this.consecutiveFailures = 0,
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

### ProxyFilterOptions

```dart
class ProxyFilterOptions {
  final int count;
  final bool onlyHttps;
  final List<String>? countries;
  final List<String>? regions;
  final List<String>? isps;
  final double? minSpeed;
  final bool? requireWebsockets;
  final bool? requireSocks;
  final int? socksVersion;
  final bool? requireAuthentication;
  final bool? requireAnonymous;

  const ProxyFilterOptions({
    this.count = 20,
    this.onlyHttps = false,
    this.countries,
    this.regions,
    this.isps,
    this.minSpeed,
    this.requireWebsockets,
    this.requireSocks,
    this.socksVersion,
    this.requireAuthentication,
    this.requireAnonymous,
  });
}
```

### ProxySourceConfig

```dart
class ProxySourceConfig {
  final bool useFreeProxyList;
  final bool useGeoNode;
  final bool useProxyScrape;
  final bool useProxyNova;
  final List<String> customSources;

  const ProxySourceConfig({
    this.useFreeProxyList = true,
    this.useGeoNode = true,
    this.useProxyScrape = true,
    this.useProxyNova = true,
    this.customSources = const [],
  });

  // Factory methods
  factory ProxySourceConfig.all();
  factory ProxySourceConfig.none();
  factory ProxySourceConfig.only({
    bool freeProxyList = false,
    bool geoNode = false,
    bool proxyScrape = false,
    bool proxyNova = false,
    List<String> custom = const [],
  });

  // Methods
  List<String> getEnabledSourceUrls();
  ProxySourceConfig copyWith({
    bool? useFreeProxyList,
    bool? useGeoNode,
    bool? useProxyScrape,
    bool? useProxyNova,
    List<String>? customSources,
  });
}
```

### ProxyAnalytics

```dart
class ProxyAnalytics {
  final int totalProxiesFetched;
  final int totalProxiesValidated;
  final int totalSuccessfulValidations;
  final int totalFailedValidations;
  final int totalRequests;
  final int totalSuccessfulRequests;
  final int totalFailedRequests;
  final int averageResponseTime;
  final double averageSuccessRate;
  final Map<String, int> proxiesByCountry;
  final Map<String, int> proxiesByAnonymityLevel;
  final Map<String, int> requestsByProxySource;

  const ProxyAnalytics({
    this.totalProxiesFetched = 0,
    this.totalProxiesValidated = 0,
    this.totalSuccessfulValidations = 0,
    this.totalFailedValidations = 0,
    this.totalRequests = 0,
    this.totalSuccessfulRequests = 0,
    this.totalFailedRequests = 0,
    this.averageResponseTime = 0,
    this.averageSuccessRate = 0.0,
    this.proxiesByCountry = const {},
    this.proxiesByAnonymityLevel = const {},
    this.requestsByProxySource = const {},
  });

  // Methods
  ProxyAnalytics recordProxyFetch(List<Proxy> proxies);
  ProxyAnalytics recordProxyValidation(List<Proxy> proxies, List<bool> results);
  ProxyAnalytics recordRequest(Proxy proxy, bool success, int? responseTime, String source);
  factory ProxyAnalytics.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### ProxyManager

```dart
class ProxyManager {
  final GetProxies getProxies;
  final ValidateProxy validateProxy;
  final GetValidatedProxies getValidatedProxies;
  final ProxyAnalyticsService? analyticsService;

  ProxyManager({
    required this.getProxies,
    required this.validateProxy,
    required this.getValidatedProxies,
    this.analyticsService,
  });

  // Methods
  Future<List<Proxy>> fetchProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(),
  });

  @Deprecated('Use fetchProxies with ProxyFilterOptions instead')
  Future<List<Proxy>> fetchProxiesLegacy({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  });

  Future<List<Proxy>> fetchValidatedProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(count: 10),
    void Function(int completed, int total)? onProgress,
  });

  @Deprecated('Use fetchValidatedProxies with ProxyFilterOptions instead')
  Future<List<Proxy>> fetchValidatedProxiesLegacy({
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

  Future<ProxyAnalytics?> getAnalytics();

  Future<void> resetAnalytics();

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
