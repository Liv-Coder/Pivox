/// Base exception class for Pivox
abstract class PivoxException implements Exception {
  /// Error message
  final String message;

  /// Creates a new [PivoxException] with the given [message]
  const PivoxException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when proxy fetching fails
class ProxyFetchException extends PivoxException {
  /// Creates a new [ProxyFetchException] with the given [message]
  const ProxyFetchException(super.message);
}

/// Exception thrown when proxy validation fails
class ProxyValidationException extends PivoxException {
  /// Creates a new [ProxyValidationException] with the given [message]
  const ProxyValidationException(super.message);
}

/// Exception thrown when no valid proxies are available
class NoValidProxiesException extends PivoxException {
  /// Creates a new [NoValidProxiesException]
  const NoValidProxiesException() : super('No valid proxies available');
}

/// Exception thrown when proxy rotation fails
class ProxyRotationException extends PivoxException {
  /// Creates a new [ProxyRotationException] with the given [message]
  const ProxyRotationException(super.message);
}
