import 'package:dio/dio.dart';
import 'package:pivox/pivox.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing proxies
class ProxyService {
  /// Proxy manager instance
  late ProxyManager _proxyManager;

  /// HTTP client with proxy support
  late ProxyHttpClient _httpClient;

  /// Dio instance with proxy support
  late Dio _dio;

  /// Gets the proxy manager
  ProxyManager get proxyManager => _proxyManager;

  /// Gets the HTTP client
  ProxyHttpClient get httpClient => _httpClient;

  /// Gets the Dio instance
  Dio get dio => _dio;

  /// Initializes the proxy service
  Future<void> initialize() async {
    // Get a shared preferences instance to reuse
    final sharedPreferences = await SharedPreferences.getInstance();

    // Create a customized proxy manager
    _proxyManager =
        await Pivox.builder()
            .withSharedPreferences(sharedPreferences)
            .withMaxConcurrentValidations(10)
            .withAnalytics(true)
            .buildProxyManager();

    // Create an HTTP client with the proxy manager
    _httpClient = ProxyHttpClient(
      proxyManager: _proxyManager,
      useValidatedProxies: true,
      rotateProxies: true,
    );

    // Create a Dio instance with the proxy manager
    _dio =
        Dio()
          ..options.connectTimeout = const Duration(seconds: 30)
          ..options.receiveTimeout = const Duration(seconds: 30)
          ..interceptors.add(
            ProxyInterceptor(
              proxyManager: _proxyManager,
              useValidatedProxies: true,
              rotateProxies: true,
              maxRetries: 3,
            ),
          );
  }

  /// Fetches proxies with advanced filtering options
  Future<List<Proxy>> fetchProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(
      count: 20,
      onlyHttps: true,
    ),
  }) async {
    return _proxyManager.fetchProxies(options: options);
  }

  /// Fetches proxies with legacy parameters
  @Deprecated('Use fetchProxies with ProxyFilterOptions instead')
  Future<List<Proxy>> fetchProxiesLegacy({
    int count = 20,
    bool onlyHttps = true,
    List<String>? countries,
  }) async {
    return fetchProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
    );
  }

  /// Fetches validated proxies with advanced filtering options
  Future<List<Proxy>> fetchValidatedProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(
      count: 10,
      onlyHttps: true,
    ),
    void Function(int completed, int total)? onProgress,
  }) async {
    return _proxyManager.fetchValidatedProxies(
      options: options,
      onProgress: onProgress,
    );
  }

  /// Fetches validated proxies with legacy parameters
  @Deprecated('Use fetchValidatedProxies with ProxyFilterOptions instead')
  Future<List<Proxy>> fetchValidatedProxiesLegacy({
    int count = 10,
    bool onlyHttps = true,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) async {
    return fetchValidatedProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
      onProgress: onProgress,
    );
  }

  /// Makes an HTTP request using the proxy
  Future<String> makeHttpRequest(String url) async {
    final response = await _httpClient.get(Uri.parse(url));
    return response.body;
  }

  /// Makes a Dio request using the proxy
  Future<String> makeDioRequest(String url) async {
    final response = await _dio.get(url);
    return response.data.toString();
  }

  /// Validates a specific proxy
  Future<bool> validateProxy(Proxy proxy) async {
    return _proxyManager.validateSpecificProxy(
      proxy,
      timeout: 5000,
      updateScore: true,
    );
  }

  /// Disposes the service
  void dispose() {
    _httpClient.close();
    _dio.close();
  }

  /// Gets the current analytics data
  Future<ProxyAnalytics?> getAnalytics() async {
    return _proxyManager.getAnalytics();
  }

  /// Resets the analytics data
  Future<void> resetAnalytics() async {
    await _proxyManager.resetAnalytics();
  }
}
