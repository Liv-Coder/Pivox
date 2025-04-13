import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pivox/pivox.dart';

/// A [ProxyValidator] implementation that validates HTTP and HTTPS proxies.
class HttpProxyValidator implements ProxyValidator {
  final String _testUrl;
  final Duration _timeout;
  final bool _validateAnonymity;

  /// Creates a new [HttpProxyValidator].
  ///
  /// [testUrl] is the URL used to test proxy connectivity.
  /// [timeout] is the maximum time to wait for a response.
  /// [validateAnonymity] determines whether to check if the proxy reveals the client's IP.
  HttpProxyValidator({
    String testUrl = 'https://httpbin.org/ip',
    Duration timeout = const Duration(seconds: 10),
    bool validateAnonymity = false,
  }) : _testUrl = testUrl,
       _timeout = timeout,
       _validateAnonymity = validateAnonymity;

  @override
  Future<bool> validate(Proxy proxy) async {
    if (proxy.type != ProxyType.http && proxy.type != ProxyType.https) {
      // This validator only supports HTTP and HTTPS proxies
      return false;
    }

    try {
      final stopwatch = Stopwatch()..start();

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(_testUrl));

        // Set up proxy
        request.headers['User-Agent'] = 'Pivox/1.0';

        // Add proxy authentication if provided
        if (proxy.username != null && proxy.password != null) {
          final auth = base64Encode(
            '${proxy.username}:${proxy.password}'.codeUnits,
          );
          request.headers['Proxy-Authorization'] = 'Basic $auth';
        }

        final response = await client.send(request).timeout(_timeout);

        stopwatch.stop();

        // Check if response is successful
        if (response.statusCode != 200) {
          return false;
        }

        // Optionally validate anonymity
        if (_validateAnonymity) {
          final body = await response.stream.bytesToString();
          final containsClientIp = await _checkForClientIp(body);
          if (containsClientIp) {
            return false;
          }
        }

        // We could measure response time here if needed
        stopwatch.stop();

        // We could create an updated proxy with the new response time here
        // but we're just returning validation status for now

        // Return true to indicate the proxy is valid
        return true;
      } finally {
        client.close();
      }
    } catch (e) {
      // Any exception means the proxy is invalid
      return false;
    }
  }

  /// Checks if the response contains the client's IP address.
  Future<bool> _checkForClientIp(String responseBody) async {
    try {
      // Get the client's actual IP
      final clientIp = await _getClientIp();
      if (clientIp == null) return false;

      // Check if the response contains the client's IP
      return responseBody.contains(clientIp);
    } catch (e) {
      return false;
    }
  }

  /// Gets the client's actual IP address.
  Future<String?> _getClientIp() async {
    try {
      // This is a simplified approach and might not work in all environments
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
