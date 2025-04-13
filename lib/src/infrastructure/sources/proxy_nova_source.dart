import 'package:pivox/pivox.dart';
import 'base_proxy_source.dart';

/// A [ProxySource] implementation that scrapes proxies from ProxyNova.
class ProxyNovaSource extends BaseProxySource {
  final String _url;

  /// Creates a new [ProxyNovaSource].
  ///
  /// [client] is an optional HTTP client for making requests.
  ProxyNovaSource({
    super.client,
  }) : _url = 'https://www.proxynova.com/proxy-server-list/';

  @override
  String get sourceName => 'ProxyNova';

  @override
  Future<List<Proxy>> fetchProxies() async {
    return fetchWithErrorHandling(_url, _parseProxies);
  }

  /// Parses the HTML response to extract proxies.
  Future<List<Proxy>> _parseProxies(String html) async {
    final proxies = <Proxy>[];
    
    try {
      // Extract the table rows containing proxy information
      final tableRegex = RegExp(
        r'<tbody[^>]*>(.*?)</tbody>',
        dotAll: true,
      );
      final tableMatch = tableRegex.firstMatch(html);
      
      if (tableMatch == null) {
        return proxies;
      }
      
      final tableContent = tableMatch.group(1) ?? '';
      
      // Extract rows
      final rowRegex = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true);
      final rowMatches = rowRegex.allMatches(tableContent);
      
      for (final rowMatch in rowMatches) {
        final row = rowMatch.group(1) ?? '';
        
        // Extract IP address (ProxyNova obfuscates the IP in JavaScript)
        final ipRegex = RegExp(r'data-ip="([^"]+)"');
        final ipMatch = ipRegex.firstMatch(row);
        
        if (ipMatch == null) continue;
        
        final ip = ipMatch.group(1)?.trim() ?? '';
        if (ip.isEmpty) continue;
        
        // Extract port
        final portRegex = RegExp(r'<td[^>]*>\s*(\d+)\s*</td>');
        final portMatch = portRegex.firstMatch(row);
        
        if (portMatch == null) continue;
        
        final portStr = portMatch.group(1)?.trim() ?? '';
        final port = int.tryParse(portStr);
        
        if (port == null || port <= 0) continue;
        
        // Determine if HTTPS
        final isHttps = row.contains('HTTPS') || row.contains('https');
        
        proxies.add(
          Proxy(
            host: ip,
            port: port,
            type: isHttps ? ProxyType.https : ProxyType.http,
            lastChecked: DateTime.now(),
            responseTime: 0, // Unknown at this point
            isActive: true,
          ),
        );
      }
    } catch (e) {
      print('Error parsing ProxyNova response: $e');
    }
    
    return proxies;
  }
}
