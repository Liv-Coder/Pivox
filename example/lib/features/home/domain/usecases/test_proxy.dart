import '../repositories/proxy_repository.dart';

/// Use case for testing a proxy connection
class TestProxy {
  /// The repository for proxy operations
  final HomeProxyRepository repository;

  /// Creates a new [TestProxy] use case
  TestProxy(this.repository);

  /// Executes the use case
  Future<String> call(String url) async {
    return repository.testProxyConnection(url);
  }
}
