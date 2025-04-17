import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/utils/logger.dart';
import 'adaptive_selector.dart';

/// Result of a selector validation
class SelectorValidationResult {
  /// Whether the selector is valid
  final bool isValid;

  /// The original selector
  final String originalSelector;

  /// The repaired selector, if any
  final String? repairedSelector;

  /// The error message, if any
  final String? errorMessage;

  /// The number of elements found with the selector
  final int elementCount;

  /// Creates a new [SelectorValidationResult] with the given parameters
  SelectorValidationResult({
    required this.isValid,
    required this.originalSelector,
    this.repairedSelector,
    this.errorMessage,
    this.elementCount = 0,
  });

  /// Creates a new [SelectorValidationResult] for a valid selector
  factory SelectorValidationResult.valid(
    String selector, {
    int elementCount = 0,
  }) {
    return SelectorValidationResult(
      isValid: true,
      originalSelector: selector,
      elementCount: elementCount,
    );
  }

  /// Creates a new [SelectorValidationResult] for an invalid selector
  factory SelectorValidationResult.invalid(
    String selector, {
    String? errorMessage,
  }) {
    return SelectorValidationResult(
      isValid: false,
      originalSelector: selector,
      errorMessage: errorMessage ?? 'Invalid selector',
    );
  }

  /// Creates a new [SelectorValidationResult] for a repaired selector
  factory SelectorValidationResult.repaired(
    String originalSelector,
    String repairedSelector, {
    int elementCount = 0,
  }) {
    return SelectorValidationResult(
      isValid: true,
      originalSelector: originalSelector,
      repairedSelector: repairedSelector,
      elementCount: elementCount,
    );
  }
}

/// Utility class for validating and repairing CSS selectors
class SelectorValidator {
  /// Logger for logging selector operations
  final Logger? logger;

  /// Creates a new [SelectorValidator] with the given parameters
  SelectorValidator({this.logger});

  /// Validates a selector against the given HTML
  SelectorValidationResult validateSelector(String selector, String html) {
    try {
      final document = html_parser.parse(html);
      return validateSelectorWithDocument(selector, document);
    } catch (e) {
      logger?.error('Error parsing HTML: $e');
      return SelectorValidationResult.invalid(
        selector,
        errorMessage: 'Error parsing HTML: $e',
      );
    }
  }

  /// Validates a selector against the given document
  SelectorValidationResult validateSelectorWithDocument(
    String selector,
    Document document,
  ) {
    try {
      // Try to use the selector
      final elements = document.querySelectorAll(selector);

      if (elements.isNotEmpty) {
        logger?.info('Selector "$selector" found ${elements.length} elements');
        return SelectorValidationResult.valid(
          selector,
          elementCount: elements.length,
        );
      } else {
        logger?.warning('Selector "$selector" found no elements');

        // Try to repair the selector
        final repairedSelector = repairSelector(selector, document);

        if (repairedSelector != null && repairedSelector != selector) {
          final repairedElements = document.querySelectorAll(repairedSelector);

          if (repairedElements.isNotEmpty) {
            logger?.info(
              'Repaired selector "$repairedSelector" found ${repairedElements.length} elements',
            );

            return SelectorValidationResult.repaired(
              selector,
              repairedSelector,
              elementCount: repairedElements.length,
            );
          }
        }

        return SelectorValidationResult.invalid(
          selector,
          errorMessage: 'Selector found no elements',
        );
      }
    } catch (e) {
      logger?.error('Error validating selector "$selector": $e');

      // Try to repair the selector
      final repairedSelector = repairSelector(selector, document);

      if (repairedSelector != null && repairedSelector != selector) {
        try {
          final repairedElements = document.querySelectorAll(repairedSelector);

          if (repairedElements.isNotEmpty) {
            logger?.info(
              'Repaired selector "$repairedSelector" found ${repairedElements.length} elements',
            );

            return SelectorValidationResult.repaired(
              selector,
              repairedSelector,
              elementCount: repairedElements.length,
            );
          }
        } catch (e) {
          // Repaired selector is also invalid
        }
      }

      return SelectorValidationResult.invalid(
        selector,
        errorMessage: 'Invalid selector: $e',
      );
    }
  }

