import 'package:pivox/pivox.dart';

/// Interface for proxy sources.
/// 
/// Implementations of this interface define how proxies are fetched
/// from various sources such as web scraping or API services.
abstract class ProxySource {
  /// Fetches a list of proxies from the source.
  /// 
  /// Returns an empty list if no proxies are available or if fetching fails.
  Future<List<Proxy>> fetchProxies();
  
  /// The name of the proxy source.
  String get sourceName;
  
  /// The timestamp when proxies were last fetched from this source.
  DateTime? get lastUpdated;
  
  /// Updates the lastUpdated timestamp to the current time.
  void updateLastFetchedTime();
}
