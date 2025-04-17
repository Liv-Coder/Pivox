/// Exception types for web scraping
enum ScrapingExceptionType {
  /// Network error (e.g., connection refused, timeout)
  network,

  /// HTTP error (e.g., 404, 500)
  http,

  /// Parsing error (e.g., invalid HTML, JSON)
  parsing,

  /// Rate limiting error (e.g., 429 Too Many Requests)
  rateLimit,

  /// Authentication error (e.g., 401 Unauthorized)
  authentication,

  /// Permission error (e.g., 403 Forbidden)
  permission,

  /// Robots.txt disallowed
  robotsTxt,

  /// CAPTCHA detected
  captcha,

  /// Proxy error (e.g., proxy connection failed)
  proxy,

  /// Validation error (e.g., invalid input)
  validation,

  /// Unexpected error
  unexpected,

  /// Lazy loading error
  lazyLoading,

  /// Pagination error
  pagination,
}

/// Exception thrown when a scraping operation fails
class ScrapingException implements Exception {
  /// The error message
  final String message;

  /// The exception type
  final ScrapingExceptionType type;

  /// The original exception that caused this exception
  final dynamic originalException;

  /// The URL that was being scraped
  final String? url;

  /// The HTTP status code (if applicable)
  final int? statusCode;

  /// Whether this exception is retryable
  final bool isRetryable;

  /// Creates a new [ScrapingException] with the given parameters
  ScrapingException(
    this.message, {
    this.type = ScrapingExceptionType.unexpected,
    this.originalException,
    this.url,
    this.statusCode,
    this.isRetryable = true,
  });

  /// Creates a new [ScrapingException] for a network error
  factory ScrapingException.network(
    String message, {
    dynamic originalException,
    String? url,
    bool isRetryable = true,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.network,
      originalException: originalException,
      url: url,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for an HTTP error
  factory ScrapingException.http(
    String message, {
    dynamic originalException,
    String? url,
    int? statusCode,
    bool isRetryable = true,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.http,
      originalException: originalException,
      url: url,
      statusCode: statusCode,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a parsing error
  factory ScrapingException.parsing(
    String message, {
    dynamic originalException,
    String? url,
    bool isRetryable = false,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.parsing,
      originalException: originalException,
      url: url,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a rate limiting error
  factory ScrapingException.rateLimit(
    String message, {
    dynamic originalException,
    String? url,
    int? statusCode,
    bool isRetryable = true,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.rateLimit,
      originalException: originalException,
      url: url,
      statusCode: statusCode,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for an authentication error
  factory ScrapingException.authentication(
    String message, {
    dynamic originalException,
    String? url,
    int? statusCode,
    bool isRetryable = false,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.authentication,
      originalException: originalException,
      url: url,
      statusCode: statusCode,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a permission error
  factory ScrapingException.permission(
    String message, {
    dynamic originalException,
    String? url,
    int? statusCode,
    bool isRetryable = false,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.permission,
      originalException: originalException,
      url: url,
      statusCode: statusCode,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a robots.txt disallowed error
  factory ScrapingException.robotsTxt(
    String message, {
    dynamic originalException,
    String? url,
    bool isRetryable = false,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.robotsTxt,
      originalException: originalException,
      url: url,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a CAPTCHA detected error
  factory ScrapingException.captcha(
    String message, {
    dynamic originalException,
    String? url,
    bool isRetryable = false,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.captcha,
      originalException: originalException,
      url: url,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a proxy error
  factory ScrapingException.proxy(
    String message, {
    dynamic originalException,
    String? url,
    bool isRetryable = true,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.proxy,
      originalException: originalException,
      url: url,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a validation error
  factory ScrapingException.validation(
    String message, {
    dynamic originalException,
    String? url,
    bool isRetryable = false,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.validation,
      originalException: originalException,
      url: url,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a lazy loading error
  factory ScrapingException.lazyLoading(
    String message, {
    dynamic originalException,
    String? url,
    bool isRetryable = true,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.lazyLoading,
      originalException: originalException,
      url: url,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ScrapingException] for a pagination error
  factory ScrapingException.pagination(
    String message, {
    dynamic originalException,
    String? url,
    bool isRetryable = true,
  }) {
    return ScrapingException(
      message,
      type: ScrapingExceptionType.pagination,
      originalException: originalException,
      url: url,
      isRetryable: isRetryable,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('ScrapingException: $message');

    if (url != null) {
      buffer.write(' (URL: $url)');
    }

    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }

    if (originalException != null) {
      buffer.write(' (Cause: $originalException)');
    }

    return buffer.toString();
  }
}
