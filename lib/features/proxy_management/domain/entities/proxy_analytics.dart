import 'proxy.dart';

/// Represents analytics data for proxy usage
class ProxyAnalytics {
  /// Total number of proxies fetched
  final int totalProxiesFetched;

  /// Total number of proxies validated
  final int totalProxiesValidated;

  /// Total number of successful validations
  final int totalSuccessfulValidations;

  /// Total number of failed validations
  final int totalFailedValidations;

  /// Total number of requests made
  final int totalRequests;

  /// Total number of successful requests
  final int totalSuccessfulRequests;

  /// Total number of failed requests
  final int totalFailedRequests;

  /// Average response time in milliseconds
  final int averageResponseTime;

  /// Average success rate (0.0 to 1.0)
  final double averageSuccessRate;

  /// Number of proxies by country
  final Map<String, int> proxiesByCountry;

  /// Number of proxies by anonymity level
  final Map<String, int> proxiesByAnonymityLevel;

  /// Number of requests by proxy source
  final Map<String, int> requestsByProxySource;

  /// Creates a new [ProxyAnalytics] instance
  const ProxyAnalytics({
    this.totalProxiesFetched = 0,
    this.totalProxiesValidated = 0,
    this.totalSuccessfulValidations = 0,
    this.totalFailedValidations = 0,
    this.totalRequests = 0,
    this.totalSuccessfulRequests = 0,
    this.totalFailedRequests = 0,
    this.averageResponseTime = 0,
    this.averageSuccessRate = 0.0,
    this.proxiesByCountry = const {},
    this.proxiesByAnonymityLevel = const {},
    this.requestsByProxySource = const {},
  });

  /// Creates a new [ProxyAnalytics] with updated values
  ProxyAnalytics copyWith({
    int? totalProxiesFetched,
    int? totalProxiesValidated,
    int? totalSuccessfulValidations,
    int? totalFailedValidations,
    int? totalRequests,
    int? totalSuccessfulRequests,
    int? totalFailedRequests,
    int? averageResponseTime,
    double? averageSuccessRate,
    Map<String, int>? proxiesByCountry,
    Map<String, int>? proxiesByAnonymityLevel,
    Map<String, int>? requestsByProxySource,
  }) {
    return ProxyAnalytics(
      totalProxiesFetched: totalProxiesFetched ?? this.totalProxiesFetched,
      totalProxiesValidated:
          totalProxiesValidated ?? this.totalProxiesValidated,
      totalSuccessfulValidations:
          totalSuccessfulValidations ?? this.totalSuccessfulValidations,
      totalFailedValidations:
          totalFailedValidations ?? this.totalFailedValidations,
      totalRequests: totalRequests ?? this.totalRequests,
      totalSuccessfulRequests:
          totalSuccessfulRequests ?? this.totalSuccessfulRequests,
      totalFailedRequests: totalFailedRequests ?? this.totalFailedRequests,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      averageSuccessRate: averageSuccessRate ?? this.averageSuccessRate,
      proxiesByCountry: proxiesByCountry ?? this.proxiesByCountry,
      proxiesByAnonymityLevel:
          proxiesByAnonymityLevel ?? this.proxiesByAnonymityLevel,
      requestsByProxySource:
          requestsByProxySource ?? this.requestsByProxySource,
    );
  }

