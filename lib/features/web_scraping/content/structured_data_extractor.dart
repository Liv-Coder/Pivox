import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/utils/logger.dart';

/// Types of structured data
enum StructuredDataType {
  /// JSON-LD format
  jsonLd,

  /// Microdata format
  microdata,

  /// RDFa format
  rdfa,

  /// Open Graph format
  openGraph,

  /// Twitter Card format
  twitterCard,

  /// Schema.org format (generic)
  schemaOrg,
}

/// Result of structured data extraction
class StructuredDataExtractionResult {
  /// The type of structured data
  final StructuredDataType type;

  /// The extracted data
  final Map<String, dynamic> data;

  /// The raw data as a string
  final String rawData;

  /// Creates a new [StructuredDataExtractionResult]
  StructuredDataExtractionResult({
    required this.type,
    required this.data,
    required this.rawData,
  });

  @override
  String toString() {
    return 'StructuredDataExtractionResult{type: $type, data: $data}';
  }
}

/// Utility class for extracting structured data from HTML
class StructuredDataExtractor {
  /// Logger for logging operations
  final Logger? logger;

  /// Creates a new [StructuredDataExtractor]
  StructuredDataExtractor({this.logger});

  /// Extracts all structured data from HTML
  List<StructuredDataExtractionResult> extractAll(String html) {
    final results = <StructuredDataExtractionResult>[];

    try {
      // Extract JSON-LD
      results.addAll(extractJsonLd(html));

      // Extract Microdata
      results.addAll(extractMicrodata(html));

      // Extract RDFa
      results.addAll(extractRdfa(html));

      // Extract Open Graph
      results.addAll(extractOpenGraph(html));

      // Extract Twitter Card
      results.addAll(extractTwitterCard(html));

      logger?.info('Extracted ${results.length} structured data items');
    } catch (e) {
      logger?.error('Error extracting structured data: $e');
    }

    return results;
  }

  /// Extracts JSON-LD data from HTML
  List<StructuredDataExtractionResult> extractJsonLd(String html) {
    final results = <StructuredDataExtractionResult>[];
    final document = html_parser.parse(html);

    try {
      // Find all script tags with type="application/ld+json"
      final scriptElements = document.querySelectorAll(
        'script[type="application/ld+json"]',
      );

      for (final scriptElement in scriptElements) {
        final jsonLdText = scriptElement.text.trim();
        if (jsonLdText.isEmpty) continue;

        try {
          // Parse JSON
          final dynamic jsonData = json.decode(jsonLdText);

          // Handle both single objects and arrays of objects
          if (jsonData is List) {
            for (final item in jsonData) {
              if (item is Map<String, dynamic>) {
                results.add(
                  StructuredDataExtractionResult(
                    type: StructuredDataType.jsonLd,
                    data: item,
                    rawData: jsonLdText,
                  ),
                );
              }
            }
          } else if (jsonData is Map<String, dynamic>) {
            results.add(
              StructuredDataExtractionResult(
                type: StructuredDataType.jsonLd,
                data: jsonData,
                rawData: jsonLdText,
              ),
            );
          }
        } catch (e) {
          logger?.warning('Error parsing JSON-LD: $e');
        }
      }

      logger?.info('Extracted ${results.length} JSON-LD items');
    } catch (e) {
      logger?.error('Error extracting JSON-LD: $e');
    }

    return results;
  }

  /// Extracts Microdata from HTML
  List<StructuredDataExtractionResult> extractMicrodata(String html) {
    final results = <StructuredDataExtractionResult>[];
    final document = html_parser.parse(html);

    try {
      // Find all elements with itemscope attribute
      final itemscopeElements = document.querySelectorAll('[itemscope]');

      for (final element in itemscopeElements) {
        // Skip nested itemscope elements (they will be processed as part of their parent)
        if (element.parent != null &&
            element.parent!.attributes.containsKey('itemscope')) {
          continue;
        }

        final data = _extractItemscope(element);
        if (data.isNotEmpty) {
          results.add(
            StructuredDataExtractionResult(
              type: StructuredDataType.microdata,
              data: data,
              rawData: element.outerHtml,
            ),
          );
        }
      }

      logger?.info('Extracted ${results.length} Microdata items');
    } catch (e) {
      logger?.error('Error extracting Microdata: $e');
    }

    return results;
  }

