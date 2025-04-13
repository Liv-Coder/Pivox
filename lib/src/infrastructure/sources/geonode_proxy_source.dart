import 'dart:convert';
import 'package:pivox/pivox.dart';
import 'base_proxy_source.dart';

/// A [ProxySource] implementation that fetches proxies from GeoNode's API.
class GeoNodeProxySource extends BaseProxySource {
  final String _apiUrl;
  final int _limit;

  /// Creates a new [GeoNodeProxySource].
  ///
  /// [limit] is the maximum number of proxies to fetch.
  /// [client] is an optional HTTP client for making requests.
  GeoNodeProxySource({
    int limit = 100,
    super.client,
  })  : _limit = limit,
        _apiUrl = 'https://proxylist.geonode.com/api/proxy-list?limit=$limit&page=1&sort_by=lastChecked&sort_type=desc';

  @override
  String get sourceName => 'GeoNode';

  @override
  Future<List<Proxy>> fetchProxies() async {
    return fetchWithErrorHandling(_apiUrl, _parseProxies);
  }

  /// Parses the JSON response to extract proxies.
  Future<List<Proxy>> _parseProxies(String jsonStr) async {
    final proxies = <Proxy>[];
    
    try {
      final data = json.decode(jsonStr);
      
      if (data is Map && data.containsKey('data')) {
        final proxyList = data['data'] as List;
        
        for (final item in proxyList) {
          if (item is Map) {
            final host = item['ip'] as String?;
            final portStr = item['port'] as String?;
            
            if (host != null && portStr != null) {
              final port = int.tryParse(portStr);
              
              if (port != null && port > 0) {
                // Determine proxy type
                ProxyType type = ProxyType.http;
                final protocols = item['protocols'] as List?;
                
                if (protocols != null) {
                  if (protocols.contains('https')) {
                    type = ProxyType.https;
                  } else if (protocols.contains('socks4')) {
                    type = ProxyType.socks4;
                  } else if (protocols.contains('socks5')) {
                    type = ProxyType.socks5;
                  }
                }
                
                // Get response time if available
                int responseTime = 0;
                final speed = item['speed'] as String?;
                if (speed != null) {
                  final speedValue = double.tryParse(speed);
                  if (speedValue != null) {
                    responseTime = (speedValue * 1000).round(); // Convert to milliseconds
                  }
                }
                
                proxies.add(
                  Proxy(
                    host: host,
                    port: port,
                    type: type,
                    lastChecked: DateTime.now(),
                    responseTime: responseTime,
                    isActive: true,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing GeoNode response: $e');
    }
    
    return proxies;
  }
}
