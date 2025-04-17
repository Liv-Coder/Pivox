import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'scraping_logger.dart';
import 'scraping_exception.dart';

/// A memory-efficient HTML parser for large documents
class MemoryEfficientParser {
  /// The logger for scraping operations
  final ScrapingLogger _logger;

  /// Creates a new [MemoryEfficientParser] with the given parameters
  MemoryEfficientParser({ScrapingLogger? logger})
    : _logger = logger ?? ScrapingLogger();

  /// Parses HTML content and extracts data using CSS selectors in a memory-efficient way
  ///
  /// [html] is the HTML content to parse
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  List<String> extractData({
    required String html,
    required String selector,
    String? attribute,
    bool asText = true,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) {
    _logger.info(
      'Starting memory-efficient extraction with selector: $selector',
    );
    if (attribute != null) {
      _logger.info('Using attribute: $attribute');
    }

    // If the HTML is small enough, use the standard parser
    if (html.length <= chunkSize) {
      return _extractDataStandard(
        html: html,
        selector: selector,
        attribute: attribute,
        asText: asText,
      );
    }

    // For large HTML, use a chunking approach
    return _extractDataChunked(
      html: html,
      selector: selector,
      attribute: attribute,
      asText: asText,
      chunkSize: chunkSize,
    );
  }

  /// Extracts data using the standard parser
  List<String> _extractDataStandard({
    required String html,
    required String selector,
    String? attribute,
    bool asText = true,
  }) {
    try {
      final document = html_parser.parse(html);
      final elements = document.querySelectorAll(selector);
      final results = <String>[];

      for (var element in elements) {
        String value;

        if (attribute != null) {
          value = element.attributes[attribute] ?? '';
        } else if (asText) {
          value = element.text.trim();
        } else {
          value = element.outerHtml;
        }

        if (value.isNotEmpty) {
          results.add(value);
        }
      }

      _logger.info('Extracted ${results.length} items');
      return results;
    } catch (e) {
      _logger.error('Error extracting data: $e');
      throw ScrapingException.parsing(
        'Error extracting data',
        originalException: e,
        isRetryable: false,
      );
    }
  }

  /// Extracts data using a chunking approach for large HTML
  List<String> _extractDataChunked({
    required String html,
    required String selector,
    String? attribute,
    bool asText = true,
    required int chunkSize,
  }) {
    _logger.info(
      'Using chunked approach for large HTML (${html.length} bytes)',
    );

    final results = <String>{};
    final chunks = _splitHtmlIntoChunks(html, chunkSize);

    _logger.info('Split HTML into ${chunks.length} chunks');

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      _logger.info(
        'Processing chunk ${i + 1}/${chunks.length} (${chunk.length} bytes)',
      );

      try {
        final document = html_parser.parse(chunk);
        final elements = document.querySelectorAll(selector);

        for (var element in elements) {
          String value;

          if (attribute != null) {
            value = element.attributes[attribute] ?? '';
          } else if (asText) {
            value = element.text.trim();
          } else {
            value = element.outerHtml;
          }

          if (value.isNotEmpty) {
            results.add(value);
          }
        }
      } catch (e) {
        _logger.warning('Error processing chunk ${i + 1}: $e');
        // Continue with next chunk
      }
    }

    _logger.info('Extracted ${results.length} unique items from all chunks');
    return results.toList();
  }

  /// Splits HTML into overlapping chunks to ensure we don't miss elements that span chunk boundaries
  List<String> _splitHtmlIntoChunks(String html, int chunkSize) {
    final chunks = <String>[];
    final length = html.length;

    // Use a 10% overlap to ensure we don't miss elements that span chunk boundaries
    final overlap = (chunkSize * 0.1).toInt();

    for (int i = 0; i < length; i += chunkSize - overlap) {
      final end = (i + chunkSize < length) ? i + chunkSize : length;
      chunks.add(html.substring(i, end));
    }

    return chunks;
  }

