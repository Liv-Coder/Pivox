import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/utils/logger.dart';

/// A selector that can adapt to different HTML structures
class AdaptiveSelector {
  /// The primary selector to try first
  final String primarySelector;

  /// Alternative selectors to try if the primary selector fails
  final List<String> alternativeSelectors;

  /// The attribute to extract from the element
  final String? attribute;

  /// Whether to extract the text content of the element
  final bool asText;

  /// Logger for logging selector operations
  final Logger? logger;

  /// Creates a new [AdaptiveSelector] with the given parameters
  AdaptiveSelector({
    required this.primarySelector,
    this.alternativeSelectors = const [],
    this.attribute,
    this.asText = true,
    this.logger,
  });

  /// Creates a new [AdaptiveSelector] from a string
  factory AdaptiveSelector.fromString(
    String selector, {
    String? attribute,
    bool asText = true,
    Logger? logger,
  }) {
    return AdaptiveSelector(
      primarySelector: selector,
      attribute: attribute,
      asText: asText,
      logger: logger,
    );
  }

  /// Creates a new [AdaptiveSelector] with multiple selectors
  factory AdaptiveSelector.withAlternatives({
    required String primarySelector,
    required List<String> alternativeSelectors,
    String? attribute,
    bool asText = true,
    Logger? logger,
  }) {
    return AdaptiveSelector(
      primarySelector: primarySelector,
      alternativeSelectors: alternativeSelectors,
      attribute: attribute,
      asText: asText,
      logger: logger,
    );
  }

  /// Extracts data from the given HTML using this selector
  List<String> extract(String html) {
    final document = html_parser.parse(html);
    return extractFromDocument(document);
  }

  /// Extracts data from the given document using this selector
  List<String> extractFromDocument(Document document) {
    // Try the primary selector first
    var elements = document.querySelectorAll(primarySelector);

    // If the primary selector doesn't find any elements, try the alternatives
    if (elements.isEmpty && alternativeSelectors.isNotEmpty) {
      logger?.info(
        'Primary selector "$primarySelector" found no elements, trying alternatives',
      );

      for (final alternativeSelector in alternativeSelectors) {
        elements = document.querySelectorAll(alternativeSelector);
        if (elements.isNotEmpty) {
          logger?.info(
            'Alternative selector "$alternativeSelector" found ${elements.length} elements',
          );
          break;
        }
      }
    }

    if (elements.isEmpty) {
      logger?.warning('No elements found with any selectors');
      return [];
    }

    logger?.info('Found ${elements.length} elements with selector');

    // Extract the data from the elements
    return elements.map((element) {
      if (attribute != null) {
        final value = element.attributes[attribute] ?? '';
        if (value.isEmpty) {
          logger?.warning(
            'Attribute "$attribute" not found or empty in element',
          );
        }
        return value;
      } else if (asText) {
        final text = element.text.trim();
        if (text.isEmpty) {
          logger?.warning('Text content is empty in element');
        }
        return text;
      } else {
        return element.outerHtml;
      }
    }).toList();
  }

  /// Extracts a single value from the given HTML using this selector
  String? extractSingle(String html) {
    final results = extract(html);
    return results.isNotEmpty ? results.first : null;
  }

  /// Extracts a single value from the given document using this selector
  String? extractSingleFromDocument(Document document) {
    final results = extractFromDocument(document);
    return results.isNotEmpty ? results.first : null;
  }

  /// Validates that this selector can find elements in the given HTML
  bool validate(String html) {
    final results = extract(html);
    return results.isNotEmpty;
  }

  /// Validates that this selector can find elements in the given document
  bool validateDocument(Document document) {
    final results = extractFromDocument(document);
    return results.isNotEmpty;
  }

  /// Suggests alternative selectors based on the given HTML
  List<String> suggestAlternatives(String html) {
    final document = html_parser.parse(html);
    return suggestAlternativesFromDocument(document);
  }

  /// Suggests alternative selectors based on the given document
  List<String> suggestAlternativesFromDocument(Document document) {
    final suggestions = <String>[];

    // If the primary selector works, no need for alternatives
    if (validateDocument(document)) {
      return suggestions;
    }

    // Try to find elements with similar tag names or classes
    final parts = primarySelector.split(' ');
    final lastPart = parts.last;

    // Extract tag name and class from the last part
    String? tagName;
    String? className;

    if (lastPart.contains('.')) {
      final tagAndClass = lastPart.split('.');
      tagName = tagAndClass[0].isEmpty ? null : tagAndClass[0];
      className = tagAndClass.length > 1 ? tagAndClass[1] : null;
    } else if (lastPart.contains('#')) {
      final tagAndId = lastPart.split('#');
      tagName = tagAndId[0].isEmpty ? null : tagAndId[0];
    } else {
      tagName = lastPart;
    }

    // Try tag name only
    if (tagName != null && tagName.isNotEmpty) {
      final tagSelector =
          '${parts.sublist(0, parts.length - 1).join(' ')}${parts.length > 1 ? ' ' : ''}$tagName';

      if (document.querySelectorAll(tagSelector).isNotEmpty) {
        suggestions.add(tagSelector);
      }
    }

    // Try similar classes
    if (className != null && className.isNotEmpty) {
      // Find elements with class names containing the target class
      final allElements = document.querySelectorAll('*');
      final classSet = <String>{};

      for (final element in allElements) {
        final classes = element.classes;
        for (final cls in classes) {
          if (cls.contains(className) || className.contains(cls)) {
            classSet.add(cls);
          }
        }
      }

      for (final cls in classSet) {
        if (cls != className) {
          final classSelector =
              '${parts.sublist(0, parts.length - 1).join(' ')}${parts.length > 1 ? ' ' : ''}${tagName != null && tagName.isNotEmpty ? tagName : ''}.$cls';

          if (document.querySelectorAll(classSelector).isNotEmpty) {
            suggestions.add(classSelector);
          }
        }
      }
    }

    // Try parent elements
    if (parts.length > 1) {
      final parentSelector = parts.sublist(0, parts.length - 1).join(' ');
      if (document.querySelectorAll(parentSelector).isNotEmpty) {
        suggestions.add(parentSelector);
      }
    }

    return suggestions;
  }
}
