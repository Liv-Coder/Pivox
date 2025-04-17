import 'proxy_error_type.dart';

/// Base class for all proxy-related errors
abstract class ProxyError implements Exception {
  /// The error message
  final String message;

  /// The error type
  final ProxyErrorType type;

  /// The underlying error that caused this error
  final Object? cause;

  /// Whether this error is retryable
  final bool isRetryable;

  /// Creates a new [ProxyError]
  const ProxyError(
    this.message, {
    required this.type,
    this.cause,
    bool? isRetryable,
  }) : isRetryable = isRetryable ?? false;

  @override
  String toString() {
    final buffer = StringBuffer('${type.description}: $message');

    if (cause != null) {
      buffer.write(' (Cause: $cause)');
    }

    return buffer.toString();
  }
}

/// Error thrown when no proxies are available
class NoProxiesAvailableError extends ProxyError {
  /// Creates a new [NoProxiesAvailableError]
  const NoProxiesAvailableError([
    super.message = 'No proxies available',
    Object? cause,
  ]) : super(
         type: ProxyErrorType.noProxiesAvailable,
         cause: cause,
         isRetryable: false,
       );
}

/// Error thrown when a proxy connection fails
class ProxyConnectionError extends ProxyError {
  /// The host that was being connected to
  final String host;

  /// The port that was being connected to
  final int port;

  /// Creates a new [ProxyConnectionError]
  const ProxyConnectionError({
    required this.host,
    required this.port,
    Object? cause,
    String? message,
    ProxyErrorType type = ProxyErrorType.connectionError,
    bool? isRetryable,
  }) : super(
         message ?? 'Failed to connect to proxy at $host:$port',
         type: type,
         cause: cause,
         isRetryable: isRetryable,
       );

