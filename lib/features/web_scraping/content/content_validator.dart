import '../../../core/utils/logger.dart';

/// Result of a content validation
class ContentValidationResult {
  /// Whether the content is valid
  final bool isValid;

  /// The original content
  final String originalContent;

  /// The cleaned content, if any
  final String? cleanedContent;

  /// The error message, if any
  final String? errorMessage;

  /// Creates a new [ContentValidationResult] with the given parameters
  ContentValidationResult({
    required this.isValid,
    required this.originalContent,
    this.cleanedContent,
    this.errorMessage,
  });

  /// Creates a new [ContentValidationResult] for valid content
  factory ContentValidationResult.valid(String content) {
    return ContentValidationResult(
      isValid: true,
      originalContent: content,
    );
  }

  /// Creates a new [ContentValidationResult] for invalid content
  factory ContentValidationResult.invalid(
    String content, {
    String? errorMessage,
  }) {
    return ContentValidationResult(
      isValid: false,
      originalContent: content,
      errorMessage: errorMessage ?? 'Invalid content',
    );
  }

  /// Creates a new [ContentValidationResult] for cleaned content
  factory ContentValidationResult.cleaned(
    String originalContent,
    String cleanedContent,
  ) {
    return ContentValidationResult(
      isValid: true,
      originalContent: originalContent,
      cleanedContent: cleanedContent,
    );
  }
}

/// Utility class for validating and cleaning extracted content
class ContentValidator {
  /// Logger for logging content operations
  final Logger? logger;

  /// Minimum content length to be considered valid
  final int minContentLength;

  /// Maximum content length to be considered valid
  final int maxContentLength;

  /// Whether to clean HTML tags from content
  final bool cleanHtmlTags;

  /// Whether to normalize whitespace in content
  final bool normalizeWhitespace;

  /// Whether to trim content
  final bool trimContent;

  /// Creates a new [ContentValidator] with the given parameters
  ContentValidator({
    this.logger,
    this.minContentLength = 1,
    this.maxContentLength = 100000,
    this.cleanHtmlTags = true,
    this.normalizeWhitespace = true,
    this.trimContent = true,
  });

  /// Validates a single content string
  ContentValidationResult validateContent(String content) {
    if (content.isEmpty) {
      return ContentValidationResult.invalid(
        content,
        errorMessage: 'Content is empty',
      );
    }

    if (content.length < minContentLength) {
      return ContentValidationResult.invalid(
        content,
        errorMessage: 'Content is too short (${content.length} < $minContentLength)',
      );
    }

    if (content.length > maxContentLength) {
      return ContentValidationResult.invalid(
        content,
        errorMessage: 'Content is too long (${content.length} > $maxContentLength)',
      );
    }

    // Clean the content if needed
    String? cleanedContent;
    bool needsCleaning = false;

    if (cleanHtmlTags && _containsHtmlTags(content)) {
      cleanedContent = _cleanHtmlTags(content);
      needsCleaning = true;
    }

    if (normalizeWhitespace && _containsExcessiveWhitespace(content)) {
      cleanedContent = _normalizeWhitespace(cleanedContent ?? content);
      needsCleaning = true;
    }

    if (trimContent && (content.startsWith(' ') || content.endsWith(' '))) {
      cleanedContent = (cleanedContent ?? content).trim();
      needsCleaning = true;
    }

    if (needsCleaning) {
      return ContentValidationResult.cleaned(
        content,
        cleanedContent!,
      );
    }

    return ContentValidationResult.valid(content);
  }

  /// Validates a list of content strings
  List<ContentValidationResult> validateContentList(List<String> contentList) {
    return contentList.map(validateContent).toList();
  }

  /// Validates a map of content strings
  Map<String, ContentValidationResult> validateContentMap(
    Map<String, String> contentMap,
  ) {
    final results = <String, ContentValidationResult>{};

    for (final entry in contentMap.entries) {
      results[entry.key] = validateContent(entry.value);
    }

    return results;
  }

  /// Validates a list of maps of content strings
  List<Map<String, ContentValidationResult>> validateContentMapList(
    List<Map<String, String>> contentMapList,
  ) {
    return contentMapList.map(validateContentMap).toList();
  }

  /// Cleans a single content string
  String cleanContent(String content) {
    var cleanedContent = content;

    if (cleanHtmlTags) {
      cleanedContent = _cleanHtmlTags(cleanedContent);
    }

    if (normalizeWhitespace) {
      cleanedContent = _normalizeWhitespace(cleanedContent);
    }

    if (trimContent) {
      cleanedContent = cleanedContent.trim();
    }

    return cleanedContent;
  }

  /// Cleans a list of content strings
  List<String> cleanContentList(List<String> contentList) {
    return contentList.map(cleanContent).toList();
  }

  /// Cleans a map of content strings
  Map<String, String> cleanContentMap(Map<String, String> contentMap) {
    final results = <String, String>{};

    for (final entry in contentMap.entries) {
      results[entry.key] = cleanContent(entry.value);
    }

    return results;
  }

  /// Cleans a list of maps of content strings
  List<Map<String, String>> cleanContentMapList(
    List<Map<String, String>> contentMapList,
  ) {
    return contentMapList.map(cleanContentMap).toList();
  }

  /// Checks if the content contains HTML tags
  bool _containsHtmlTags(String content) {
    return RegExp(r'<[^>]+>').hasMatch(content);
  }

  /// Cleans HTML tags from the content
  String _cleanHtmlTags(String content) {
    return content.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Checks if the content contains excessive whitespace
  bool _containsExcessiveWhitespace(String content) {
    return RegExp(r'\s{2,}').hasMatch(content);
  }

  /// Normalizes whitespace in the content
  String _normalizeWhitespace(String content) {
    return content.replaceAll(RegExp(r'\s+'), ' ');
  }
}
