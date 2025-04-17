/// Options for proxy validation
class ProxyValidationOptions {
  /// The URL to use for testing the proxy
  final String? testUrl;

  /// The timeout in milliseconds
  final int timeout;

  /// Whether to update the proxy's score based on the validation result
  final bool updateScore;

  /// Whether to validate HTTPS support
  final bool validateHttps;

  /// Whether to validate SOCKS support
  final bool validateSocks;

  /// Whether to validate WebSocket support
  final bool validateWebsockets;

  /// Whether to log validation errors
  final bool logErrors;

  /// Whether to categorize errors by type
  final bool categorizeErrors;

  /// Creates a new [ProxyValidationOptions] with the given parameters
  const ProxyValidationOptions({
    this.testUrl,
    this.timeout = 10000,
    this.updateScore = true,
    this.validateHttps = false,
    this.validateSocks = false,
    this.validateWebsockets = false,
    this.logErrors = true,
    this.categorizeErrors = true,
  });

  /// Creates a copy of this [ProxyValidationOptions] with the given parameters
  ProxyValidationOptions copyWith({
    String? testUrl,
    int? timeout,
    bool? updateScore,
    bool? validateHttps,
    bool? validateSocks,
    bool? validateWebsockets,
    bool? logErrors,
    bool? categorizeErrors,
  }) {
    return ProxyValidationOptions(
      testUrl: testUrl ?? this.testUrl,
      timeout: timeout ?? this.timeout,
      updateScore: updateScore ?? this.updateScore,
      validateHttps: validateHttps ?? this.validateHttps,
      validateSocks: validateSocks ?? this.validateSocks,
      validateWebsockets: validateWebsockets ?? this.validateWebsockets,
      logErrors: logErrors ?? this.logErrors,
      categorizeErrors: categorizeErrors ?? this.categorizeErrors,
    );
  }
}
