import 'package:pivox/pivox.dart';
import 'base_proxy_source.dart';

/// A [ProxySource] implementation that scrapes proxies from free-proxy-list.net.
class FreeProxyListScraper extends BaseProxySource {
  final String _url;

  /// Creates a new [FreeProxyListScraper].
  ///
  /// [url] is the URL of the proxy list website to scrape.
  /// [client] is an optional HTTP client for making requests.
  FreeProxyListScraper({
    String url = 'https://free-proxy-list.net/',
    super.client,
  }) : _url = url;

  @override
  String get sourceName => 'FreeProxyList';

  @override
  Future<List<Proxy>> fetchProxies() async {
    return fetchWithErrorHandling(_url, (html) async => _parseProxies(html));
  }

  /// Parses the HTML response to extract proxies.
  List<Proxy> _parseProxies(String html) {
    final proxies = <Proxy>[];

    // Extract the table rows containing proxy information
    final tableRegex = RegExp(r'<tbody>(.*?)</tbody>', dotAll: true);
    final tableMatch = tableRegex.firstMatch(html);

    if (tableMatch == null) {
      return proxies;
    }

    final tableContent = tableMatch.group(1) ?? '';

    // Extract rows
    final rowRegex = RegExp(r'<tr>(.*?)</tr>', dotAll: true);
    final rowMatches = rowRegex.allMatches(tableContent);

    for (final rowMatch in rowMatches) {
      final row = rowMatch.group(1) ?? '';

      // Extract cells
      final cellRegex = RegExp(r'<td>(.*?)</td>', dotAll: true);
      final cellMatches = cellRegex.allMatches(row);
      final cells = cellMatches.map((m) => m.group(1)?.trim() ?? '').toList();

      if (cells.length >= 8) {
        final ip = cells[0];
        final port = int.tryParse(cells[1]) ?? 0;
        final isHttps = cells[6].toLowerCase() == 'yes';

        if (port > 0) {
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
      }
    }

    return proxies;
  }
}
