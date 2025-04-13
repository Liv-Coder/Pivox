import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pivox/pivox.dart';

/// Main client for the Pivox package.
///
/// This class provides the primary interface for getting proxies and
/// managing the proxy pool, with a focus on HTTP client integration.
class PivoxClient {
  final ProxyPoolManager _poolManager;
  final ProxyValidator _validator;

  /// Creates a new [PivoxClient].
  ///
  /// [poolManager] is responsible for managing the proxy pool and rotation.
  /// [validator] is used to validate proxies before returning them.
  PivoxClient({
    required ProxyPoolManager poolManager,
    required ProxyValidator validator,
  }) : _poolManager = poolManager,
       _validator = validator;

  /// Gets a valid proxy from the pool.
  ///
  /// Returns null if no valid proxies are available.
  /// This method will validate the proxy before returning it and
  /// will recursively try the next proxy if validation fails.
  Future<Proxy?> getProxy() async {
    final proxy = await _poolManager.getNextProxy();
    if (proxy == null) return null;

    final isValid = await _validator.validate(proxy);
    if (!isValid) {
      await _poolManager.markProxyAsInactive(proxy);
      return getProxy(); // Recursively try next proxy
    }

    return proxy;
  }

  /// Marks a proxy as inactive in the pool.
  ///
  /// This is useful when a proxy is found to be invalid or unresponsive
  /// during use, outside of the normal validation process.
  Future<void> markProxyAsInactive(Proxy proxy) async {
    await _poolManager.markProxyAsInactive(proxy);
  }

  /// Adds a new proxy to the pool.
  Future<void> addProxy(Proxy proxy) async {
    await _poolManager.addProxy(proxy);
  }

  /// Removes a proxy from the pool.
  Future<void> removeProxy(Proxy proxy) async {
    await _poolManager.removeProxy(proxy);
  }

  /// Gets all active proxies from the pool.
  Future<List<Proxy>> getActiveProxies() async {
    return _poolManager.getActiveProxies();
  }

  /// Creates an HTTP client that uses proxies from this Pivox client.
  ///
  /// This is a convenience method for creating a PivoxHttpClient.
  http.Client createHttpClient({int maxRetries = 3}) {
    return PivoxHttpClient(pivoxClient: this, maxRetries: maxRetries);
  }

  /// Formats a proxy as a connection string for use with HTTP clients.
  ///
  /// Returns a string in the format 'http://username:password@host:port'
  /// or 'http://host:port' if no authentication is provided.
  static String formatProxyUrl(Proxy proxy) {
    final scheme = proxy.type == ProxyType.https ? 'https' : 'http';

    if (proxy.username != null && proxy.password != null) {
      final auth = '${proxy.username}:${proxy.password}';
      return '$scheme://$auth@${proxy.host}:${proxy.port}';
    }

    return '$scheme://${proxy.host}:${proxy.port}';
  }

  /// Creates proxy authentication headers for use with HTTP clients.
  ///
  /// Returns a map containing the 'Proxy-Authorization' header if
  /// authentication is provided, or an empty map otherwise.
  static Map<String, String> createProxyAuthHeaders(Proxy proxy) {
    if (proxy.username != null && proxy.password != null) {
      final auth = base64Encode(
        '${proxy.username}:${proxy.password}'.codeUnits,
      );
      return {'Proxy-Authorization': 'Basic $auth'};
    }

    return {};
  }
}
