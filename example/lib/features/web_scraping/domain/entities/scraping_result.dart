/// Entity representing the result of a web scraping operation
class ScrapingResult {
  /// The URL that was scraped
  final String url;

  /// The data that was scraped
  final List<Map<String, String>> data;

  /// The timestamp when the scraping was completed
  final DateTime timestamp;

  /// Creates a new [ScrapingResult]
  const ScrapingResult({
    required this.url,
    required this.data,
    required this.timestamp,
  });

  /// Creates a copy of this [ScrapingResult] with the given fields replaced with new values
  ScrapingResult copyWith({
    String? url,
    List<Map<String, String>>? data,
    DateTime? timestamp,
  }) {
    return ScrapingResult(
      url: url ?? this.url,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