  /// Recursively extracts itemscope data from an element
  Map<String, dynamic> _extractItemscope(Element element) {
    final result = <String, dynamic>{};

    // Get item type
    if (element.attributes.containsKey('itemtype')) {
      result['@type'] = element.attributes['itemtype'];
    }

    // Get item id
    if (element.attributes.containsKey('itemid')) {
      result['@id'] = element.attributes['itemid'];
    }

    // Process itemprop elements
    final itemprops = element.querySelectorAll('[itemprop]');
    for (final itemprop in itemprops) {
      // Skip if this itemprop belongs to a nested itemscope
      if (itemprop != element &&
          itemprop.attributes.containsKey('itemscope') &&
          itemprop.parent != element) {
        continue;
      }

      final propName = itemprop.attributes['itemprop'];
      if (propName == null || propName.isEmpty) continue;

      dynamic propValue;

      // Handle nested itemscope
      if (itemprop.attributes.containsKey('itemscope')) {
        propValue = _extractItemscope(itemprop);
      } else {
        // Extract value based on element type
        propValue = _extractItemPropValue(itemprop);
      }

      // Add to result
      if (propValue != null) {
        // Handle multiple properties with the same name
        if (result.containsKey(propName)) {
          if (result[propName] is List) {
            (result[propName] as List).add(propValue);
          } else {
            result[propName] = [result[propName], propValue];
          }
        } else {
          result[propName] = propValue;
        }
      }
    }

    return result;
  }

  /// Extracts the value of an itemprop element
  dynamic _extractItemPropValue(Element element) {
    // Check for specific attributes based on element type
    if (element.localName == 'meta' &&
        element.attributes.containsKey('content')) {
      return element.attributes['content'];
    } else if (element.localName == 'img' &&
        element.attributes.containsKey('src')) {
      return element.attributes['src'];
    } else if (element.localName == 'a' &&
        element.attributes.containsKey('href')) {
      return element.attributes['href'];
    } else if (element.localName == 'time' &&
        element.attributes.containsKey('datetime')) {
      return element.attributes['datetime'];
    } else if (element.localName == 'data' &&
        element.attributes.containsKey('value')) {
      return element.attributes['value'];
    } else if (element.localName == 'meter' &&
        element.attributes.containsKey('value')) {
      return element.attributes['value'];
    } else if (element.localName == 'link' &&
        element.attributes.containsKey('href')) {
      return element.attributes['href'];
    } else {
      // Default to text content
      return element.text.trim();
    }
  }

  /// Extracts RDFa data from HTML
  List<StructuredDataExtractionResult> extractRdfa(String html) {
    final results = <StructuredDataExtractionResult>[];
    final document = html_parser.parse(html);

    try {
      // Find all elements with typeof attribute (RDFa 1.1)
      final typeofElements = document.querySelectorAll('[typeof]');

      for (final element in typeofElements) {
        // Skip nested typeof elements (they will be processed as part of their parent)
        if (element.parent != null &&
            element.parent!.attributes.containsKey('typeof')) {
          continue;
        }

        final data = _extractRdfaType(element);
        if (data.isNotEmpty) {
          results.add(
            StructuredDataExtractionResult(
              type: StructuredDataType.rdfa,
              data: data,
              rawData: element.outerHtml,
            ),
          );
        }
      }

      logger?.info('Extracted ${results.length} RDFa items');
    } catch (e) {
      logger?.error('Error extracting RDFa: $e');
    }

    return results;
  }

  /// Recursively extracts RDFa data from an element
  Map<String, dynamic> _extractRdfaType(Element element) {
    final result = <String, dynamic>{};

    // Get type
    if (element.attributes.containsKey('typeof')) {
      result['@type'] = element.attributes['typeof'];
    }

    // Get resource/about (subject)
    if (element.attributes.containsKey('resource')) {
      result['@id'] = element.attributes['resource'];
    } else if (element.attributes.containsKey('about')) {
      result['@id'] = element.attributes['about'];
    }

    // Process property elements
    final propertyElements = element.querySelectorAll('[property]');
    for (final propElement in propertyElements) {
      // Skip if this property belongs to a nested typeof
      if (propElement != element &&
          propElement.attributes.containsKey('typeof') &&
          propElement.parent != element) {
        continue;
      }

      final propName = propElement.attributes['property'];
      if (propName == null || propName.isEmpty) continue;

      dynamic propValue;

      // Handle nested typeof
      if (propElement.attributes.containsKey('typeof')) {
        propValue = _extractRdfaType(propElement);
      } else {
        // Extract value based on element type
        propValue = _extractRdfaPropertyValue(propElement);
      }

      // Add to result
      if (propValue != null) {
        // Handle multiple properties with the same name
        if (result.containsKey(propName)) {
          if (result[propName] is List) {
            (result[propName] as List).add(propValue);
          } else {
            result[propName] = [result[propName], propValue];
          }
        } else {
          result[propName] = propValue;
        }
      }
    }

    return result;
  }

