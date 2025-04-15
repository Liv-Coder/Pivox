# Pivox Web Scraping

Pivox provides advanced web scraping capabilities with robust features to handle challenging websites and avoid detection. This document covers the key components and techniques used in Pivox's web scraping functionality.

## Table of Contents

1. [Overview](#overview)
2. [Key Components](#key-components)
3. [Dynamic User Agent Management](#dynamic-user-agent-management)
4. [Specialized Site Handlers](#specialized-site-handlers)
5. [Advanced Techniques](#advanced-techniques)
6. [Usage Examples](#usage-examples)
7. [Troubleshooting](#troubleshooting)

## Overview

Web scraping can be challenging due to anti-scraping measures implemented by websites. Pivox addresses these challenges with a comprehensive set of tools and techniques:

- **Dynamic User Agent Rotation**: Automatically rotate through modern, realistic user agents
- **Specialized Site Handlers**: Custom handlers for problematic websites
- **Proxy Rotation**: Integrate with Pivox's proxy rotation capabilities
- **Adaptive Scraping Strategies**: Adjust scraping behavior based on site reputation
- **Error Handling**: Robust error handling with detailed logging
- **Rate Limiting**: Respect website rate limits to avoid blocking

## Key Components

### WebScraper

The core `WebScraper` class provides basic scraping functionality:

```dart
final webScraper = WebScraper(
  proxyManager: proxyManager,
  defaultTimeout: 30000,
  maxRetries: 3,
);

// Fetch HTML content
final html = await webScraper.fetchHtml(
  url: 'https://example.com',
);

// Extract data using CSS selectors
final titles = webScraper.extractData(
  html: html,
  selector: 'h1',
);
```

### WebScraperExtension

The `WebScraperExtension` adds enhanced capabilities to the `WebScraper`:

```dart
// Handle problematic sites with specialized techniques
final html = await webScraper.fetchFromProblematicSite(
  url: 'https://difficult-site.com',
  timeout: 60000,
  retries: 5,
);
```

### AdvancedWebScraper

The `AdvancedWebScraper` provides additional features like rate limiting and cookie management:

```dart
final advancedScraper = AdvancedWebScraper(
  proxyManager: proxyManager,
  rateLimiter: RateLimiter(defaultDelayMs: 1000),
  userAgentRotator: UserAgentRotator(),
  cookieManager: await CookieManager.create(),
);
```

## Dynamic User Agent Management

The `DynamicUserAgentManager` is a powerful component that provides realistic, up-to-date user agents to help avoid detection.

### Features

- **Latest User Agents**: Includes the most recent browser versions
- **Dynamic Fetching**: Can fetch user agents from online sources
- **Browser-Specific Agents**: Get user agents for specific browsers
- **Site-Specific Agents**: Special user agents for problematic sites
- **User Agent Sequences**: Generate sequences of user agents to try

### Usage

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

### Browser Types

The `BrowserType` enum provides the following options:

- `BrowserType.chrome`: Chrome browser
- `BrowserType.firefox`: Firefox browser
- `BrowserType.safari`: Safari browser
- `BrowserType.edge`: Edge browser
- `BrowserType.opera`: Opera browser
- `BrowserType.mobile`: Mobile browsers (Android, iOS)

### Online User Agent Fetching

The `DynamicUserAgentManager` can fetch user agents from online sources:

```dart
// Initialize the manager (this will fetch user agents from the web)
await userAgentManager.initialize();
```

## Specialized Site Handlers

Pivox includes specialized handlers for websites that are particularly difficult to scrape. These handlers implement custom approaches tailored to specific sites.

### SpecializedSiteHandler

The `SpecializedSiteHandler` interface defines the contract for site-specific handlers:

```dart
abstract class SpecializedSiteHandler {
  /// Checks if this handler can handle the given URL
  bool canHandle(String url);

  /// Fetches HTML content from the given URL
  Future<String> fetchHtml({
    required String url,
    required Map<String, String> headers,
    required int timeout,
    required ScrapingLogger logger,
  });
}
```

### SpecializedSiteHandlerRegistry

The `SpecializedSiteHandlerRegistry` manages the available specialized handlers:

```dart
// Get a handler for a specific URL
final handler = registry.getHandlerForUrl('https://difficult-site.com');

// Check if a handler is available for a URL
final hasHandler = registry.hasHandlerForUrl('https://difficult-site.com');

// Register a custom handler
registry.registerHandler(MyCustomSiteHandler());
```

### Built-in Specialized Handlers

Pivox includes specialized handlers for the following sites:

1. **OnlineKhabarHandler**: Handles onlinekhabar.com with multiple approaches:

   - Tries multiple user agents
   - Uses both HttpClient and http package
   - Handles URL format issues (port 443)

2. **VegaMoviesHandler**: Handles vegamovies sites with:
   - Multiple user agents
   - Alternative domain extensions (.tv, .td, .nl, .lol)
   - Custom HTTP client configuration

### Creating Custom Handlers

You can create custom handlers for specific sites:

```dart
class MyCustomSiteHandler implements SpecializedSiteHandler {
  @override
  bool canHandle(String url) {
    return url.contains('example.com');
  }

  @override
  Future<String> fetchHtml({
    required String url,
    required Map<String, String> headers,
    required int timeout,
    required ScrapingLogger logger,
  }) async {
    // Custom implementation for this site
    // ...
  }
}
```

## Advanced Techniques

### Multiple Approach Strategy

For problematic sites, Pivox tries multiple approaches in sequence:

1. **Standard Approach**: First try with standard HTTP request
2. **User Agent Rotation**: Try with different user agents
3. **HTTP Client Variation**: Try with different HTTP clients (http package, HttpClient)
4. **URL Modification**: Try with modified URLs (e.g., removing port numbers)
5. **Domain Variation**: Try with alternative domain extensions

### Adaptive Scraping

The `AdaptiveScrapingStrategy` adjusts scraping behavior based on site reputation:

```dart
// Get the optimal strategy for a URL
final strategy = adaptiveStrategy.getStrategyForUrl(url);

// Record success or failure
adaptiveStrategy.recordSuccess(url);
adaptiveStrategy.recordFailure(url, errorMessage);
```

### Logging

The `ScrapingLogger` provides detailed logging for debugging:

```dart
// Create a logger
final logger = ScrapingLogger();

// Log different types of messages
logger.info('Starting to scrape...');
logger.warning('Site may have anti-scraping measures');
logger.error('Failed to scrape: $error');
logger.success('Successfully scraped data');
```

## Usage Examples

### Basic Scraping

```dart
import 'package:pivox/pivox.dart';

Future<void> main() async {
  // Create a proxy manager
  final proxyManager = await Pivox.createProxyManager();

  // Create a web scraper
  final webScraper = WebScraper(
    proxyManager: proxyManager,
    defaultTimeout: 30000,
    maxRetries: 3,
  );

  try {
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
  } catch (e) {
    print('Error: $e');
  } finally {
    webScraper.close();
  }
}
```

### Handling Problematic Sites

```dart
import 'package:pivox/pivox.dart';

Future<void> main() async {
  // Create a proxy manager
  final proxyManager = await Pivox.createProxyManager();

  // Create a web scraper
  final webScraper = WebScraper(
    proxyManager: proxyManager,
    defaultTimeout: 60000,
    maxRetries: 5,
  );

  try {
    // Check if the site is known to be problematic
    final url = 'https://difficult-site.com';
    final isProblematic = webScraper.reputationTracker.isProblematicSite(url);

    String html;
    if (isProblematic) {
      // Use specialized approach for problematic sites
      html = await webScraper.fetchFromProblematicSite(
        url: url,
        timeout: 60000,
        retries: 5,
      );
    } else {
      // Use standard approach
      html = await webScraper.fetchHtml(
        url: url,
      );
    }

    // Extract data
    final data = webScraper.extractData(
      html: html,
      selector: '.content',
    );

    print('Successfully scraped data');
  } catch (e) {
    print('Error: $e');
  } finally {
    webScraper.close();
  }
}
```

### Structured Data Extraction

```dart
import 'package:pivox/pivox.dart';

Future<void> main() async {
  // Create a web scraper
  final webScraper = await Pivox.createWebScraper();

  try {
    // Fetch HTML content
    final html = await webScraper.fetchHtml(
      url: 'https://example.com/products',
    );

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
      print('Description: ${product['description']}');
      print('Image URL: ${product['image']}');
      print('---');
    });
  } catch (e) {
    print('Error: $e');
  } finally {
    webScraper.close();
  }
}
```

## Troubleshooting

### Common Issues

1. **Connection Errors**:

   - Try using a different proxy
   - Increase the timeout value
   - Check if the URL is correct and accessible

2. **Empty Results**:

   - Verify that the CSS selectors are correct
   - Check if the website requires JavaScript
   - Try with a different user agent

3. **Blocked Requests**:
   - Use a different proxy
   - Rotate user agents
   - Add a delay between requests
   - Try with a specialized site handler

### Debugging

Enable detailed logging to debug scraping issues:

```dart
final logger = ScrapingLogger();
final webScraper = WebScraper(
  proxyManager: proxyManager,
  logger: logger,
);

// Listen for log entries
logger.onLog.listen((entry) {
  print('${entry.timestamp}: [${entry.type}] ${entry.message}');
});
```

### Site-Specific Tips

#### onlinekhabar.com

- Try removing the port number (:443) from the URL
- Use a proxy from a different region
- Try with a mobile user agent
- The site may have rate limiting - wait and try again

#### vegamovies

- Try with a different domain extension (.td, .nl, etc.)
- The site may require specific headers
- Try with a longer timeout (120+ seconds)
