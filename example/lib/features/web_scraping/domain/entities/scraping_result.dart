/// Scraping result entity
class ScrapingResult {
  final List<Map<String, dynamic>> data;
  final bool success;
  final String? error;
  final int statusCode;
  final int itemsScraped;
  final int pagesScraped;
  final Duration duration;
  final String? proxyUsed;
  final bool usedHeadlessBrowser;
  final List<String>? logs;

  const ScrapingResult({
    required this.data,
    required this.success,
    this.error,
    required this.statusCode,
    required this.itemsScraped,
    required this.pagesScraped,
    required this.duration,
    this.proxyUsed,
    required this.usedHeadlessBrowser,
    this.logs,
  });

  /// Create a success result
  factory ScrapingResult.success({
    required List<Map<String, dynamic>> data,
    required int statusCode,
    required int pagesScraped,
    required Duration duration,
    String? proxyUsed,
    required bool usedHeadlessBrowser,
    List<String>? logs,
  }) {
    return ScrapingResult(
      data: data,
      success: true,
      statusCode: statusCode,
      itemsScraped: data.length,
      pagesScraped: pagesScraped,
      duration: duration,
      proxyUsed: proxyUsed,
      usedHeadlessBrowser: usedHeadlessBrowser,
      logs: logs,
    );
  }

  /// Create an error result
  factory ScrapingResult.error({
    required String error,
    int statusCode = 0,
    Duration? duration,
    String? proxyUsed,
    bool usedHeadlessBrowser = false,
    List<String>? logs,
  }) {
    return ScrapingResult(
      data: [],
      success: false,
      error: error,
      statusCode: statusCode,
      itemsScraped: 0,
      pagesScraped: 0,
      duration: duration ?? Duration.zero,
      proxyUsed: proxyUsed,
      usedHeadlessBrowser: usedHeadlessBrowser,
      logs: logs,
    );
  }
}
