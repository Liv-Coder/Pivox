import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/utils/logger.dart';

/// Types of lazy loading
enum LazyLoadType {
  /// Image lazy loading
  image,

  /// Iframe lazy loading
  iframe,

  /// JavaScript-based lazy loading
  javascript,

  /// Infinite scroll lazy loading
  infiniteScroll,

  /// Button-triggered lazy loading
  buttonTriggered,

  /// Unknown lazy loading type
  unknown,
}

/// Result of lazy loading detection
class LazyLoadDetectionResult {
  /// The type of lazy loading
  final LazyLoadType type;

  /// The lazy loaded elements
  final List<Element> lazyElements;

  /// The trigger elements (e.g., buttons)
  final List<Element> triggerElements;

  /// Whether JavaScript is required for lazy loading
  final bool requiresJavaScript;

  /// Whether scrolling is required for lazy loading
  final bool requiresScrolling;

  /// Whether interaction is required for lazy loading
  final bool requiresInteraction;

  /// Creates a new [LazyLoadDetectionResult]
  LazyLoadDetectionResult({
    required this.type,
    this.lazyElements = const [],
    this.triggerElements = const [],
    this.requiresJavaScript = false,
    this.requiresScrolling = false,
    this.requiresInteraction = false,
  });

  /// Creates an empty [LazyLoadDetectionResult]
  factory LazyLoadDetectionResult.empty() {
    return LazyLoadDetectionResult(
      type: LazyLoadType.unknown,
    );
  }

  /// Whether lazy loading was detected
  bool get hasLazyLoading => 
      lazyElements.isNotEmpty || 
      triggerElements.isNotEmpty || 
      requiresJavaScript || 
      requiresScrolling || 
      requiresInteraction;
}

/// A class for detecting lazy loading on webpages
class LazyLoadDetector {
  /// Logger for logging operations
  final Logger? logger;

  /// Creates a new [LazyLoadDetector]
  LazyLoadDetector({this.logger});

  /// Detects lazy loading in HTML
  LazyLoadDetectionResult detectLazyLoading(String html) {
    try {
      final document = html_parser.parse(html);
      
      // Try different lazy loading detection methods
      final imageLazyLoadResult = _detectImageLazyLoading(document);
      if (imageLazyLoadResult.hasLazyLoading) {
        logger?.info('Detected image lazy loading');
        return imageLazyLoadResult;
      }

      final iframeLazyLoadResult = _detectIframeLazyLoading(document);
      if (iframeLazyLoadResult.hasLazyLoading) {
        logger?.info('Detected iframe lazy loading');
        return iframeLazyLoadResult;
      }

      final jsLazyLoadResult = _detectJavaScriptLazyLoading(document);
      if (jsLazyLoadResult.hasLazyLoading) {
        logger?.info('Detected JavaScript-based lazy loading');
        return jsLazyLoadResult;
      }

      final infiniteScrollResult = _detectInfiniteScrollLazyLoading(document);
      if (infiniteScrollResult.hasLazyLoading) {
        logger?.info('Detected infinite scroll lazy loading');
        return infiniteScrollResult;
      }

      final buttonTriggeredResult = _detectButtonTriggeredLazyLoading(document);
      if (buttonTriggeredResult.hasLazyLoading) {
        logger?.info('Detected button-triggered lazy loading');
        return buttonTriggeredResult;
      }

      logger?.info('No lazy loading detected');
      return LazyLoadDetectionResult.empty();
    } catch (e) {
      logger?.error('Error detecting lazy loading: $e');
      return LazyLoadDetectionResult.empty();
    }
  }

  /// Detects image lazy loading
  LazyLoadDetectionResult _detectImageLazyLoading(Document document) {
    final lazyElements = <Element>[];
    
    // Check for native lazy loading
    final nativeLazyImages = document.querySelectorAll('img[loading="lazy"]');
    lazyElements.addAll(nativeLazyImages);
    
    // Check for common lazy loading libraries
    final dataLazyImages = document.querySelectorAll(
      'img[data-src], img[data-lazy-src], img[data-lazy], img[data-original], '
      'img[data-srcset], img[data-lazy-srcset], img[data-original-set], '
      'img.lazy, img.lazyload, img.lazyloaded',
    );
    lazyElements.addAll(dataLazyImages);
    
    // Check for images with placeholder src
    final placeholderImages = document.querySelectorAll('img[src]');
    for (final img in placeholderImages) {
      final src = img.attributes['src'] ?? '';
      if (src.contains('placeholder') || 
          src.contains('blank.') || 
          src.contains('transparent.') || 
          src.contains('grey.') || 
          src.contains('gray.') || 
          src.contains('loading.') || 
          src.endsWith('.svg') || 
          src.startsWith('data:image/')) {
        // Check if it has a data attribute for the real image
        if (img.attributes.containsKey('data-src') || 
            img.attributes.containsKey('data-lazy-src') || 
            img.attributes.containsKey('data-original')) {
          lazyElements.add(img);
        }
      }
    }
    
    // Check for JavaScript-based lazy loading
    bool requiresJavaScript = false;
    final scriptElements = document.querySelectorAll('script');
    for (final script in scriptElements) {
      final scriptText = script.text.toLowerCase();
      if (scriptText.contains('lazy load') || 
          scriptText.contains('lazyload') || 
          scriptText.contains('lazy-load') || 
          scriptText.contains('lazysizes') || 
          scriptText.contains('lozad') || 
          scriptText.contains('unveil') || 
          scriptText.contains('echo.js') || 
          scriptText.contains('lazy image')) {
        requiresJavaScript = true;
        break;
      }
    }
    
    return LazyLoadDetectionResult(
      type: LazyLoadType.image,
      lazyElements: lazyElements,
      requiresJavaScript: requiresJavaScript,
      requiresScrolling: requiresJavaScript || lazyElements.isNotEmpty,
    );
  }

