# Headless Browser Integration

Pivox now includes powerful headless browser capabilities for advanced web scraping, enabling you to handle complex websites that rely on JavaScript, dynamic content loading, and other modern web technologies.

## Overview

The headless browser integration in Pivox uses the `flutter_inappwebview` package to provide a full browser environment that can:

- Execute JavaScript
- Handle dynamic content loading
- Interact with forms and buttons
- Manage cookies and sessions
- Take screenshots
- Work with complex single-page applications

This feature is particularly useful for scraping websites that:

- Require JavaScript to display content
- Use lazy loading or infinite scrolling
- Implement anti-scraping measures
- Require user interaction (clicking, form submission)
- Use modern web frameworks (React, Angular, Vue, etc.)

## Getting Started

### Basic Usage

```dart
import 'package:pivox/pivox.dart';

// Create a headless browser service with default settings
final browserService = await Pivox.createHeadlessBrowserService();

// Scrape a URL that requires JavaScript
final result = await browserService.scrapeUrl(
  'https://example.com',
  selectors: {
    'title': 'h1',
    'description': '.description',
    'items': '.item',
  },
);

if (result.success) {
  print('Title: ${result.data?['title']}');
  print('Description: ${result.data?['description']}');
  print('Items: ${result.data?['items']}');
  
  // You can also access the full HTML
  print('HTML length: ${result.html?.length}');
} else {
  print('Error: ${result.errorMessage}');
}

// Don't forget to dispose when done
await browserService.dispose();
```

### Using Specialized Handlers

For websites with specific challenges, you can use specialized handlers:

```dart
import 'package:pivox/pivox.dart';

// Create specialized handlers for problematic sites
final handlers = await Pivox.createSpecializedHeadlessHandlers();

// Handle a site with lazy loading
final result = await handlers.handleLazyLoadingSite(
  'https://example.com/lazy-loading-page',
  selectors: {
    'products': '.product-card',
    'prices': '.price',
  },
  scrollCount: 5,  // Scroll 5 times to load more content
  scrollDelay: 1000,  // Wait 1 second between scrolls
);

if (result.success) {
  final products = result.data?['products'] as List<dynamic>?;
  print('Found ${products?.length} products');
}

// Handle a site that requires clicking elements
final clickResult = await handlers.handleClickInteractionSite(
  'https://example.com/click-to-load',
  clickSelector: '.load-more-button',
  maxClicks: 3,  // Click the button 3 times
  selectors: {
    'items': '.item',
  },
);

// Don't forget to dispose when done
await handlers.dispose();
```

### Advanced Configuration

You can customize the headless browser behavior using the builder pattern:

```dart
import 'package:pivox/pivox.dart';

// Create a custom configuration
final config = HeadlessBrowserConfig(
  userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  javaScriptEnabled: true,
  domStorageEnabled: true,
  blockImages: true,  // Block images for faster loading
  timeoutMillis: 60000,  // 60 second timeout
  clearCookies: true,  // Clear cookies before each request
  loggingEnabled: true,  // Enable logging
);

// Use the builder pattern for more control
final browserService = await Pivox.builder()
  .withHeadlessBrowserConfig(config)
  .withMaxRetries(5)
  .withRotateProxies(true)
  .buildHeadlessBrowserService();

// Use the service as needed
final result = await browserService.scrapeUrl('https://example.com');

// Don't forget to dispose when done
await browserService.dispose();
```

## Specialized Handlers

Pivox includes several specialized handlers for common web scraping challenges:

### JavaScript Sites

For sites that require JavaScript to display content:

```dart
final result = await handlers.handleJavaScriptSite(
  'https://example.com/js-heavy-site',
  selectors: {
    'data': '.dynamic-content',
  },
);
```

### Lazy Loading Sites

For sites that load content as you scroll:

```dart
final result = await handlers.handleLazyLoadingSite(
  'https://example.com/lazy-loading',
  selectors: {
    'items': '.item',
  },
  scrollCount: 5,  // Scroll 5 times
  scrollDelay: 1000,  // Wait 1 second between scrolls
);
```

### Infinite Scrolling Sites

For sites with infinite scrolling:

```dart
final result = await handlers.handleInfiniteScrollingSite(
  'https://example.com/infinite-scroll',
  selectors: {
    'posts': '.post',
    'authors': '.author',
  },
  maxScrolls: 10,  // Scroll up to 10 times
  itemSelector: '.post',  // Used to detect when new items are loaded
);
```

### Click Interaction Sites

For sites that require clicking elements:

```dart
final result = await handlers.handleClickInteractionSite(
  'https://example.com/click-to-load',
  clickSelector: '.load-more-button',
  maxClicks: 3,  // Click the button 3 times
  selectors: {
    'items': '.item',
  },
);
```

### Form Submission Sites

For sites that require form submission:

```dart
final result = await handlers.handleFormSubmissionSite(
  'https://example.com/search',
  formData: {
    'query': 'example search',
    'category': 'all',
  },
  formSelector: '#search-form',
  submitSelector: '#submit-button',
  selectors: {
    'results': '.search-result',
  },
  waitAfterSubmit: 3000,  // Wait 3 seconds after submission
);
```

## Integration with Proxy System

The headless browser integration works seamlessly with Pivox's proxy system:

```dart
import 'package:pivox/pivox.dart';

// Create a proxy manager
final proxyManager = await Pivox.createProxyManager();

// Create a headless browser service with proxy support
final browserService = await HeadlessBrowserFactory.createService(
  proxyManager: proxyManager,
  useProxies: true,
  rotateProxies: true,
);

// The service will automatically use and rotate proxies
final result = await browserService.scrapeUrl('https://example.com');
```

## Performance Considerations

Headless browser scraping is more resource-intensive than regular HTTP requests. Consider the following tips:

1. Use `HeadlessBrowserConfig.performance()` for performance-optimized settings
2. Enable `blockImages` to reduce bandwidth and improve speed
3. Set appropriate timeouts based on your needs
4. Dispose of the browser when done to free resources
5. Use regular HTTP requests for simple pages that don't require JavaScript

## Error Handling

The headless browser integration includes robust error handling:

```dart
try {
  final result = await browserService.scrapeUrl('https://example.com');
  
  if (result.success) {
    // Process successful result
    print('Data: ${result.data}');
  } else {
    // Handle error
    print('Error: ${result.errorMessage}');
    print('Status code: ${result.statusCode}');
  }
} catch (e) {
  // Handle unexpected errors
  print('Exception: $e');
}
```

## Limitations

While the headless browser integration is powerful, it has some limitations:

1. Android uses system proxy settings, which may require additional configuration
2. iOS has limited proxy support in WebView
3. Headless browsing uses more resources than regular HTTP requests
4. Some websites may detect and block headless browsers

## Best Practices

1. Use the appropriate handler for each type of website
2. Set reasonable timeouts to avoid hanging
3. Implement rate limiting to avoid overloading websites
4. Respect robots.txt and website terms of service
5. Add delays between requests to mimic human behavior
6. Use the stealth configuration for sensitive websites
7. Implement proper error handling and retries

## Conclusion

The headless browser integration in Pivox provides powerful capabilities for scraping complex websites. By combining it with Pivox's proxy rotation and other web scraping features, you can build robust and reliable web scraping solutions for even the most challenging websites.