  /// Extracts the value of a RDFa property element
  dynamic _extractRdfaPropertyValue(Element element) {
    // Check for content attribute first (explicit value)
    if (element.attributes.containsKey('content')) {
      return element.attributes['content'];
    } else if (element.attributes.containsKey('resource')) {
      return element.attributes['resource'];
    } else if (element.attributes.containsKey('href')) {
      return element.attributes['href'];
    } else if (element.attributes.containsKey('src')) {
      return element.attributes['src'];
    } else if (element.attributes.containsKey('datetime')) {
      return element.attributes['datetime'];
    } else {
      // Default to text content
      return element.text.trim();
    }
  }

  /// Extracts Open Graph data from HTML
  List<StructuredDataExtractionResult> extractOpenGraph(String html) {
    final document = html_parser.parse(html);
    final results = <StructuredDataExtractionResult>[];

    try {
      // Find all meta tags with property starting with "og:"
      final metaTags = document.querySelectorAll('meta[property^="og:"]');

      if (metaTags.isEmpty) {
        return results;
      }

      final data = <String, dynamic>{};

      for (final metaTag in metaTags) {
        final property = metaTag.attributes['property'];
        final content = metaTag.attributes['content'];

        if (property != null && content != null) {
          // Remove the "og:" prefix
          final key = property.substring(3);

          // Handle arrays (e.g., og:image, og:image:width, og:image:height)
          if (key.contains(':')) {
            final parts = key.split(':');
            final mainKey = parts[0];
            final subKey = parts.sublist(1).join(':');

            if (!data.containsKey(mainKey)) {
              data[mainKey] = <String, dynamic>{};
            } else if (data[mainKey] is! Map) {
              // If it's already a string, convert to a map with 'url' key
              data[mainKey] = {'url': data[mainKey]};
            }

            if (data[mainKey] is Map) {
              (data[mainKey] as Map<String, dynamic>)[subKey] = content;
            }
          } else {
            data[key] = content;
          }
        }
      }

      if (data.isNotEmpty) {
        // Add type information
        data['@type'] = 'OpenGraph';

        results.add(
          StructuredDataExtractionResult(
            type: StructuredDataType.openGraph,
            data: data,
            rawData: metaTags.map((e) => e.outerHtml).join('\n'),
          ),
        );
      }

      logger?.info('Extracted ${results.length} Open Graph items');
    } catch (e) {
      logger?.error('Error extracting Open Graph data: $e');
    }

    return results;
  }

  /// Extracts Twitter Card data from HTML
  List<StructuredDataExtractionResult> extractTwitterCard(String html) {
    final document = html_parser.parse(html);
    final results = <StructuredDataExtractionResult>[];

    try {
      // Find all meta tags with name starting with "twitter:"
      final metaTags = document.querySelectorAll('meta[name^="twitter:"]');

      if (metaTags.isEmpty) {
        return results;
      }

      final data = <String, dynamic>{};

      for (final metaTag in metaTags) {
        final name = metaTag.attributes['name'];
        final content = metaTag.attributes['content'];

        if (name != null && content != null) {
          // Remove the "twitter:" prefix
          final key = name.substring(8);
          data[key] = content;
        }
      }

      if (data.isNotEmpty) {
        // Add type information
        data['@type'] = 'TwitterCard';

        results.add(
          StructuredDataExtractionResult(
            type: StructuredDataType.twitterCard,
            data: data,
            rawData: metaTags.map((e) => e.outerHtml).join('\n'),
          ),
        );
      }

      logger?.info('Extracted ${results.length} Twitter Card items');
    } catch (e) {
      logger?.error('Error extracting Twitter Card data: $e');
    }

    return results;
  }