  /// Creates a [ProxyAnalytics] from a JSON map
  factory ProxyAnalytics.fromJson(Map<String, dynamic> json) {
    return ProxyAnalytics(
      totalProxiesFetched: json['totalProxiesFetched'] as int? ?? 0,
      totalProxiesValidated: json['totalProxiesValidated'] as int? ?? 0,
      totalSuccessfulValidations:
          json['totalSuccessfulValidations'] as int? ?? 0,
      totalFailedValidations: json['totalFailedValidations'] as int? ?? 0,
      totalRequests: json['totalRequests'] as int? ?? 0,
      totalSuccessfulRequests: json['totalSuccessfulRequests'] as int? ?? 0,
      totalFailedRequests: json['totalFailedRequests'] as int? ?? 0,
      averageResponseTime: json['averageResponseTime'] as int? ?? 0,
      averageSuccessRate:
          (json['averageSuccessRate'] as num?)?.toDouble() ?? 0.0,
      proxiesByCountry:
          (json['proxiesByCountry'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      proxiesByAnonymityLevel:
          (json['proxiesByAnonymityLevel'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      requestsByProxySource:
          (json['requestsByProxySource'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }

  /// Converts this [ProxyAnalytics] to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'totalProxiesFetched': totalProxiesFetched,
      'totalProxiesValidated': totalProxiesValidated,
      'totalSuccessfulValidations': totalSuccessfulValidations,
      'totalFailedValidations': totalFailedValidations,
      'totalRequests': totalRequests,
      'totalSuccessfulRequests': totalSuccessfulRequests,
      'totalFailedRequests': totalFailedRequests,
      'averageResponseTime': averageResponseTime,
      'averageSuccessRate': averageSuccessRate,
      'proxiesByCountry': proxiesByCountry,
      'proxiesByAnonymityLevel': proxiesByAnonymityLevel,
      'requestsByProxySource': requestsByProxySource,
    };
  }

  /// Records a proxy fetch operation
  ProxyAnalytics recordProxyFetch(List<Proxy> proxies) {
    // Update total proxies fetched
    final newTotalProxiesFetched = totalProxiesFetched + proxies.length;

    // Update proxies by country
    final newProxiesByCountry = Map<String, int>.from(proxiesByCountry);
    for (final proxy in proxies) {
      if (proxy.countryCode != null) {
        final countryCode = proxy.countryCode!;
        newProxiesByCountry[countryCode] =
            (newProxiesByCountry[countryCode] ?? 0) + 1;
      }
    }

    // Update proxies by anonymity level
    final newProxiesByAnonymityLevel = Map<String, int>.from(
      proxiesByAnonymityLevel,
    );
    for (final proxy in proxies) {
      if (proxy.anonymityLevel != null) {
        final anonymityLevel = proxy.anonymityLevel!;
        newProxiesByAnonymityLevel[anonymityLevel] =
            (newProxiesByAnonymityLevel[anonymityLevel] ?? 0) + 1;
      }
    }

    return copyWith(
      totalProxiesFetched: newTotalProxiesFetched,
      proxiesByCountry: newProxiesByCountry,
      proxiesByAnonymityLevel: newProxiesByAnonymityLevel,
    );
  }

  /// Records a proxy validation operation
  ProxyAnalytics recordProxyValidation(
    List<Proxy> proxies,
    List<bool> results,
  ) {
    // Update validation counts
    final newTotalProxiesValidated = totalProxiesValidated + proxies.length;
    final successCount = results.where((result) => result).length;
    final failCount = results.where((result) => !result).length;
    final newTotalSuccessfulValidations =
        totalSuccessfulValidations + successCount;
    final newTotalFailedValidations = totalFailedValidations + failCount;

    return copyWith(
      totalProxiesValidated: newTotalProxiesValidated,
      totalSuccessfulValidations: newTotalSuccessfulValidations,
      totalFailedValidations: newTotalFailedValidations,
    );
  }

  /// Records a request made through a proxy
  ProxyAnalytics recordRequest(
    Proxy proxy,
    bool success,
    int? responseTime,
    String source,
  ) {
    // Update request counts
    final newTotalRequests = totalRequests + 1;
    final newTotalSuccessfulRequests =
        success ? totalSuccessfulRequests + 1 : totalSuccessfulRequests;
    final newTotalFailedRequests =
        !success ? totalFailedRequests + 1 : totalFailedRequests;

    // Update average response time
    final newAverageResponseTime =
        success && responseTime != null
            ? ((averageResponseTime * totalSuccessfulRequests) + responseTime) /
                (newTotalSuccessfulRequests)
            : averageResponseTime;

    // Update average success rate
    final newAverageSuccessRate =
        newTotalRequests > 0
            ? newTotalSuccessfulRequests / newTotalRequests
            : 0.0;

    // Update requests by proxy source
    final newRequestsByProxySource = Map<String, int>.from(
      requestsByProxySource,
    );
    newRequestsByProxySource[source] =
        (newRequestsByProxySource[source] ?? 0) + 1;

    return copyWith(
      totalRequests: newTotalRequests,
      totalSuccessfulRequests: newTotalSuccessfulRequests,
      totalFailedRequests: newTotalFailedRequests,
      averageResponseTime: newAverageResponseTime.round(),
      averageSuccessRate: newAverageSuccessRate,
      requestsByProxySource: newRequestsByProxySource,
    );
  }
}
