/// Types of proxy errors that can occur
enum ProxyErrorType {
  /// No proxies are available
  noProxiesAvailable,

  /// Connection to the proxy failed
  connectionError,

  /// Connection to the proxy timed out
  connectionTimeout,

  /// Connection was reset by the proxy
  connectionReset,

  /// Proxy returned invalid headers
  invalidHeaders,

  /// Proxy returned invalid content length
  invalidContentLength,

  /// Proxy returned invalid response
  invalidResponse,

  /// Proxy was blocked by the target website
  blocked,

  /// Proxy was rate limited by the target website
  rateLimited,

  /// Proxy authentication failed
  authenticationFailed,

  /// Proxy validation failed
  validationFailed,

  /// Proxy returned an HTTP error
  httpError,

  /// DNS resolution failed
  dnsError,

  /// SSL/TLS error
  sslError,

  /// Unknown error
  unknown,
}

/// Extension methods for ProxyErrorType
extension ProxyErrorTypeExtension on ProxyErrorType {
  /// Returns true if this error type is retryable
  bool get isRetryable {
    switch (this) {
      case ProxyErrorType.noProxiesAvailable:
      case ProxyErrorType.authenticationFailed:
        return false;
      case ProxyErrorType.connectionError:
      case ProxyErrorType.connectionTimeout:
      case ProxyErrorType.connectionReset:
      case ProxyErrorType.invalidHeaders:
      case ProxyErrorType.invalidContentLength:
      case ProxyErrorType.invalidResponse:
      case ProxyErrorType.blocked:
      case ProxyErrorType.rateLimited:
      case ProxyErrorType.validationFailed:
      case ProxyErrorType.httpError:
      case ProxyErrorType.dnsError:
      case ProxyErrorType.sslError:
      case ProxyErrorType.unknown:
        return true;
    }
  }

  /// Returns a human-readable description of this error type
  String get description {
    switch (this) {
      case ProxyErrorType.noProxiesAvailable:
        return 'No proxies available';
      case ProxyErrorType.connectionError:
        return 'Connection error';
      case ProxyErrorType.connectionTimeout:
        return 'Connection timeout';
      case ProxyErrorType.connectionReset:
        return 'Connection reset';
      case ProxyErrorType.invalidHeaders:
        return 'Invalid headers';
      case ProxyErrorType.invalidContentLength:
        return 'Invalid content length';
      case ProxyErrorType.invalidResponse:
        return 'Invalid response';
      case ProxyErrorType.blocked:
        return 'Proxy blocked';
      case ProxyErrorType.rateLimited:
        return 'Rate limited';
      case ProxyErrorType.authenticationFailed:
        return 'Authentication failed';
      case ProxyErrorType.validationFailed:
        return 'Validation failed';
      case ProxyErrorType.httpError:
        return 'HTTP error';
      case ProxyErrorType.dnsError:
        return 'DNS resolution error';
      case ProxyErrorType.sslError:
        return 'SSL/TLS error';
      case ProxyErrorType.unknown:
        return 'Unknown error';
    }
  }
}
