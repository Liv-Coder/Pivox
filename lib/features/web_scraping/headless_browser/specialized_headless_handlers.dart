import 'dart:async';

import 'package:pivox/features/web_scraping/headless_browser/headless_browser_config.dart';
import 'package:pivox/features/web_scraping/headless_browser/headless_browser_result.dart';
import 'package:pivox/features/web_scraping/headless_browser/headless_browser_service.dart';
import 'package:pivox/features/web_scraping/scraping_logger.dart';

/// Specialized handlers for problematic sites using headless browser
class SpecializedHeadlessHandlers {
  /// The headless browser service
  final HeadlessBrowserService _service;

  /// The scraping logger
  final ScrapingLogger _logger;

  /// Creates a new [SpecializedHeadlessHandlers] instance
  SpecializedHeadlessHandlers({
    HeadlessBrowserService? service,
    ScrapingLogger? logger,
  }) : _service =
           service ??
           HeadlessBrowserService(config: HeadlessBrowserConfig.stealth()),
       _logger = logger ?? ScrapingLogger();

  /// Initializes the handlers
  Future<void> initialize() async {
    await _service.initialize();
  }

  /// Handles a site that requires JavaScript
  Future<HeadlessBrowserResult> handleJavaScriptSite(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? selectors,
    Map<String, String>? attributes,
    int? timeoutMillis,
  }) async {
    _logger.info('Handling JavaScript site: $url');

    return await _service.scrapeUrl(
      url,
      headers: headers,
      selectors: selectors,
      attributes: attributes,
      timeoutMillis: timeoutMillis,
    );
  }

  /// Handles a site that uses lazy loading
  Future<HeadlessBrowserResult> handleLazyLoadingSite(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? selectors,
    Map<String, String>? attributes,
    int? timeoutMillis,
    int scrollCount = 5,
    int scrollDelay = 1000,
  }) async {
    _logger.info('Handling lazy loading site: $url');

    final result = await _service.scrapeUrl(
      url,
      headers: headers,
      timeoutMillis: timeoutMillis,
    );

    if (!result.success) {
      return result;
    }

    // Scroll down to trigger lazy loading
    for (int i = 0; i < scrollCount; i++) {
      await _service.executeScript('''
        window.scrollTo({
          top: document.body.scrollHeight * ${(i + 1) / scrollCount},
          behavior: 'smooth'
        });
      ''');

      await Future.delayed(Duration(milliseconds: scrollDelay));
    }

    // Scroll back to top
    await _service.executeScript('window.scrollTo(0, 0);');

    // Extract data if selectors provided
    Map<String, dynamic>? extractedData;
    if (selectors != null && selectors.isNotEmpty) {
      extractedData = await _service.executeScript('''
        (function() {
          const result = {};
          ${selectors.entries.map((entry) {
        final key = entry.key;
        final selector = entry.value;
        final attribute = attributes?[key];

        if (attribute != null) {
          return '''
                result["$key"] = Array.from(document.querySelectorAll('$selector'))
                  .map(el => el.getAttribute('$attribute'))
                  .filter(val => val !== null);
              ''';
        } else {
          return '''
                result["$key"] = Array.from(document.querySelectorAll('$selector'))
                  .map(el => el.textContent.trim())
                  .filter(val => val !== "");
              ''';
        }
      }).join('\n')}
          return result;
        })();
      ''');
    }

    // Get updated HTML
    final html = await _service.executeScript(
      'document.documentElement.outerHTML',
    );

    return HeadlessBrowserResult.success(
      html: html,
      data: extractedData,
      elapsedMillis: result.elapsedMillis,
    );
  }

  /// Handles a site that uses infinite scrolling
  Future<HeadlessBrowserResult> handleInfiniteScrollingSite(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? selectors,
    Map<String, String>? attributes,
    int? timeoutMillis,
    int maxScrolls = 10,
    int scrollDelay = 1000,
    String? itemSelector,
  }) async {
    _logger.info('Handling infinite scrolling site: $url');

    final result = await _service.scrapeUrl(
      url,
      headers: headers,
      timeoutMillis: timeoutMillis,
    );

    if (!result.success) {
      return result;
    }

    // Get initial item count
    int initialItemCount = 0;
    if (itemSelector != null) {
      final countResult = await _service.executeScript(
        "document.querySelectorAll('$itemSelector').length",
      );
      initialItemCount = countResult is int ? countResult : 0;
    }

    // Scroll down to trigger infinite loading
    int currentItemCount = initialItemCount;
    int unchangedScrolls = 0;

    for (int i = 0; i < maxScrolls; i++) {
      await _service.executeScript(
        'window.scrollTo(0, document.body.scrollHeight);',
      );
      await Future.delayed(Duration(milliseconds: scrollDelay));

      // Check if new items were loaded
      if (itemSelector != null) {
        final newCountResult = await _service.executeScript(
          "document.querySelectorAll('$itemSelector').length",
        );
        final newCount = newCountResult is int ? newCountResult : 0;

        if (newCount > currentItemCount) {
          _logger.info('Loaded more items: $newCount (was $currentItemCount)');
          currentItemCount = newCount;
          unchangedScrolls = 0;
        } else {
          unchangedScrolls++;
          if (unchangedScrolls >= 3) {
            _logger.info('No new items after 3 scrolls, stopping');
            break;
          }
        }
      }
    }

    // Extract data if selectors provided
    Map<String, dynamic>? extractedData;
    if (selectors != null && selectors.isNotEmpty) {
      extractedData = await _service.executeScript('''
        (function() {
          const result = {};
          ${selectors.entries.map((entry) {
        final key = entry.key;
        final selector = entry.value;
        final attribute = attributes?[key];

        if (attribute != null) {
          return '''
                result["$key"] = Array.from(document.querySelectorAll('$selector'))
                  .map(el => el.getAttribute('$attribute'))
                  .filter(val => val !== null);
              ''';
        } else {
          return '''
                result["$key"] = Array.from(document.querySelectorAll('$selector'))
                  .map(el => el.textContent.trim())
                  .filter(val => val !== "");
              ''';
        }
      }).join('\n')}
          return result;
        })();
      ''');
    }

    // Get updated HTML
    final html = await _service.executeScript(
      'document.documentElement.outerHTML',
    );

    if (itemSelector != null) {
      _logger.info(
        'Total items loaded: $currentItemCount (initial: $initialItemCount)',
      );
    }

    return HeadlessBrowserResult.success(
      html: html,
      data: extractedData,
      elapsedMillis: result.elapsedMillis,
    );
  }

  /// Handles a site that requires clicking elements
  Future<HeadlessBrowserResult> handleClickInteractionSite(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? selectors,
    Map<String, String>? attributes,
    int? timeoutMillis,
    String? clickSelector,
    int clickDelay = 1000,
    int maxClicks = 1,
  }) async {
    _logger.info('Handling click interaction site: $url');

    final result = await _service.scrapeUrl(
      url,
      headers: headers,
      timeoutMillis: timeoutMillis,
    );

    if (!result.success || clickSelector == null) {
      return result;
    }

    // Wait for the element to be present
    final elementPresent = await _service.waitForElement(clickSelector);
    if (!elementPresent) {
      _logger.error('Click selector not found: $clickSelector');
      return HeadlessBrowserResult.failure(
        errorMessage: 'Click selector not found: $clickSelector',
        elapsedMillis: result.elapsedMillis,
      );
    }

    // Click the element
    for (int i = 0; i < maxClicks; i++) {
      final clickResult = await _service.executeScript('''
        (function() {
          const elements = document.querySelectorAll('$clickSelector');
          if (elements.length === 0) return false;

          const element = elements[$i];
          element.click();
          return true;
        })();
      ''');

      if (clickResult != true) {
        _logger.error('Failed to click element: $clickSelector');
        break;
      }

      await Future.delayed(Duration(milliseconds: clickDelay));
    }

    // Extract data if selectors provided
    Map<String, dynamic>? extractedData;
    if (selectors != null && selectors.isNotEmpty) {
      extractedData = await _service.executeScript('''
        (function() {
          const result = {};
          ${selectors.entries.map((entry) {
        final key = entry.key;
        final selector = entry.value;
        final attribute = attributes?[key];

        if (attribute != null) {
          return '''
                result["$key"] = Array.from(document.querySelectorAll('$selector'))
                  .map(el => el.getAttribute('$attribute'))
                  .filter(val => val !== null);
              ''';
        } else {
          return '''
                result["$key"] = Array.from(document.querySelectorAll('$selector'))
                  .map(el => el.textContent.trim())
                  .filter(val => val !== "");
              ''';
        }
      }).join('\n')}
          return result;
        })();
      ''');
    }

    // Get updated HTML
    final html = await _service.executeScript(
      'document.documentElement.outerHTML',
    );

    return HeadlessBrowserResult.success(
      html: html,
      data: extractedData,
      elapsedMillis: result.elapsedMillis,
    );
  }

  /// Handles a site that requires form submission
  Future<HeadlessBrowserResult> handleFormSubmissionSite(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? selectors,
    Map<String, String>? attributes,
    int? timeoutMillis,
    required Map<String, String> formData,
    String? formSelector,
    String? submitSelector,
    int waitAfterSubmit = 3000,
  }) async {
    _logger.info('Handling form submission site: $url');

    final result = await _service.scrapeUrl(
      url,
      headers: headers,
      timeoutMillis: timeoutMillis,
    );

    if (!result.success) {
      return result;
    }

    // Fill form fields
    for (final entry in formData.entries) {
      final fieldName = entry.key;
      final fieldValue = entry.value;

      await _service.executeScript('''
        (function() {
          const field = document.querySelector('input[name="$fieldName"], textarea[name="$fieldName"], select[name="$fieldName"]');
          if (!field) return false;

          field.value = '$fieldValue';

          // Trigger change event
          const event = new Event('change', { bubbles: true });
          field.dispatchEvent(event);

          return true;
        })();
      ''');
    }

    // Submit form
    if (submitSelector != null) {
      await _service.executeScript('''
        (function() {
          const submitButton = document.querySelector('$submitSelector');
          if (!submitButton) return false;

          submitButton.click();
          return true;
        })();
      ''');
    } else if (formSelector != null) {
      await _service.executeScript('''
        (function() {
          const form = document.querySelector('$formSelector');
          if (!form) return false;

          form.submit();
          return true;
        })();
      ''');
    }

    // Wait for form submission to complete
    await Future.delayed(Duration(milliseconds: waitAfterSubmit));

    // Extract data if selectors provided
    Map<String, dynamic>? extractedData;
    if (selectors != null && selectors.isNotEmpty) {
      extractedData = await _service.executeScript('''
        (function() {
          const result = {};
          ${selectors.entries.map((entry) {
        final key = entry.key;
        final selector = entry.value;
        final attribute = attributes?[key];

        if (attribute != null) {
          return '''
                result["$key"] = Array.from(document.querySelectorAll('$selector'))
                  .map(el => el.getAttribute('$attribute'))
                  .filter(val => val !== null);
              ''';
        } else {
          return '''
                result["$key"] = Array.from(document.querySelectorAll('$selector'))
                  .map(el => el.textContent.trim())
                  .filter(val => val !== "");
              ''';
        }
      }).join('\n')}
          return result;
        })();
      ''');
    }

    // Get updated HTML
    final html = await _service.executeScript(
      'document.documentElement.outerHTML',
    );

    return HeadlessBrowserResult.success(
      html: html,
      data: extractedData,
      elapsedMillis: result.elapsedMillis,
    );
  }

  /// Flag to track if the handlers have been disposed
  bool _isDisposed = false;

  /// Disposes the handlers
  Future<void> dispose() async {
    if (_isDisposed) {
      // Already disposed, do nothing
      return;
    }

    _isDisposed = true;

    try {
      await _service.dispose();
    } catch (e) {
      _logger.error('Error disposing specialized handlers: $e');
    }
  }
}
