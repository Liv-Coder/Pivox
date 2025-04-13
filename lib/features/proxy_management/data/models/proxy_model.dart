import '../../domain/entities/proxy.dart';
import '../../domain/entities/proxy_auth.dart';
import '../../domain/entities/proxy_protocol.dart';
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
    super.region,
    super.isp,
    super.speed,
    super.supportsWebsockets,
    super.protocol,
    super.auth,
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
      region: json['region'] as String?,
      isp: json['isp'] as String?,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      supportsWebsockets: json['supportsWebsockets'] as bool?,
      protocol:
          json['protocol'] != null
              ? ProxyProtocol.values[json['protocol'] as int]
              : json['supportsSocks'] == true
              ? json['socksVersion'] == 5
                  ? ProxyProtocol.socks5
                  : ProxyProtocol.socks4
              : json['isHttps'] == true
              ? ProxyProtocol.https
              : ProxyProtocol.http,
      auth:
          json['auth'] != null
              ? ProxyAuth.fromJson(json['auth'] as Map<String, dynamic>)
              : json['username'] != null && json['password'] != null
              ? ProxyAuth.basic(
                username: json['username'] as String,
                password: json['password'] as String,
              )
              : null,
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
      if (region != null) 'region': region,
      if (isp != null) 'isp': isp,
      if (speed != null) 'speed': speed,
      if (supportsWebsockets != null) 'supportsWebsockets': supportsWebsockets,
      'protocol': protocol.index,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
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
      region: proxy.region,
      isp: proxy.isp,
      speed: proxy.speed,
      supportsWebsockets: proxy.supportsWebsockets,
      protocol: proxy.protocol,
      auth: proxy.auth,
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
      region: region,
      isp: isp,
      speed: speed,
      supportsWebsockets: supportsWebsockets,
      protocol: protocol,
      auth: auth,
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
      region: region,
      isp: isp,
      speed: speed,
      supportsWebsockets: supportsWebsockets,
      protocol: protocol,
      auth: auth,
      lastChecked: DateTime.now().millisecondsSinceEpoch,
      responseTime: responseTime,
      score: newScore,
    );
  }

  /// Creates a copy of this [ProxyModel] with the given parameters
  ProxyModel copyWith({
    String? ip,
    int? port,
    String? countryCode,
    bool? isHttps,
    String? anonymityLevel,
    String? region,
    String? isp,
    double? speed,
    bool? supportsWebsockets,
    ProxyProtocol? protocol,
    ProxyAuth? auth,
    int? lastChecked,
    int? responseTime,
    ProxyScore? score,
  }) {
    return ProxyModel(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      countryCode: countryCode ?? this.countryCode,
      isHttps: isHttps ?? this.isHttps,
      anonymityLevel: anonymityLevel ?? this.anonymityLevel,
      region: region ?? this.region,
      isp: isp ?? this.isp,
      speed: speed ?? this.speed,
      supportsWebsockets: supportsWebsockets ?? this.supportsWebsockets,
      protocol: protocol ?? this.protocol,
      auth: auth ?? this.auth,
      lastChecked: lastChecked ?? this.lastChecked,
      responseTime: responseTime ?? this.responseTime,
      score: score ?? this.score,
    );
  }

  /// Creates a new [ProxyModel] with the given authentication credentials
  @override
  ProxyModel withAuth(ProxyAuth auth) {
    return copyWith(auth: auth);
  }

  /// Creates a new [ProxyModel] with basic authentication
  @override
  ProxyModel withBasicAuth(String username, String password) {
    return withAuth(ProxyAuth.basic(username: username, password: password));
  }

  /// Creates a new [ProxyModel] with digest authentication
  ProxyModel withDigestAuth(String username, String password) {
    return withAuth(ProxyAuth.digest(username: username, password: password));
  }

  /// Creates a new [ProxyModel] with NTLM authentication
  ProxyModel withNtlmAuth(String username, String password, String domain) {
    return withAuth(
      ProxyAuth.ntlm(username: username, password: password, domain: domain),
    );
  }
}
