import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../../../features/proxy_management/domain/entities/proxy.dart';
import '../../../features/proxy_management/domain/entities/proxy_filter_options.dart';
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

  /// Whether to enable debug logging
  final bool _enableLogging;

  /// Internal logging method
  void _log(String message) {
    if (_enableLogging && kDebugMode) {
      debugPrint('[ProxyInterceptor] $message');
    }
  }

  /// Creates a new [ProxyInterceptor] with the given parameters
  ProxyInterceptor({
    required ProxyManager proxyManager,
    bool useValidatedProxies = true,
    bool rotateProxies = true,
    int maxRetries = 3,
    bool enableLogging = true,
  }) : _proxyManager = proxyManager,
       _useValidatedProxies = useValidatedProxies,
       _rotateProxies = rotateProxies,
       _maxRetries = maxRetries,
       _enableLogging = enableLogging;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Start timing the request
    options.extra['requestStartTime'] = DateTime.now().millisecondsSinceEpoch;

    if (_rotateProxies || _currentProxy == null) {
      try {
        _currentProxy = _proxyManager.getNextProxy(
          validated: _useValidatedProxies,
        );
      } catch (e) {
        // If no proxies are available, try to fetch some
        try {
          if (_useValidatedProxies) {
            await _proxyManager.fetchValidatedProxies(
              options: ProxyFilterOptions(count: 20, onlyHttps: true),
              onProgress: (completed, total) {
                _log('Validated $completed of $total proxies');
              },
            );
          } else {
            await _proxyManager.fetchProxies(
              options: ProxyFilterOptions(count: 20),
            );
          }

          try {
            _currentProxy = _proxyManager.getNextProxy(
              validated: _useValidatedProxies,
            );
          } catch (e) {
            // If still no validated proxies, try unvalidated as fallback
            if (_useValidatedProxies) {
              _log('No validated proxies available, trying unvalidated...');
              try {
                _currentProxy = _proxyManager.getNextProxy(validated: false);
                _log('Using unvalidated proxy as fallback');
              } catch (_) {
                // If still no proxies, proceed without a proxy
                _log('No proxies available at all, proceeding without proxy');
                handler.next(options);
                return;
              }
            } else {
              // If still no proxies, proceed without a proxy
              _log('No proxies available at all, proceeding without proxy');
              handler.next(options);
              return;
            }
          }
        } catch (fetchError) {
          // If fetching fails, proceed without a proxy
          _log('Error fetching proxies: $fetchError');
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

    // Store the proxy for later use in response/error handlers
    options.extra['currentProxy'] = proxy;

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
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Calculate response time if not already set
    int responseTime = 0;
    if (response.extra.containsKey('responseTime')) {
      responseTime = response.extra['responseTime'] as int? ?? 0;
    } else if (response.extra.containsKey('requestStartTime')) {
      final startTime = response.extra['requestStartTime'] as int;
      final endTime = DateTime.now().millisecondsSinceEpoch;
      responseTime = endTime - startTime;
      response.extra['responseTime'] = responseTime;
    }

    // Record successful proxy usage
    if (_currentProxy != null) {
      _log('Proxy request successful, response time: ${responseTime}ms');
      await _proxyManager.recordSuccess(_currentProxy!, responseTime);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Record proxy failure if it's a proxy-related error
    if (_isProxyError(err) && _currentProxy != null) {
      await _proxyManager.recordFailure(_currentProxy!);
    }

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
        final stopwatch = Stopwatch()..start();

        try {
          final response = await dio.fetch(options);
          stopwatch.stop();

          // Add response time to the response
          response.extra['responseTime'] = stopwatch.elapsedMilliseconds;

          handler.resolve(response);
          return;
        } catch (e) {
          // If retry fails, record the failure
          if (_currentProxy != null) {
            await _proxyManager.recordFailure(_currentProxy!);
          }
          // Proceed with the original error
        }
      } catch (e) {
        // If getting a new proxy fails, proceed with the original error
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
