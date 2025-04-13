import 'dart:convert';
import 'package:dio/dio.dart';

import '../../../features/proxy_management/domain/entities/proxy.dart';
import '../../../features/proxy_management/presentation/managers/proxy_manager.dart';

/// Dio interceptor for proxy support
class ProxyInterceptor extends Interceptor {
  /// The proxy manager for getting proxies
  final ProxyManager _proxyManager;

  /// Whether to use validated proxies
  final bool _useValidatedProxies;

  /// Whether to rotate proxies on each request
  final bool _rotateProxies;

  /// The current proxy being used
  Proxy? _currentProxy;

  /// Maximum number of retry attempts
  final int _maxRetries;

  /// Current retry count
  int _retryCount = 0;

  /// Creates a new [ProxyInterceptor] with the given parameters
  ProxyInterceptor({
    required ProxyManager proxyManager,
    bool useValidatedProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
  }) : _proxyManager = proxyManager,
       _useValidatedProxies = useValidatedProxies,
       _rotateProxies = rotateProxies,
       _maxRetries = maxRetries;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_rotateProxies || _currentProxy == null) {
      try {
        _currentProxy = _proxyManager.getNextProxy(
          validated: _useValidatedProxies,
        );
      } catch (e) {
        // If no proxies are available, try to fetch some
        try {
          if (_useValidatedProxies) {
            await _proxyManager.fetchValidatedProxies();
          } else {
            await _proxyManager.fetchProxies();
          }

          _currentProxy = _proxyManager.getNextProxy(
            validated: _useValidatedProxies,
          );
        } catch (_) {
          // If still no proxies, proceed without a proxy
          handler.next(options);
          return;
        }
      }
    }

    // Set up the proxy
    final proxy = _currentProxy!;

    // Set proxy for Dio
    final proxyUrl = '${proxy.ip}:${proxy.port}';
    options.headers['proxy'] = proxyUrl;
    options.extra['proxy'] = proxyUrl;

    // Add authentication if needed
    if (proxy.isAuthenticated) {
      final auth =
          'Basic ${base64Encode(utf8.encode('${proxy.username}:${proxy.password}'))}';
      options.headers['Proxy-Authorization'] = auth;
      options.extra['proxyAuth'] = auth;
    }

    // Reset retry count for new requests
    _retryCount = 0;

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If the error is related to the proxy and we haven't exceeded max retries
    if (_isProxyError(err) && _retryCount < _maxRetries) {
      _retryCount++;

      // Try with a different proxy
      try {
        _currentProxy = _proxyManager.getNextProxy(
          validated: _useValidatedProxies,
        );

        // Retry the request with the new proxy
        final options = err.requestOptions;
        final proxy = _currentProxy!;
        options.headers['proxy'] = '${proxy.ip}:${proxy.port}';
        options.extra['proxy'] = '${proxy.ip}:${proxy.port}';

        // Create a new request
        final dio = Dio();
        final response = await dio.fetch(options);

        handler.resolve(response);
        return;
      } catch (e) {
        // If retry fails, proceed with the original error
      }
    }

    handler.next(err);
  }

  /// Checks if the error is related to the proxy
  bool _isProxyError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  /// The current proxy being used (can be set directly)
  Proxy? currentProxy;

  /// Updates the current proxy
  void setProxy(Proxy? proxy) {
    _currentProxy = proxy;
    currentProxy = proxy;
  }
}
