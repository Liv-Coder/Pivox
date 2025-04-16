import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../../../features/proxy_management/domain/entities/proxy.dart';
import '../../../features/proxy_management/domain/entities/proxy_filter_options.dart';
import '../../../features/proxy_management/presentation/managers/proxy_manager.dart';

/// HTTP client with proxy support
class ProxyHttpClient extends http.BaseClient {
  /// The underlying HTTP client
  final http.Client _inner;

  /// The proxy manager for getting proxies
  final ProxyManager _proxyManager;

  /// Whether to use validated proxies
  final bool _useValidatedProxies;

  /// Whether to rotate proxies on each request
  final bool _rotateProxies;

  /// Whether to enable debug logging
  final bool _enableLogging;

  /// The current proxy being used
  Proxy? _currentProxy;

  /// Internal logging method
  void _log(String message) {
    if (_enableLogging && kDebugMode) {
      debugPrint('[ProxyHttpClient] $message');
    }
  }

  /// Creates a new [ProxyHttpClient] with the given parameters
  ProxyHttpClient({
    http.Client? inner,
    required ProxyManager proxyManager,
    bool useValidatedProxies = true,
    bool rotateProxies = true,
    bool enableLogging = true,
  }) : _inner = inner ?? http.Client(),
       _proxyManager = proxyManager,
       _useValidatedProxies = useValidatedProxies,
       _rotateProxies = rotateProxies,
       _enableLogging = enableLogging;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Try to get a proxy with fallback mechanisms
    if (_rotateProxies || _currentProxy == null) {
      try {
        // First try to get a validated proxy if required
        _currentProxy = _proxyManager.getNextProxy(
          validated: _useValidatedProxies,
        );
      } catch (e) {
        // If no proxies are available, try to fetch some
        try {
          // Log the issue
          _log('No proxies available, fetching new ones...');

          // Try to fetch and validate new proxies
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

          // Try to get a proxy again
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
                // If still no proxies, use direct connection
                _log('No proxies available at all, using direct connection');
                return _inner.send(request);
              }
            } else {
              // If still no proxies, use direct connection
              _log('No proxies available at all, using direct connection');
              return _inner.send(request);
            }
          }
        } catch (fetchError) {
          // If fetching fails, use direct connection
          _log('Error fetching proxies: $fetchError');
          return _inner.send(request);
        }
      }
    }

    // Set up the proxy
    final proxy = _currentProxy!;
    final proxyUrl = '${proxy.ip}:${proxy.port}';

    // Create a new HttpClient with the proxy
    final httpClient = HttpClient();
    httpClient.findProxy = (uri) => 'PROXY $proxyUrl';

    // Set up authentication if needed
    if (proxy.isAuthenticated) {
      httpClient.authenticate = (Uri url, String scheme, String? realm) {
        httpClient.addCredentials(
          url,
          realm ?? '',
          HttpClientBasicCredentials(proxy.username!, proxy.password!),
        );
        return Future.value(true);
      };
    }

    // Record the proxy usage for analytics and scoring
    _log('Using proxy: $proxyUrl');

    // Convert the request to an HttpClientRequest
    final url = request.url;
    final stopwatch = Stopwatch()..start();

    try {
      _log('Opening connection to $url using proxy ${proxy.ip}:${proxy.port}');
      final httpRequest = await httpClient.openUrl(request.method, url);

      // Copy headers
      request.headers.forEach((name, value) {
        httpRequest.headers.set(name, value);
        _log('Setting header: $name: $value');
      });

      // Copy the body
      if (request is http.Request) {
        _log('Writing request body (${request.body.length} bytes)');
        httpRequest.write(request.body);
      }

      // Send the request
      _log('Sending request to $url');
      final httpResponse = await httpRequest.close();
      stopwatch.stop();

      _log(
        'Received response: ${httpResponse.statusCode} ${httpResponse.reasonPhrase}',
      );

      // Record successful proxy usage
      if (_currentProxy != null) {
        _log(
          'Proxy request successful, response time: ${stopwatch.elapsedMilliseconds}ms',
        );
        await _proxyManager.recordSuccess(
          _currentProxy!,
          stopwatch.elapsedMilliseconds,
        );
      }

      // Convert the response to a StreamedResponse
      final headers = <String, String>{};
      httpResponse.headers.forEach((name, values) {
        headers[name] = values.join(',');
      });

      final response = http.StreamedResponse(
        httpResponse,
        httpResponse.statusCode,
        contentLength: httpResponse.contentLength,
        request: request,
        headers: headers,
        isRedirect: httpResponse.isRedirect,
        persistentConnection: httpResponse.persistentConnection,
        reasonPhrase: httpResponse.reasonPhrase,
      );

      return response;
    } catch (e) {
      // Record proxy failure
      if (_currentProxy != null) {
        _log('Proxy request failed: $e');
        try {
          await _proxyManager.recordFailure(_currentProxy!);
        } catch (recordError) {
          _log('Error recording proxy failure: $recordError');
        }
      }

      // If proxy fails, try direct connection
      _log('Falling back to direct connection due to error: $e');
      try {
        return _inner.send(request);
      } catch (directError) {
        _log('Direct connection also failed: $directError');
        // Re-throw the original error if direct connection also fails
        rethrow;
      }
    } finally {
      // Close the client
      try {
        httpClient.close();
      } catch (e) {
        _log('Error closing HTTP client: $e');
      }
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  /// The current proxy being used (can be set directly)
  Proxy? currentProxy;

  /// Updates the current proxy
  void setProxy(Proxy? proxy) {
    _currentProxy = proxy;
    currentProxy = proxy;
  }
}
