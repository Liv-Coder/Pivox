import '../../domain/entities/proxy.dart';
import '../../domain/entities/proxy_score.dart';

/// Data model for a proxy server
class ProxyModel extends Proxy {
  /// Last time the proxy was checked (in milliseconds since epoch)
  final int? lastChecked;

  /// Response time of the proxy in milliseconds (optional)
  final int? responseTime;

  /// Score of the proxy (optional)
  final ProxyScore? score;

  /// Creates a new [ProxyModel] instance
  const ProxyModel({
    required super.ip,
    required super.port,
    super.countryCode,
    super.isHttps,
    super.anonymityLevel,
    this.lastChecked,
    this.responseTime,
    this.score,
  });

  /// Creates a [ProxyModel] from a JSON map
  factory ProxyModel.fromJson(Map<String, dynamic> json) {
    return ProxyModel(
      ip: json['ip'] as String,
      port: json['port'] as int,
      countryCode: json['countryCode'] as String?,
      isHttps: json['isHttps'] as bool? ?? false,
      anonymityLevel: json['anonymityLevel'] as String?,
      lastChecked: json['lastChecked'] as int?,
      responseTime: json['responseTime'] as int?,
      score:
          json['score'] != null
              ? ProxyScore.fromJson(json['score'] as Map<String, dynamic>)
              : null,
    );
  }

  /// Converts this [ProxyModel] to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'port': port,
      if (countryCode != null) 'countryCode': countryCode,
      'isHttps': isHttps,
      if (anonymityLevel != null) 'anonymityLevel': anonymityLevel,
      if (lastChecked != null) 'lastChecked': lastChecked,
      if (responseTime != null) 'responseTime': responseTime,
      if (score != null) 'score': score!.toJson(),
    };
  }

  /// Creates a [ProxyModel] from a [Proxy] entity
  factory ProxyModel.fromEntity(Proxy proxy) {
    return ProxyModel(
      ip: proxy.ip,
      port: proxy.port,
      countryCode: proxy.countryCode,
      isHttps: proxy.isHttps,
      anonymityLevel: proxy.anonymityLevel,
      lastChecked: null,
      responseTime: null,
      score: ProxyScore.initial(),
    );
  }

  /// Creates a new [ProxyModel] with an updated score after a successful request
  ProxyModel withSuccessfulRequest(int responseTime) {
    final newScore = (score ?? ProxyScore.initial()).recordSuccess(
      responseTime,
    );

    return ProxyModel(
      ip: ip,
      port: port,
      countryCode: countryCode,
      isHttps: isHttps,
      anonymityLevel: anonymityLevel,
      lastChecked: DateTime.now().millisecondsSinceEpoch,
      responseTime: responseTime,
      score: newScore,
    );
  }

  /// Creates a new [ProxyModel] with an updated score after a failed request
  ProxyModel withFailedRequest() {
    final newScore = (score ?? ProxyScore.initial()).recordFailure();

    return ProxyModel(
      ip: ip,
      port: port,
      countryCode: countryCode,
      isHttps: isHttps,
      anonymityLevel: anonymityLevel,
      lastChecked: DateTime.now().millisecondsSinceEpoch,
      responseTime: responseTime,
      score: newScore,
    );
  }
}
