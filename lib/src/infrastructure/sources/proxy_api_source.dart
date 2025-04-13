import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pivox/pivox.dart';

/// A [ProxySource] implementation that fetches proxies from a JSON API.
class ProxyApiSource implements ProxySource {
  final String _apiUrl;
  final Map<String, String>? _headers;
  final http.Client _client;
  DateTime? _lastUpdated;

  /// Creates a new [ProxyApiSource].
  ///
  /// [apiUrl] is the URL of the API endpoint that returns proxies.
  /// [headers] is an optional map of HTTP headers to include in the request.
  /// [client] is an optional HTTP client for making requests.
  ProxyApiSource({
    required String apiUrl,
    Map<String, String>? headers,
    http.Client? client,
  })  : _apiUrl = apiUrl,
        _headers = headers,
        _client = client ?? http.Client();

  @override
  String get sourceName => 'ProxyAPI';

  @override
  DateTime? get lastUpdated => _lastUpdated;

  @override
  void updateLastFetchedTime() {
    _lastUpdated = DateTime.now();
  }

  @override
  Future<List<Proxy>> fetchProxies() async {
    try {
      final response = await _client.get(
        Uri.parse(_apiUrl),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load proxies: ${response.statusCode}');
      }

      return _parseProxies(response.body);
    } catch (e) {
      // Log error but return empty list
      print('Error fetching proxies from $sourceName: $e');
      return [];
    }
  }

  /// Parses the JSON response to extract proxies.
  List<Proxy> _parseProxies(String jsonStr) {
    final proxies = <Proxy>[];
    
    try {
      final data = json.decode(jsonStr);
      
      // Handle different API response formats
      if (data is List) {
        // Format: [{"ip": "1.2.3.4", "port": 8080, ...}, ...]
        for (final item in data) {
          final proxy = _createProxyFromMap(item);
          if (proxy != null) {
            proxies.add(proxy);
          }
        }
      } else if (data is Map && data.containsKey('data')) {
        // Format: {"data": [{"ip": "1.2.3.4", "port": 8080, ...}, ...]}
        final dataList = data['data'];
        if (dataList is List) {
          for (final item in dataList) {
            final proxy = _createProxyFromMap(item);
            if (proxy != null) {
              proxies.add(proxy);
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing proxy JSON: $e');
    }
    
    return proxies;
  }

  /// Creates a Proxy object from a map of proxy data.
  Proxy? _createProxyFromMap(Map<String, dynamic> map) {
    // Extract host (might be under 'ip' or 'host' key)
    final host = map['ip'] ?? map['host'] ?? map['address'];
    if (host == null || host is! String) return null;

    // Extract port
    final port = map['port'];
    if (port == null) return null;
    
    final portInt = port is int ? port : int.tryParse(port.toString());
    if (portInt == null || portInt <= 0) return null;

    // Extract proxy type
    ProxyType type = ProxyType.http;
    final protocol = map['protocol'] ?? map['type'] ?? 'http';
    if (protocol is String) {
      final protocolLower = protocol.toLowerCase();
      if (protocolLower.contains('https')) {
        type = ProxyType.https;
      } else if (protocolLower.contains('socks4')) {
        type = ProxyType.socks4;
      } else if (protocolLower.contains('socks5')) {
        type = ProxyType.socks5;
      }
    }

    // Extract authentication if available
    final username = map['username'] as String?;
    final password = map['password'] as String?;

    return Proxy(
      host: host,
      port: portInt,
      username: username,
      password: password,
      type: type,
      lastChecked: DateTime.now(),
      responseTime: map['response_time'] is int ? map['response_time'] : 0,
      isActive: true,
    );
  }

  /// Disposes of resources used by this source.
  void dispose() {
    _client.close();
  }
}
