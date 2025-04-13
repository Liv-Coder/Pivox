import 'package:http/http.dart' as http;
import 'package:pivox/pivox.dart';

/// Base class for all proxy sources.
///
/// This class provides common functionality for all proxy sources,
/// such as HTTP client management and timestamp tracking.
abstract class BaseProxySource implements ProxySource {
  final http.Client _client;
  DateTime? _lastUpdated;

  /// Creates a new [BaseProxySource].
  ///
  /// [client] is an optional HTTP client for making requests.
  BaseProxySource({http.Client? client}) : _client = client ?? http.Client();

  @override
  DateTime? get lastUpdated => _lastUpdated;

  @override
  void updateLastFetchedTime() {
    _lastUpdated = DateTime.now();
  }

  /// Makes an HTTP GET request to the specified URL.
  ///
  /// Returns the response body as a string if successful,
  /// or null if the request fails.
  Future<String?> _getRequest(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return response.body;
      }

      print('Error fetching from $url: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Exception fetching from $url: $e');
      return null;
    }
  }

  /// Helper method to make HTTP requests with error handling.
  Future<List<Proxy>> fetchWithErrorHandling(
    String url,
    Future<List<Proxy>> Function(String responseBody) parser, {
    Map<String, String>? headers,
  }) async {
    try {
      final responseBody = await _getRequest(url, headers: headers);

      if (responseBody == null) {
        return [];
      }

      final proxies = await parser(responseBody);
      updateLastFetchedTime();
      return proxies;
    } catch (e) {
      print('Error in $sourceName: $e');
      return [];
    }
  }

  /// Disposes of resources used by this source.
  void dispose() {
    _client.close();
  }
}
