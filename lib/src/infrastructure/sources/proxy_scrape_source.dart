import 'package:pivox/pivox.dart';
import 'base_proxy_source.dart';

/// A [ProxySource] implementation that fetches proxies from ProxyScrape's API.
class ProxyScrapeSource extends BaseProxySource {
  final String _apiUrl;
  final ProxyType _proxyType;

  /// Creates a new [ProxyScrapeSource].
  ///
  /// [proxyType] is the type of proxies to fetch (http, https, socks4, socks5).
  /// [timeout] is the maximum timeout in milliseconds for the proxies.
  /// [client] is an optional HTTP client for making requests.
  ProxyScrapeSource({
    ProxyType proxyType = ProxyType.http,
    int timeout = 10000,
    super.client,
  }) : _proxyType = proxyType,
       _apiUrl =
           'https://api.proxyscrape.com/v2/?request=getproxies&protocol=${_getProtocolString(proxyType)}&timeout=$timeout&country=all&ssl=all&anonymity=all';

  /// Converts a [ProxyType] to the corresponding protocol string for the API.
  static String _getProtocolString(ProxyType type) {
    switch (type) {
      case ProxyType.http:
        return 'http';
      case ProxyType.https:
        return 'https';
      case ProxyType.socks4:
        return 'socks4';
      case ProxyType.socks5:
        return 'socks5';
    }
  }

  @override
  String get sourceName => 'ProxyScrape';

  @override
  Future<List<Proxy>> fetchProxies() async {
    return fetchWithErrorHandling(_apiUrl, _parseProxies);
  }

  /// Parses the text response to extract proxies.
  Future<List<Proxy>> _parseProxies(String text) async {
    final proxies = <Proxy>[];

    try {
      // The response is a plain text list of IP:PORT
      final lines = text.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final parts = trimmed.split(':');
        if (parts.length == 2) {
          final host = parts[0];
          final port = int.tryParse(parts[1]);

          if (port != null && port > 0) {
            proxies.add(
              Proxy(
                host: host,
                port: port,
                type: _proxyType,
                lastChecked: DateTime.now(),
                responseTime: 0, // Unknown at this point
                isActive: true,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error parsing ProxyScrape response: $e');
    }

    return proxies;
  }
}