  /// Parses HTML content and extracts structured data using CSS selectors in a memory-efficient way
  ///
  /// [html] is the HTML content to parse
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  List<Map<String, String>> extractStructuredData({
    required String html,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) {
    _logger.info(
      'Starting memory-efficient structured extraction with selectors: ${selectors.toString()}',
    );
    if (attributes != null) {
      _logger.info('Using attributes: ${attributes.toString()}');
    }

    // If the HTML is small enough, use the standard parser
    if (html.length <= chunkSize) {
      return _extractStructuredDataStandard(
        html: html,
        selectors: selectors,
        attributes: attributes,
      );
    }

    // For large HTML, use a chunking approach
    return _extractStructuredDataChunked(
      html: html,
      selectors: selectors,
      attributes: attributes,
      chunkSize: chunkSize,
    );
  }

  /// Extracts structured data using the standard parser
  List<Map<String, String>> _extractStructuredDataStandard({
    required String html,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
  }) {
    try {
      final document = html_parser.parse(html);

      // Find the maximum number of items for any selector
      int maxItems = 0;
      final elementsByField = <String, List<Element>>{};

      selectors.forEach((field, selector) {
        final elements = document.querySelectorAll(selector);
        elementsByField[field] = elements;
        if (elements.length > maxItems) {
          maxItems = elements.length;
        }
      });

      final results = <Map<String, String>>[];

      // Process each item
      for (int i = 0; i < maxItems; i++) {
        final item = <String, String>{};
        bool hasData = false;

        selectors.forEach((field, selector) {
          final elements = elementsByField[field] ?? [];
          if (i < elements.length) {
            final element = elements[i];
            final attribute = attributes?[field];

            if (attribute != null) {
              item[field] = element.attributes[attribute] ?? '';
            } else {
              item[field] = element.text.trim();
            }

            if (item[field]!.isNotEmpty) {
              hasData = true;
            }
          } else {
            item[field] = '';
          }
        });

        // Only add items that have at least some data
        if (hasData) {
          results.add(item);
        }
      }

      _logger.info('Extracted ${results.length} structured items');
      return results;
    } catch (e) {
      _logger.error('Error extracting structured data: $e');
      throw ScrapingException.parsing(
        'Error extracting structured data',
        originalException: e,
        isRetryable: false,
      );
    }
  }

  /// Extracts structured data using a chunking approach for large HTML
  List<Map<String, String>> _extractStructuredDataChunked({
    required String html,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    required int chunkSize,
  }) {
    _logger.info(
      'Using chunked approach for large HTML (${html.length} bytes)',
    );

    final results = <Map<String, String>>[];
    final chunks = _splitHtmlIntoChunks(html, chunkSize);
    final processedItems = <String>{};

    _logger.info('Split HTML into ${chunks.length} chunks');

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      _logger.info(
        'Processing chunk ${i + 1}/${chunks.length} (${chunk.length} bytes)',
      );

      try {
        final document = html_parser.parse(chunk);

        // Find the maximum number of items for any selector
        int maxItems = 0;
        final elementsByField = <String, List<Element>>{};

        selectors.forEach((field, selector) {
          final elements = document.querySelectorAll(selector);
          elementsByField[field] = elements;
          if (elements.length > maxItems) {
            maxItems = elements.length;
          }
        });

        // Process each item
        for (int j = 0; j < maxItems; j++) {
          final item = <String, String>{};
          bool hasData = false;

          selectors.forEach((field, selector) {
            final elements = elementsByField[field] ?? [];
            if (j < elements.length) {
              final element = elements[j];
              final attribute = attributes?[field];

              if (attribute != null) {
                item[field] = element.attributes[attribute] ?? '';
              } else {
                item[field] = element.text.trim();
              }

              if (item[field]!.isNotEmpty) {
                hasData = true;
              }
            } else {
              item[field] = '';
            }
          });

          // Only add items that have at least some data and haven't been processed yet
          if (hasData) {
            final itemKey = _generateItemKey(item);

            if (!processedItems.contains(itemKey)) {
              processedItems.add(itemKey);
              results.add(item);
            }
          }
        }
      } catch (e) {
        _logger.warning('Error processing chunk ${i + 1}: $e');
        // Continue with next chunk
      }
    }

    _logger.info(
      'Extracted ${results.length} unique structured items from all chunks',
    );
    return results;
  }

  /// Generates a unique key for an item to avoid duplicates
  String _generateItemKey(Map<String, String> item) {
    // Use a combination of the item's values as a key
    return item.entries.map((e) => '${e.key}=${e.value}').join(',');
  }
}
