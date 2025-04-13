import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../features/proxy_management/domain/entities/proxy.dart';
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

  /// The current proxy being used
  Proxy? _currentProxy;

  /// Creates a new [ProxyHttpClient] with the given parameters
  ProxyHttpClient({
    http.Client? inner,
    required ProxyManager proxyManager,
    bool useValidatedProxies = true,
    bool rotateProxies = true,
  }) : _inner = inner ?? http.Client(),
       _proxyManager = proxyManager,
       _useValidatedProxies = useValidatedProxies,
       _rotateProxies = rotateProxies;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
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
          // If still no proxies, use direct connection
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

    // Convert the request to an HttpClientRequest
    final url = request.url;
    final httpRequest = await httpClient.openUrl(request.method, url);

    // Copy headers
    request.headers.forEach((name, value) {
      httpRequest.headers.set(name, value);
    });

    // Copy the body
    if (request is http.Request) {
      httpRequest.write(request.body);
    }

    // Send the request
    final httpResponse = await httpRequest.close();

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

    // Close the client
    httpClient.close();

    return response;
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