  /// Detects iframe lazy loading
  LazyLoadDetectionResult _detectIframeLazyLoading(Document document) {
    final lazyElements = <Element>[];
    
    // Check for native lazy loading
    final nativeLazyIframes = document.querySelectorAll('iframe[loading="lazy"]');
    lazyElements.addAll(nativeLazyIframes);
    
    // Check for common lazy loading libraries
    final dataLazyIframes = document.querySelectorAll(
      'iframe[data-src], iframe[data-lazy-src], iframe[data-lazy], '
      'iframe.lazy, iframe.lazyload, iframe.lazyloaded',
    );
    lazyElements.addAll(dataLazyIframes);
    
    // Check for iframes with placeholder src
    final placeholderIframes = document.querySelectorAll('iframe[src]');
    for (final iframe in placeholderIframes) {
      final src = iframe.attributes['src'] ?? '';
      if (src.contains('about:blank') || src == '#' || src.isEmpty) {
        // Check if it has a data attribute for the real iframe
        if (iframe.attributes.containsKey('data-src') || 
            iframe.attributes.containsKey('data-lazy-src')) {
          lazyElements.add(iframe);
        }
      }
    }
    
    return LazyLoadDetectionResult(
      type: LazyLoadType.iframe,
      lazyElements: lazyElements,
      requiresJavaScript: lazyElements.isNotEmpty,
      requiresScrolling: lazyElements.isNotEmpty,
    );
  }

  /// Detects JavaScript-based lazy loading
  LazyLoadDetectionResult _detectJavaScriptLazyLoading(Document document) {
    bool requiresJavaScript = false;
    
    // Check for common lazy loading libraries in script tags
    final scriptElements = document.querySelectorAll('script');
    for (final script in scriptElements) {
      final scriptText = script.text.toLowerCase();
      final scriptSrc = script.attributes['src'] ?? '';
      
      if (scriptText.contains('lazy load') || 
          scriptText.contains('lazyload') || 
          scriptText.contains('lazy-load') || 
          scriptText.contains('lazysizes') || 
          scriptText.contains('lozad') || 
          scriptText.contains('unveil') || 
          scriptText.contains('echo.js') || 
          scriptText.contains('lazy image') ||
          scriptSrc.contains('lazy') || 
          scriptSrc.contains('lazysizes') || 
          scriptSrc.contains('lozad') || 
          scriptSrc.contains('unveil') || 
          scriptSrc.contains('echo.js')) {
        requiresJavaScript = true;
        break;
      }
    }
    
    // Check for elements with lazy loading classes or data attributes
    final lazyElements = document.querySelectorAll(
      '[data-lazy], [data-lazy-load], [data-lazyload], '
      '.lazy, .lazyload, .lazy-load, .lazyfade, .b-lazy',
    );
    
    return LazyLoadDetectionResult(
      type: LazyLoadType.javascript,
      lazyElements: lazyElements.toList(),
      requiresJavaScript: requiresJavaScript || lazyElements.isNotEmpty,
      requiresScrolling: true,
    );
  }

  /// Detects infinite scroll lazy loading
  LazyLoadDetectionResult _detectInfiniteScrollLazyLoading(Document document) {
    bool requiresJavaScript = false;
    
    // Check for common infinite scroll libraries in script tags
    final scriptElements = document.querySelectorAll('script');
    for (final script in scriptElements) {
      final scriptText = script.text.toLowerCase();
      final scriptSrc = script.attributes['src'] ?? '';
      
      if (scriptText.contains('infinite scroll') || 
          scriptText.contains('infinitescroll') || 
          scriptText.contains('endless scroll') || 
          scriptSrc.contains('infinite') || 
          scriptSrc.contains('infinitescroll') || 
          scriptSrc.contains('endless')) {
        requiresJavaScript = true;
        break;
      }
    }
    
    // Check for elements with infinite scroll classes or data attributes
    final infiniteScrollElements = document.querySelectorAll(
      '[data-infinite-scroll], [data-infinite], [data-endless-scroll], '
      '.infinite-scroll, .infinitescroll, .endless-scroll',
    );
    
    return LazyLoadDetectionResult(
      type: LazyLoadType.infiniteScroll,
      lazyElements: infiniteScrollElements.toList(),
      requiresJavaScript: requiresJavaScript || infiniteScrollElements.isNotEmpty,
      requiresScrolling: true,
    );
  }

  /// Detects button-triggered lazy loading
  LazyLoadDetectionResult _detectButtonTriggeredLazyLoading(Document document) {
    final triggerElements = <Element>[];
    
    // Look for "load more" buttons
    final loadMoreSelectors = [
      'a:contains("Load More")',
      'a:contains("load more")',
      'a:contains("Show More")',
      'a:contains("show more")',
      'a:contains("View More")',
      'a:contains("view more")',
      'button:contains("Load More")',
      'button:contains("load more")',
      'button:contains("Show More")',
      'button:contains("show more")',
      'button:contains("View More")',
      'button:contains("view more")',
      '.load-more',
      '.loadmore',
      '.show-more',
      '.showmore',
      '.view-more',
      '.viewmore',
    ];

    for (final selector in loadMoreSelectors) {
      try {
        final elements = document.querySelectorAll(selector);
        triggerElements.addAll(elements);
      } catch (e) {
        // Some selectors might not be supported by the parser
        continue;
      }
    }
    
    return LazyLoadDetectionResult(
      type: LazyLoadType.buttonTriggered,
      triggerElements: triggerElements,
      requiresJavaScript: triggerElements.isNotEmpty,
      requiresInteraction: triggerElements.isNotEmpty,
    );
  }
}
