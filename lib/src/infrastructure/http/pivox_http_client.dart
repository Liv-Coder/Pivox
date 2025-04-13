import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pivox/pivox.dart';

/// An HTTP client that uses Pivox for proxy rotation.
///
/// This client extends the standard Dart http.Client and automatically
/// routes requests through proxies managed by Pivox.
class PivoxHttpClient extends http.BaseClient {
  final PivoxClient _pivoxClient;
  final http.Client _innerClient;
  final int _maxRetries;
  final bool _closeInnerClient;

  /// Creates a new [PivoxHttpClient].
  ///
  /// [pivoxClient] is the Pivox client used to get proxies.
  /// [innerClient] is an optional HTTP client to use for making requests.
  /// [maxRetries] is the maximum number of retries if a request fails.
  /// [closeInnerClient] determines whether to close the inner client when this client is closed.
  PivoxHttpClient({
    required PivoxClient pivoxClient,
    http.Client? innerClient,
    int maxRetries = 3,
    bool closeInnerClient = true,
  })  : _pivoxClient = pivoxClient,
        _innerClient = innerClient ?? http.Client(),
        _maxRetries = maxRetries,
        _closeInnerClient = closeInnerClient;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    int retries = 0;
    Exception? lastException;

    while (retries <= _maxRetries) {
      final proxy = await _pivoxClient.getProxy();
      
      if (proxy == null) {
        // No proxies available, try with direct connection
        try {
          return await _innerClient.send(request);
        } catch (e) {
          if (retries >= _maxRetries) {
            rethrow;
          }
          retries++;
          continue;
        }
      }

      try {
        // Clone the request since we can't reuse it
        final clonedRequest = await _cloneRequest(request);
        
        // Add proxy headers for HTTP/HTTPS proxies
        if (proxy.type == ProxyType.http || proxy.type == ProxyType.https) {
          // Set proxy host and port
          clonedRequest.headers['Host'] = '${proxy.host}:${proxy.port}';
          
          // Add proxy authentication if provided
          if (proxy.username != null && proxy.password != null) {
            final auth = base64Encode('${proxy.username}:${proxy.password}'.codeUnits);
            clonedRequest.headers['Proxy-Authorization'] = 'Basic $auth';
          }
        }
        
        // For SOCKS proxies, we would need a different approach
        // This is a simplified implementation that doesn't fully support SOCKS
        
        // Send the request
        final response = await _innerClient.send(clonedRequest);
        
        // Check if the response indicates a proxy error
        if (response.statusCode == 407) { // Proxy Authentication Required
          await _pivoxClient.markProxyAsInactive(proxy);
          retries++;
          continue;
        }
        
        return response;
      } catch (e) {
        // Mark the proxy as inactive if the request fails
        await _pivoxClient.markProxyAsInactive(proxy);
        
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (retries >= _maxRetries) {
          break;
        }
        
        retries++;
      }
    }

    // If we've exhausted all retries, throw the last exception
    throw lastException ?? Exception('Failed to send request after $_maxRetries retries');
  }

  /// Clones a request so it can be sent again.
  Future<http.BaseRequest> _cloneRequest(http.BaseRequest request) async {
    final clone = http.Request(request.method, request.url);
    
    // Copy headers
    clone.headers.addAll(request.headers);
    
    // Copy body for POST/PUT requests
    if (request is http.Request) {
      clone.body = request.body;
    }
    
    return clone;
  }

  @override
  void close() {
    if (_closeInnerClient) {
      _innerClient.close();
    }
    super.close();
  }
}
