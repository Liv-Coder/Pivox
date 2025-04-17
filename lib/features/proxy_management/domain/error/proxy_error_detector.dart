import 'proxy_error.dart';
import 'proxy_error_type.dart';
import '../../domain/entities/proxy.dart';

/// Utility class for detecting and categorizing proxy errors
class ProxyErrorDetector {
  /// Detects the type of error from an exception
  static ProxyErrorType detectErrorType(Object error) {
    final errorString = error.toString().toLowerCase();

    // Connection errors
    if (errorString.contains('connection refused') ||
        errorString.contains('failed to connect') ||
        errorString.contains('connection failed') ||
        errorString.contains('socket error')) {
      return ProxyErrorType.connectionError;
    }

    // Connection reset
    if (errorString.contains('connection reset') ||
        errorString.contains('connection closed') ||
        errorString.contains('broken pipe')) {
      return ProxyErrorType.connectionReset;
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return ProxyErrorType.connectionTimeout;
    }

    // Invalid content length
    if (errorString.contains('invalid content length') ||
        errorString.contains('content-length')) {
      return ProxyErrorType.invalidContentLength;
    }

    // Invalid headers
    if (errorString.contains('invalid header') ||
        errorString.contains('malformed header')) {
      return ProxyErrorType.invalidHeaders;
    }

    // DNS errors
    if (errorString.contains('dns') ||
        errorString.contains('lookup') ||
        errorString.contains('resolve') ||
        errorString.contains('unknown host')) {
      return ProxyErrorType.dnsError;
    }

    // SSL errors
    if (errorString.contains('ssl') ||
        errorString.contains('tls') ||
        errorString.contains('certificate') ||
        errorString.contains('handshake')) {
      return ProxyErrorType.sslError;
    }

    // Authentication errors
    if (errorString.contains('authentication') ||
        errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return ProxyErrorType.authenticationFailed;
    }

    // HTTP errors
    if (errorString.contains('http error') ||
        errorString.contains('status code') ||
        errorString.contains('403') ||
        errorString.contains('429') ||
        errorString.contains('500')) {
      return ProxyErrorType.httpError;
    }

    // Rate limiting
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429')) {
      return ProxyErrorType.rateLimited;
    }

    // Blocked
    if (errorString.contains('blocked') ||
        errorString.contains('banned') ||
        errorString.contains('forbidden') ||
        errorString.contains('403')) {
      return ProxyErrorType.blocked;
    }

    // Default to unknown
    return ProxyErrorType.unknown;
  }

  /// Creates an appropriate ProxyError from an exception
  static ProxyError createProxyError(
    Object error,
    Proxy proxy, {
    String? targetUrl,
  }) {
    final errorType = detectErrorType(error);
    final host = proxy.ip;
    final port = proxy.port;

    switch (errorType) {
      case ProxyErrorType.connectionError:
        return ProxyConnectionError(host: host, port: port, cause: error);
      case ProxyErrorType.connectionReset:
        return ProxyConnectionError.connectionReset(
          host: host,
          port: port,
          cause: error,
        );
      case ProxyErrorType.connectionTimeout:
        return ProxyTimeoutError(
          host: host,
          port: port,
          timeoutMs: 10000, // Default timeout
          cause: error,
        );
      case ProxyErrorType.invalidContentLength:
        return ProxyInvalidResponseError.invalidContentLength(
          host: host,
          port: port,
          cause: error,
        );
      case ProxyErrorType.invalidHeaders:
        return ProxyInvalidResponseError.invalidHeaders(
          host: host,
          port: port,
          cause: error,
        );
      case ProxyErrorType.dnsError:
        return ProxyConnectionError.dnsError(
          host: host,
          port: port,
          cause: error,
        );
      case ProxyErrorType.sslError:
        return ProxyConnectionError.sslError(
          host: host,
          port: port,
          cause: error,
        );
      case ProxyErrorType.authenticationFailed:
        return ProxyAuthenticationError(host: host, port: port, cause: error);
      case ProxyErrorType.httpError:
        // Try to extract status code
        final errorString = error.toString();
        final statusCodeMatch = RegExp(
          r'status code (\d+)',
        ).firstMatch(errorString);
        final statusCode =
            statusCodeMatch != null
                ? int.tryParse(statusCodeMatch.group(1) ?? '')
                : null;

        return ProxyInvalidResponseError.httpError(
          host: host,
          port: port,
          statusCode: statusCode ?? 500,
          cause: error,
        );
      case ProxyErrorType.rateLimited:
        // Try to extract retry-after
        final errorString = error.toString();
        final retryAfterMatch = RegExp(
          r'retry after (\d+)',
        ).firstMatch(errorString);
        final retryAfter =
            retryAfterMatch != null
                ? int.tryParse(retryAfterMatch.group(1) ?? '')
                : null;

        return ProxyRateLimitedError(
          host: host,
          port: port,
          targetUrl: targetUrl,
          retryAfterSeconds: retryAfter,
          cause: error,
        );
      case ProxyErrorType.blocked:
        return ProxyBlockedError(
          host: host,
          port: port,
          targetUrl: targetUrl,
          cause: error,
        );
      case ProxyErrorType.validationFailed:
        return ProxyValidationError(
          host: host,
          port: port,
          reason: error.toString(),
          cause: error,
        );
      case ProxyErrorType.noProxiesAvailable:
        return NoProxiesAvailableError('No proxies available', error);
      case ProxyErrorType.invalidResponse:
        return ProxyInvalidResponseError(host: host, port: port, cause: error);
      case ProxyErrorType.unknown:
        return ProxyConnectionError(
          host: host,
          port: port,
          message: 'Unknown proxy error: ${error.toString()}',
          cause: error,
          type: ProxyErrorType.unknown,
        );
    }
  }
}
