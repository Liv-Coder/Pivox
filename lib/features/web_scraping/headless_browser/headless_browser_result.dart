import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Result of a headless browser operation
class HeadlessBrowserResult {
  /// Whether the operation was successful
  final bool success;

  /// HTML content of the page
  final String? html;

  /// Extracted data from the page
  final Map<String, dynamic>? data;

  /// Screenshot of the page
  final Uint8List? screenshot;

  /// Error message if the operation failed
  final String? errorMessage;

  /// HTTP status code of the response
  final int? statusCode;

  /// Time taken to complete the operation in milliseconds
  final int? elapsedMillis;

  /// Creates a new [HeadlessBrowserResult] instance
  const HeadlessBrowserResult({
    required this.success,
    this.html,
    this.data,
    this.screenshot,
    this.errorMessage,
    this.statusCode,
    this.elapsedMillis,
  });

  /// Creates a successful result
  factory HeadlessBrowserResult.success({
    String? html,
    Map<String, dynamic>? data,
    Uint8List? screenshot,
    int? statusCode,
    int? elapsedMillis,
  }) {
    return HeadlessBrowserResult(
      success: true,
      html: html,
      data: data,
      screenshot: screenshot,
      statusCode: statusCode,
      elapsedMillis: elapsedMillis,
    );
  }

  /// Creates a failed result
  factory HeadlessBrowserResult.failure({
    String? errorMessage,
    int? statusCode,
    int? elapsedMillis,
  }) {
    return HeadlessBrowserResult(
      success: false,
      errorMessage: errorMessage ?? 'Unknown error',
      statusCode: statusCode,
      elapsedMillis: elapsedMillis,
    );
  }

  /// Creates a copy of this result with the given fields replaced
  HeadlessBrowserResult copyWith({
    bool? success,
    String? html,
    Map<String, dynamic>? data,
    Uint8List? screenshot,
    String? errorMessage,
    int? statusCode,
    int? elapsedMillis,
  }) {
    return HeadlessBrowserResult(
      success: success ?? this.success,
      html: html ?? this.html,
      data: data ?? this.data,
      screenshot: screenshot ?? this.screenshot,
      errorMessage: errorMessage ?? this.errorMessage,
      statusCode: statusCode ?? this.statusCode,
      elapsedMillis: elapsedMillis ?? this.elapsedMillis,
    );
  }

  @override
  String toString() {
    return 'HeadlessBrowserResult{success: $success, '
        'html: ${html != null ? '${html!.length} chars' : 'null'}, '
        'data: $data, '
        'screenshot: ${screenshot != null ? '${screenshot!.length} bytes' : 'null'}, '
        'errorMessage: $errorMessage, '
        'statusCode: $statusCode, '
        'elapsedMillis: $elapsedMillis}';
  }
}
