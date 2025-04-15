/// Base class for all proxy-related errors
abstract class ProxyError implements Exception {
  /// The error message
  final String message;

  /// Creates a new [ProxyError]
  const ProxyError(this.message);

  @override
  String toString() => message;
}

/// Error thrown when no proxies are available
class NoProxiesAvailableError extends ProxyError {
  /// Creates a new [NoProxiesAvailableError]
  const NoProxiesAvailableError([super.message = 'No proxies available']);
}

/// Error thrown when a proxy connection fails
class ProxyConnectionError extends ProxyError {
  /// The host that was being connected to
  final String host;

  /// The port that was being connected to
  final int port;

  /// The underlying error
  final Object? error;

  /// Creates a new [ProxyConnectionError]
  const ProxyConnectionError({
    required this.host,
    required this.port,
    this.error,
    String? message,
  }) : super(message ?? 'Failed to connect to proxy at $host:$port');
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
    String? message,
  }) : super(message ?? 'Failed to authenticate with proxy at $host:$port');
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
    String? message,
  }) : super(message ?? 'Proxy at $host:$port timed out after ${timeoutMs}ms');
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
    String? message,
  }) : super(
         message ??
             'Proxy at $host:$port was blocked${targetUrl != null ? ' by $targetUrl' : ''}',
       );
}

/// Error thrown when all proxies have been exhausted
class AllProxiesExhaustedError extends ProxyError {
  /// The number of proxies that were tried
  final int attemptedCount;

  /// Creates a new [AllProxiesExhaustedError]
  const AllProxiesExhaustedError({
    required this.attemptedCount,
    String? message,
  }) : super(
         message ??
             'All $attemptedCount proxies have been exhausted without success',
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
    String? message,
  }) : super(message ?? 'Proxy at $host:$port failed validation: $reason');
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
    String? message,
  }) : super(
         message ??
             'Proxy at $host:$port was rate limited${targetUrl != null ? ' by $targetUrl' : ''}${retryAfterSeconds != null ? '. Retry after $retryAfterSeconds seconds' : ''}',
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
    String? message,
  }) : super(
         message ??
             'Proxy at $host:$port returned an invalid response${statusCode != null ? ' with status code $statusCode' : ''}',
       );
}
