import 'dart:async';
import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'scraping_logger.dart';
import 'scraping_exception.dart';

/// A streaming HTML parser that can process HTML incrementally
class StreamingHtmlParser {
  /// The logger for scraping operations
  final ScrapingLogger _logger;

  /// Creates a new [StreamingHtmlParser] with the given parameters
  StreamingHtmlParser({ScrapingLogger? logger})
      : _logger = logger ?? ScrapingLogger();

  /// Parses HTML content and extracts data using CSS selectors in a streaming fashion
  ///
  /// [htmlStream] is the stream of HTML content to parse
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  Stream<String> extractDataStream({
    required Stream<List<int>> htmlStream,
    required String selector,
    String? attribute,
    bool asText = true,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) async* {
    _logger.info('Starting streaming extraction with selector: $selector');
    if (attribute != null) {
      _logger.info('Using attribute: $attribute');
    }

    // Buffer to accumulate HTML chunks
    final buffer = StringBuffer();
    
    // Track if we've found the opening body tag
    bool foundBody = false;
    
    // Track elements we've already processed to avoid duplicates
    final processedElements = <String>{};

    await for (var chunk in htmlStream.transform(utf8.decoder)) {
      buffer.write(chunk);
      String html = buffer.toString();
      
      // Only start processing once we have the opening body tag
      if (!foundBody && html.contains('<body')) {
        foundBody = true;
      }
      
      // If we haven't found the body yet, continue accumulating
      if (!foundBody) {
        continue;
      }

      try {
        // Parse the accumulated HTML
        final document = html_parser.parse(html);
        
        // Query the elements
        final elements = document.querySelectorAll(selector);
        
        // Process each element
        for (var element in elements) {
          String value;
          
          if (attribute != null) {
            value = element.attributes[attribute] ?? '';
          } else if (asText) {
            value = element.text.trim();
          } else {
            value = element.outerHtml;
          }
          
          // Generate a unique key for this element to avoid duplicates
          final elementKey = _generateElementKey(element, value);
          
          // Only yield elements we haven't processed yet
          if (!processedElements.contains(elementKey) && value.isNotEmpty) {
            processedElements.add(elementKey);
            yield value;
          }
        }
        
        // If the buffer is getting too large, trim it
        if (buffer.length > chunkSize * 2) {
          // Keep only the last chunk to ensure we don't miss elements that span chunks
          html = html.substring(html.length - chunkSize);
          buffer.clear();
          buffer.write(html);
        }
      } catch (e) {
        _logger.warning('Error parsing HTML chunk: $e');
        // Continue processing - don't throw an exception for a single chunk
      }
    }
    
    // Process any remaining HTML
    if (buffer.isNotEmpty) {
      try {
        final document = html_parser.parse(buffer.toString());
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
          
          final elementKey = _generateElementKey(element, value);
          
          if (!processedElements.contains(elementKey) && value.isNotEmpty) {
            processedElements.add(elementKey);
            yield value;
          }
        }
      } catch (e) {
        _logger.error('Error parsing final HTML chunk: $e');
        throw ScrapingException.parsing(
          'Error parsing final HTML chunk',
          originalException: e,
          isRetryable: false,
        );
      }
    }
    
    _logger.info('Completed streaming extraction, found ${processedElements.length} items');
  }

  /// Parses HTML content and extracts structured data using CSS selectors in a streaming fashion
  ///
  /// [htmlStream] is the stream of HTML content to parse
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [chunkSize] is the size of each chunk to process (default: 1024 * 1024 bytes)
  Stream<Map<String, String>> extractStructuredDataStream({
    required Stream<List<int>> htmlStream,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) async* {
    _logger.info(
      'Starting streaming structured extraction with selectors: ${selectors.toString()}',
    );
    if (attributes != null) {
      _logger.info('Using attributes: ${attributes.toString()}');
    }

    // Buffer to accumulate HTML chunks
    final buffer = StringBuffer();
    
    // Track if we've found the opening body tag
    bool foundBody = false;
    
    // Track items we've already processed to avoid duplicates
    final processedItems = <String>{};

    await for (var chunk in htmlStream.transform(utf8.decoder)) {
      buffer.write(chunk);
      String html = buffer.toString();
      
      // Only start processing once we have the opening body tag
      if (!foundBody && html.contains('<body')) {
        foundBody = true;
      }
      
      // If we haven't found the body yet, continue accumulating
      if (!foundBody) {
        continue;
      }

      try {
        // Parse the accumulated HTML
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
          
          // Only yield items that have at least some data
          if (hasData) {
            final itemKey = _generateItemKey(item);
            
            if (!processedItems.contains(itemKey)) {
              processedItems.add(itemKey);
              yield item;
            }
          }
        }
        
        // If the buffer is getting too large, trim it
        if (buffer.length > chunkSize * 2) {
          // Keep only the last chunk to ensure we don't miss elements that span chunks
          html = html.substring(html.length - chunkSize);
          buffer.clear();
          buffer.write(html);
        }
      } catch (e) {
        _logger.warning('Error parsing HTML chunk: $e');
        // Continue processing - don't throw an exception for a single chunk
      }
    }
    
    // Process any remaining HTML
    if (buffer.isNotEmpty) {
      try {
        final document = html_parser.parse(buffer.toString());
        
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
          
          // Only yield items that have at least some data
          if (hasData) {
            final itemKey = _generateItemKey(item);
            
            if (!processedItems.contains(itemKey)) {
              processedItems.add(itemKey);
              yield item;
            }
          }
        }
      } catch (e) {
        _logger.error('Error parsing final HTML chunk: $e');
        throw ScrapingException.parsing(
          'Error parsing final HTML chunk',
          originalException: e,
          isRetryable: false,
        );
      }
    }
    
    _logger.info('Completed streaming structured extraction, found ${processedItems.length} items');
  }

  /// Generates a unique key for an element to avoid duplicates
  String _generateElementKey(Element element, String value) {
    // Use a combination of the element's attributes and value as a key
    final attributes = element.attributes.entries
        .map((e) => '${e.key}=${e.value}')
        .join(',');
    return '$attributes:$value';
  }

  /// Generates a unique key for an item to avoid duplicates
  String _generateItemKey(Map<String, String> item) {
    // Use a combination of the item's values as a key
    return item.entries
        .map((e) => '${e.key}=${e.value}')
        .join(',');
  }
}
