import '../../../core/utils/logger.dart';
import 'content_validator.dart';

/// Result of a structured data validation
class StructuredDataValidationResult {
  /// Whether the structured data is valid
  final bool isValid;

  /// The original structured data
  final Map<String, String> originalData;

  /// The cleaned structured data, if any
  final Map<String, String>? cleanedData;

  /// The validation results for each field
  final Map<String, ContentValidationResult> fieldResults;

  /// The error message, if any
  final String? errorMessage;

  /// Creates a new [StructuredDataValidationResult] with the given parameters
  StructuredDataValidationResult({
    required this.isValid,
    required this.originalData,
    this.cleanedData,
    required this.fieldResults,
    this.errorMessage,
  });

  /// Creates a new [StructuredDataValidationResult] for valid structured data
  factory StructuredDataValidationResult.valid(
    Map<String, String> data,
    Map<String, ContentValidationResult> fieldResults,
  ) {
    return StructuredDataValidationResult(
      isValid: true,
      originalData: data,
      fieldResults: fieldResults,
    );
  }

  /// Creates a new [StructuredDataValidationResult] for invalid structured data
  factory StructuredDataValidationResult.invalid(
    Map<String, String> data,
    Map<String, ContentValidationResult> fieldResults, {
    String? errorMessage,
  }) {
    return StructuredDataValidationResult(
      isValid: false,
      originalData: data,
      fieldResults: fieldResults,
      errorMessage: errorMessage ?? 'Invalid structured data',
    );
  }

  /// Creates a new [StructuredDataValidationResult] for cleaned structured data
  factory StructuredDataValidationResult.cleaned(
    Map<String, String> originalData,
    Map<String, String> cleanedData,
    Map<String, ContentValidationResult> fieldResults,
  ) {
    return StructuredDataValidationResult(
      isValid: true,
      originalData: originalData,
      cleanedData: cleanedData,
      fieldResults: fieldResults,
    );
  }
}

/// Utility class for validating and cleaning structured data
class StructuredDataValidator {
  /// Logger for logging structured data operations
  final Logger? logger;

  /// Content validator for validating individual fields
  final ContentValidator contentValidator;

  /// Required fields that must be present and non-empty
  final List<String> requiredFields;

  /// Creates a new [StructuredDataValidator] with the given parameters
  StructuredDataValidator({
    this.logger,
    ContentValidator? contentValidator,
    this.requiredFields = const [],
  }) : contentValidator = contentValidator ?? ContentValidator();

  /// Validates a single structured data item
  StructuredDataValidationResult validateStructuredData(
    Map<String, String> data,
  ) {
    // Check for required fields
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field]!.isEmpty) {
        return StructuredDataValidationResult.invalid(
          data,
          {},
          errorMessage: 'Missing required field: $field',
        );
      }
    }

    // Validate each field
    final fieldResults = <String, ContentValidationResult>{};
    var needsCleaning = false;

    for (final entry in data.entries) {
      final field = entry.key;
      final content = entry.value;

      final result = contentValidator.validateContent(content);
      fieldResults[field] = result;

      if (result.cleanedContent != null) {
        needsCleaning = true;
      }
    }

    // Check if any fields are invalid
    final invalidFields = fieldResults.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.key)
        .toList();

    if (invalidFields.isNotEmpty) {
      return StructuredDataValidationResult.invalid(
        data,
        fieldResults,
        errorMessage: 'Invalid fields: ${invalidFields.join(', ')}',
      );
    }

    // Clean the data if needed
    if (needsCleaning) {
      final cleanedData = <String, String>{};

      for (final entry in data.entries) {
        final field = entry.key;
        final content = entry.value;
        final result = fieldResults[field]!;

        cleanedData[field] = result.cleanedContent ?? content;
      }

      return StructuredDataValidationResult.cleaned(
        data,
        cleanedData,
        fieldResults,
      );
    }

    return StructuredDataValidationResult.valid(data, fieldResults);
  }

  /// Validates a list of structured data items
  List<StructuredDataValidationResult> validateStructuredDataList(
    List<Map<String, String>> dataList,
  ) {
    return dataList.map(validateStructuredData).toList();
  }

  /// Cleans a single structured data item
  Map<String, String> cleanStructuredData(Map<String, String> data) {
    final cleanedData = <String, String>{};

    for (final entry in data.entries) {
      cleanedData[entry.key] = contentValidator.cleanContent(entry.value);
    }

    return cleanedData;
  }

  /// Cleans a list of structured data items
  List<Map<String, String>> cleanStructuredDataList(
    List<Map<String, String>> dataList,
  ) {
    return dataList.map(cleanStructuredData).toList();
  }

  /// Filters out invalid items from a list of structured data items
  List<Map<String, String>> filterValidItems(
    List<Map<String, String>> dataList,
  ) {
    final results = validateStructuredDataList(dataList);
    final validItems = <Map<String, String>>[];

    for (var i = 0; i < results.length; i++) {
      final result = results[i];

      if (result.isValid) {
        validItems.add(result.cleanedData ?? result.originalData);
      }
    }

    return validItems;
  }

  /// Normalizes field names in structured data
  Map<String, String> normalizeFieldNames(
    Map<String, String> data, {
    Map<String, String>? fieldMappings,
  }) {
    if (fieldMappings == null || fieldMappings.isEmpty) {
      return data;
    }

    final normalizedData = <String, String>{};

    for (final entry in data.entries) {
      final field = entry.key;
      final content = entry.value;

      final normalizedField = fieldMappings[field] ?? field;
      normalizedData[normalizedField] = content;
    }

    return normalizedData;
  }

  /// Normalizes field names in a list of structured data items
  List<Map<String, String>> normalizeFieldNamesList(
    List<Map<String, String>> dataList, {
    Map<String, String>? fieldMappings,
  }) {
    return dataList
        .map((data) => normalizeFieldNames(data, fieldMappings: fieldMappings))
        .toList();
  }
}