  /// Creates a new [ProxyConnectionError] for a connection reset
  factory ProxyConnectionError.connectionReset({
    required String host,
    required int port,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) {
    return ProxyConnectionError(
      host: host,
      port: port,
      cause: cause,
      message: message ?? 'Connection reset by proxy at $host:$port',
      type: ProxyErrorType.connectionReset,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ProxyConnectionError] for a DNS error
  factory ProxyConnectionError.dnsError({
    required String host,
    required int port,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) {
    return ProxyConnectionError(
      host: host,
      port: port,
      cause: cause,
      message: message ?? 'DNS resolution failed for proxy at $host:$port',
      type: ProxyErrorType.dnsError,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ProxyConnectionError] for an SSL error
  factory ProxyConnectionError.sslError({
    required String host,
    required int port,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) {
    return ProxyConnectionError(
      host: host,
      port: port,
      cause: cause,
      message: message ?? 'SSL/TLS error with proxy at $host:$port',
      type: ProxyErrorType.sslError,
      isRetryable: isRetryable,
    );
  }
}

/// Error thrown when a proxy authentication fails
class ProxyAuthenticationError extends ProxyError {
  /// The host that was being authenticated with
  final String host;

  /// The port that was being authenticated with
  final int port;

  /// Creates a new [ProxyAuthenticationError]
  const ProxyAuthenticationError({
    required this.host,
    required this.port,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) : super(
         message ?? 'Failed to authenticate with proxy at $host:$port',
         type: ProxyErrorType.authenticationFailed,
         cause: cause,
         isRetryable: isRetryable ?? false,
       );
}

/// Error thrown when a proxy times out
class ProxyTimeoutError extends ProxyError {
  /// The host that timed out
  final String host;

  /// The port that timed out
  final int port;

  /// The timeout duration in milliseconds
  final int timeoutMs;

  /// Creates a new [ProxyTimeoutError]
  const ProxyTimeoutError({
    required this.host,
    required this.port,
    required this.timeoutMs,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) : super(
         message ?? 'Proxy at $host:$port timed out after ${timeoutMs}ms',
         type: ProxyErrorType.connectionTimeout,
         cause: cause,
         isRetryable: isRetryable,
       );
}

/// Error thrown when a proxy is blocked or banned
class ProxyBlockedError extends ProxyError {
  /// The host that was blocked
  final String host;

  /// The port that was blocked
  final int port;

  /// The target URL that blocked the proxy
  final String? targetUrl;

  /// Creates a new [ProxyBlockedError]
  const ProxyBlockedError({
    required this.host,
    required this.port,
    this.targetUrl,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) : super(
         message ??
             'Proxy at $host:$port was blocked${targetUrl != null ? ' by $targetUrl' : ''}',
         type: ProxyErrorType.blocked,
         cause: cause,
         isRetryable: isRetryable,
       );
}

/// Error thrown when all proxies have been exhausted
class AllProxiesExhaustedError extends ProxyError {
  /// The number of proxies that were tried
  final int attemptedCount;

  /// Creates a new [AllProxiesExhaustedError]
  const AllProxiesExhaustedError({
    required this.attemptedCount,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) : super(
         message ??
             'All $attemptedCount proxies have been exhausted without success',
         type: ProxyErrorType.noProxiesAvailable,
         cause: cause,
         isRetryable: isRetryable ?? false,
       );
}

/// Error thrown when a proxy validation fails
class ProxyValidationError extends ProxyError {
  /// The host that failed validation
  final String host;

  /// The port that failed validation
  final int port;

  /// The reason for the validation failure
  final String reason;

  /// Creates a new [ProxyValidationError]
  const ProxyValidationError({
    required this.host,
    required this.port,
    required this.reason,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) : super(
         message ?? 'Proxy at $host:$port failed validation: $reason',
         type: ProxyErrorType.validationFailed,
         cause: cause,
         isRetryable: isRetryable,
       );
}

/// Error thrown when a proxy is rate limited
class ProxyRateLimitedError extends ProxyError {
  /// The host that was rate limited
  final String host;

  /// The port that was rate limited
  final int port;

  /// The target URL that rate limited the proxy
  final String? targetUrl;

  /// The retry-after time in seconds, if available
  final int? retryAfterSeconds;

  /// Creates a new [ProxyRateLimitedError]
  const ProxyRateLimitedError({
    required this.host,
    required this.port,
    this.targetUrl,
    this.retryAfterSeconds,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) : super(
         message ??
             'Proxy at $host:$port was rate limited${targetUrl != null ? ' by $targetUrl' : ''}${retryAfterSeconds != null ? '. Retry after $retryAfterSeconds seconds' : ''}',
         type: ProxyErrorType.rateLimited,
         cause: cause,
         isRetryable: isRetryable,
       );
}

/// Error thrown when a proxy returns an invalid response
class ProxyInvalidResponseError extends ProxyError {
  /// The host that returned the invalid response
  final String host;

  /// The port that returned the invalid response
  final int port;

  /// The status code of the response
  final int? statusCode;

  /// Creates a new [ProxyInvalidResponseError]
  const ProxyInvalidResponseError({
    required this.host,
    required this.port,
    this.statusCode,
    Object? cause,
    String? message,
    ProxyErrorType type = ProxyErrorType.invalidResponse,
    bool? isRetryable,
  }) : super(
         message ??
             'Proxy at $host:$port returned an invalid response${statusCode != null ? ' with status code $statusCode' : ''}',
         type: type,
         cause: cause,
         isRetryable: isRetryable,
       );

  /// Creates a new [ProxyInvalidResponseError] for invalid headers
  factory ProxyInvalidResponseError.invalidHeaders({
    required String host,
    required int port,
    int? statusCode,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) {
    return ProxyInvalidResponseError(
      host: host,
      port: port,
      statusCode: statusCode,
      cause: cause,
      message: message ?? 'Proxy at $host:$port returned invalid headers',
      type: ProxyErrorType.invalidHeaders,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ProxyInvalidResponseError] for invalid content length
  factory ProxyInvalidResponseError.invalidContentLength({
    required String host,
    required int port,
    int? statusCode,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) {
    return ProxyInvalidResponseError(
      host: host,
      port: port,
      statusCode: statusCode,
      cause: cause,
      message:
          message ?? 'Proxy at $host:$port returned invalid content length',
      type: ProxyErrorType.invalidContentLength,
      isRetryable: isRetryable,
    );
  }

  /// Creates a new [ProxyInvalidResponseError] for HTTP errors
  factory ProxyInvalidResponseError.httpError({
    required String host,
    required int port,
    required int statusCode,
    Object? cause,
    String? message,
    bool? isRetryable,
  }) {
    return ProxyInvalidResponseError(
      host: host,
      port: port,
      statusCode: statusCode,
      cause: cause,
      message:
          message ?? 'Proxy at $host:$port returned HTTP error $statusCode',
      type: ProxyErrorType.httpError,
      isRetryable: isRetryable ?? (statusCode >= 500 || statusCode == 429),
    );
  }
}
