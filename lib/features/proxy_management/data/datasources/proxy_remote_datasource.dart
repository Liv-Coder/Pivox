// We'll need dart:convert when implementing JSON parsing
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import '../../../../core/config/proxy_source_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/proxy_model.dart';

/// Interface for remote data source to fetch proxies
abstract class ProxyRemoteDataSource {
  /// Fetches proxies from various sources
  ///
  /// [count] is the number of proxies to fetch
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  /// [regions] filters to only return proxies from specific regions
  /// [isps] filters to only return proxies from specific ISPs
  Future<List<ProxyModel>> fetchProxies({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
    List<String>? regions,
    List<String>? isps,
  });
}

/// Implementation of [ProxyRemoteDataSource]
class ProxyRemoteDataSourceImpl implements ProxyRemoteDataSource {
  /// HTTP client for making requests
  final http.Client client;

  /// Configuration for proxy sources
  final ProxySourceConfig sourceConfig;

  /// Creates a new [ProxyRemoteDataSourceImpl] with the given [client] and [sourceConfig]
  const ProxyRemoteDataSourceImpl({
    required this.client,
    this.sourceConfig = const ProxySourceConfig(),
  });

  @override
  Future<List<ProxyModel>> fetchProxies({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
    List<String>? regions,
    List<String>? isps,
  }) async {
    final proxies = <ProxyModel>[];

    // Try each enabled source until we have enough proxies
    for (final url in sourceConfig.getEnabledSourceUrls()) {
      if (proxies.length >= count) break;

      try {
        final sourceProxies = await _fetchFromSource(
          url,
          onlyHttps: onlyHttps,
          countries: countries,
          regions: regions,
          isps: isps,
        );

        proxies.addAll(sourceProxies);
      } catch (e) {
        // Continue to the next source if this one fails
        continue;
      }
    }

    // Return the requested number of proxies
    return proxies.take(count).toList();
  }

  /// Fetches proxies from a specific source
  ///
  /// [url] is the URL of the proxy source
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  /// [regions] filters to only return proxies from specific regions
  /// [isps] filters to only return proxies from specific ISPs
  Future<List<ProxyModel>> _fetchFromSource(
    String url, {
    bool onlyHttps = false,
    List<String>? countries,
    List<String>? regions,
    List<String>? isps,
  }) async {
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {'User-Agent': AppConstants.defaultUserAgent},
      );

      if (response.statusCode != 200) {
        throw ProxyFetchException(
          'Failed to fetch proxies from $url: ${response.statusCode}',
        );
      }

      // Parse the response based on the source
      if (url.contains('free-proxy-list.net')) {
        return _parseFreeProxyList(response.body, onlyHttps, countries);
      } else if (url.contains('geonode.com')) {
        return _parseGeoNode(response.body, onlyHttps, countries);
      } else if (url.contains('proxyscrape.com')) {
        return _parseProxyScrape(response.body, onlyHttps, countries);
      } else if (url.contains('proxynova.com')) {
        return _parseProxyNova(response.body, onlyHttps, countries);
      }

      return [];
    } catch (e) {
      throw ProxyFetchException('Failed to fetch proxies from $url: $e');
    }
  }

  /// Parses proxies from free-proxy-list.net
  List<ProxyModel> _parseFreeProxyList(
    String html,
    bool onlyHttps,
    List<String>? countries,
  ) {
    final proxies = <ProxyModel>[];
    final document = parser.parse(html);

    // Find the table rows
    final rows = document.querySelectorAll('table tbody tr');

    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 8) continue;

      final ip = cells[0].text.trim();
      final port = int.tryParse(cells[1].text.trim()) ?? 0;
      final countryCode = cells[2].text.trim();
      final anonymity = cells[4].text.trim().toLowerCase();
      final https = cells[6].text.trim().toLowerCase() == 'yes';

      // Skip if port is invalid
      if (port <= 0) continue;

      // Skip if not HTTPS but only HTTPS is requested
      if (onlyHttps && !https) continue;

      // Skip if country filter is applied and this proxy doesn't match
      if (countries != null &&
          countries.isNotEmpty &&
          !countries.contains(countryCode)) {
        continue;
      }

      proxies.add(
        ProxyModel(
          ip: ip,
          port: port,
          countryCode: countryCode,
          isHttps: https,
          anonymityLevel: anonymity,
          lastChecked: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    return proxies;
  }

  /// Parses proxies from geonode.com
  List<ProxyModel> _parseGeoNode(
    String html,
    bool onlyHttps,
    List<String>? countries,
  ) {
    // Implementation would depend on the actual structure of the page
    // This is a placeholder
    return [];
  }

  /// Parses proxies from proxyscrape.com
  List<ProxyModel> _parseProxyScrape(
    String html,
    bool onlyHttps,
    List<String>? countries,
  ) {
    // Implementation would depend on the actual structure of the page
    // This is a placeholder
    return [];
  }

  /// Parses proxies from proxynova.com
  List<ProxyModel> _parseProxyNova(
    String html,
    bool onlyHttps,
    List<String>? countries,
  ) {
    // Implementation would depend on the actual structure of the page
    // This is a placeholder
    return [];
  }
}
