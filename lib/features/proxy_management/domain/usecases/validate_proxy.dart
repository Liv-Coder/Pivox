import '../entities/proxy.dart';
import '../repositories/proxy_repository.dart';

/// Use case for validating a proxy
class ValidateProxy {
  /// Repository for proxy management
  final ProxyRepository repository;

  /// Creates a new [ValidateProxy] use case with the given [repository]
  const ValidateProxy(this.repository);

  /// Executes the use case to validate a proxy
  /// 
  /// [proxy] is the proxy to validate
  /// [testUrl] is the URL to use for testing
  /// [timeout] is the timeout in milliseconds
  Future<bool> call(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
  }) {
    return repository.validateProxy(
      proxy,
      testUrl: testUrl,
      timeout: timeout,
    );
  }
}