  /// Extracts structured data of a specific type
  List<StructuredDataExtractionResult> extractByType(
    String html,
    StructuredDataType type,
  ) {
    switch (type) {
      case StructuredDataType.jsonLd:
        return extractJsonLd(html);
      case StructuredDataType.microdata:
        return extractMicrodata(html);
      case StructuredDataType.rdfa:
        return extractRdfa(html);
      case StructuredDataType.openGraph:
        return extractOpenGraph(html);
      case StructuredDataType.twitterCard:
        return extractTwitterCard(html);
      case StructuredDataType.schemaOrg:
        // Combine JSON-LD, Microdata, and RDFa results that use schema.org
        final results = <StructuredDataExtractionResult>[];
        results.addAll(
          extractJsonLd(html).where(
            (r) =>
                r.data['@context']?.toString().contains('schema.org') == true ||
                r.data['@type']?.toString().startsWith('http://schema.org/') ==
                    true ||
                r.data['@type']?.toString().startsWith('https://schema.org/') ==
                    true,
          ),
        );
        results.addAll(
          extractMicrodata(html).where(
            (r) => r.data['@type']?.toString().contains('schema.org') == true,
          ),
        );
        results.addAll(
          extractRdfa(html).where(
            (r) => r.data['@type']?.toString().contains('schema.org') == true,
          ),
        );
        return results;
    }
  }

  /// Extracts structured data and converts it to a specific schema
  Map<String, dynamic>? extractAsSchema(
    String html,
    String schemaType, {
    List<StructuredDataType> preferredTypes = const [
      StructuredDataType.jsonLd,
      StructuredDataType.microdata,
      StructuredDataType.rdfa,
    ],
  }) {
    // Try each preferred type in order
    for (final type in preferredTypes) {
      final results = extractByType(html, type);

      // Find the first result that matches the schema type
      for (final result in results) {
        final resultType = result.data['@type'];
        if (resultType != null) {
          // Check if the type matches (handle both full URLs and short names)
          if (resultType == schemaType ||
              resultType == 'http://schema.org/$schemaType' ||
              resultType == 'https://schema.org/$schemaType' ||
              (resultType is String && resultType.endsWith('/$schemaType'))) {
            return result.data;
          }
        }
      }
    }

    return null;
  }

  /// Extracts all product information from the HTML
  List<Map<String, dynamic>> extractProducts(String html) {
    final products = <Map<String, dynamic>>[];

    // Try to extract products from JSON-LD
    final jsonLdResults = extractJsonLd(html);
    for (final result in jsonLdResults) {
      if (result.data['@type'] == 'Product' ||
          result.data['@type'] == 'http://schema.org/Product' ||
          result.data['@type'] == 'https://schema.org/Product') {
        products.add(result.data);
      }
    }

    // Try to extract products from Microdata
    final microdataResults = extractMicrodata(html);
    for (final result in microdataResults) {
      if (result.data['@type']?.toString().contains('Product') == true) {
        products.add(result.data);
      }
    }

    // Try to extract products from RDFa
    final rdfaResults = extractRdfa(html);
    for (final result in rdfaResults) {
      if (result.data['@type']?.toString().contains('Product') == true) {
        products.add(result.data);
      }
    }

    return products;
  }

  /// Extracts all article information from the HTML
  List<Map<String, dynamic>> extractArticles(String html) {
    final articles = <Map<String, dynamic>>[];

    // Try to extract articles from JSON-LD
    final jsonLdResults = extractJsonLd(html);
    for (final result in jsonLdResults) {
      if (result.data['@type'] == 'Article' ||
          result.data['@type'] == 'NewsArticle' ||
          result.data['@type'] == 'BlogPosting' ||
          result.data['@type']?.toString().contains('Article') == true) {
        articles.add(result.data);
      }
    }

    // Try to extract articles from Microdata
    final microdataResults = extractMicrodata(html);
    for (final result in microdataResults) {
      if (result.data['@type']?.toString().contains('Article') == true) {
        articles.add(result.data);
      }
    }

    // Try to extract articles from RDFa
    final rdfaResults = extractRdfa(html);
    for (final result in rdfaResults) {
      if (result.data['@type']?.toString().contains('Article') == true) {
        articles.add(result.data);
      }
    }

    // Try to extract articles from Open Graph
    final ogResults = extractOpenGraph(html);
    for (final result in ogResults) {
      if (result.data['type'] == 'article') {
        articles.add(result.data);
      }
    }

    return articles;
  }
}