  /// Repairs a selector if possible
  String? repairSelector(String selector, Document document) {
    // Apply simple fixes
    var repairedSelector = selector;

    // Fix missing space after comma
    repairedSelector = repairedSelector.replaceAllMapped(
      RegExp(r',([^\s])'),
      (match) => ', ${match[1]}',
    );

    // Fix spaces around operators
    repairedSelector = repairedSelector.replaceAll(RegExp(r'\s*>\s*'), ' > ');
    repairedSelector = repairedSelector.replaceAll(RegExp(r'\s*\+\s*'), ' + ');
    repairedSelector = repairedSelector.replaceAll(RegExp(r'\s*~\s*'), ' ~ ');

    // Remove unclosed brackets
    if (repairedSelector.contains('[') && !repairedSelector.contains(']')) {
      repairedSelector = repairedSelector.replaceAll(RegExp(r'\[[^\]]*$'), '');
    }

    // Remove unclosed parentheses
    if (repairedSelector.contains('(') && !repairedSelector.contains(')')) {
      repairedSelector = repairedSelector.replaceAll(RegExp(r'\([^)]*$'), '');
    }

    // If the repaired selector is different, try it
    if (repairedSelector != selector) {
      try {
        final elements = document.querySelectorAll(repairedSelector);
        if (elements.isNotEmpty) {
          return repairedSelector;
        }
      } catch (e) {
        // Repaired selector is still invalid
      }
    }

    // Try to find alternative selectors
    final adaptiveSelector = AdaptiveSelector(
      primarySelector: selector,
      logger: logger,
    );

    final alternatives = adaptiveSelector.suggestAlternativesFromDocument(
      document,
    );

    for (final alternative in alternatives) {
      try {
        final elements = document.querySelectorAll(alternative);
        if (elements.isNotEmpty) {
          return alternative;
        }
      } catch (e) {
        // Alternative is invalid
      }
    }

    // If all else fails, try to simplify the selector
    final parts = selector.split(' ');
    if (parts.length > 1) {
      // Try the last part only
      final lastPart = parts.last;
      try {
        final elements = document.querySelectorAll(lastPart);
        if (elements.isNotEmpty) {
          return lastPart;
        }
      } catch (e) {
        // Last part is invalid
      }

      // Try the first part only
      final firstPart = parts.first;
      try {
        final elements = document.querySelectorAll(firstPart);
        if (elements.isNotEmpty) {
          return firstPart;
        }
      } catch (e) {
        // First part is invalid
      }
    }

    return null;
  }

  /// Validates a map of selectors against the given HTML
  Map<String, SelectorValidationResult> validateSelectors(
    Map<String, String> selectors,
    String html,
  ) {
    final document = html_parser.parse(html);
    return validateSelectorsWithDocument(selectors, document);
  }

  /// Validates a map of selectors against the given document
  Map<String, SelectorValidationResult> validateSelectorsWithDocument(
    Map<String, String> selectors,
    Document document,
  ) {
    final results = <String, SelectorValidationResult>{};

    for (final entry in selectors.entries) {
      final field = entry.key;
      final selector = entry.value;

      results[field] = validateSelectorWithDocument(selector, document);
    }

    return results;
  }

  /// Suggests alternative selectors for a given selector
  List<String> suggestAlternatives(String selector, String html) {
    try {
      final document = html_parser.parse(html);
      return suggestAlternativesWithDocument(selector, document);
    } catch (e) {
      logger?.error('Error parsing HTML: $e');
      return [];
    }
  }

  /// Suggests alternative selectors for a given selector with a document
  List<String> suggestAlternativesWithDocument(
    String selector,
    Document document,
  ) {
    final adaptiveSelector = AdaptiveSelector(
      primarySelector: selector,
      logger: logger,
    );

    return adaptiveSelector.suggestAlternativesFromDocument(document);
  }
}
