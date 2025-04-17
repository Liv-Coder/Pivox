/// Proxy entity
class ProxyEntity {
  final String ip;
  final int port;
  final String? username;
  final String? password;
  final String? country;
  final String? city;
  final bool isAnonymous;
  final bool isHttps;
  final String? type;
  final double? speed;
  final DateTime? lastChecked;
  final bool isValid;
  final int successCount;
  final int failureCount;
  final double? score;
  final DateTime? lastUsed;

  const ProxyEntity({
    required this.ip,
    required this.port,
    this.username,
    this.password,
    this.country,
    this.city,
    this.isAnonymous = false,
    this.isHttps = false,
    this.type,
    this.speed,
    this.lastChecked,
    this.isValid = false,
    this.successCount = 0,
    this.failureCount = 0,
    this.score,
    this.lastUsed,
  });

  /// Get proxy URL
  String get url {
    final auth =
        (username != null && password != null) ? '$username:$password@' : '';
    return '$auth$ip:$port';
  }

  /// Get proxy URL with protocol
  String getUrlWithProtocol({bool useHttps = false}) {
    final protocol = useHttps ? 'https' : 'http';
    return '$protocol://$url';
  }

  /// Get success rate
  double get successRate {
    final total = successCount + failureCount;
    if (total == 0) return 0;
    return successCount / total;
  }

  /// Copy with new values
  ProxyEntity copyWith({
    String? ip,
    int? port,
    String? username,
    String? password,
    String? country,
    String? city,
    bool? isAnonymous,
    bool? isHttps,
    String? type,
    double? speed,
    DateTime? lastChecked,
    bool? isValid,
    int? successCount,
    int? failureCount,
    double? score,
    DateTime? lastUsed,
  }) {
    return ProxyEntity(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      country: country ?? this.country,
      city: city ?? this.city,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isHttps: isHttps ?? this.isHttps,
      type: type ?? this.type,
      speed: speed ?? this.speed,
      lastChecked: lastChecked ?? this.lastChecked,
      isValid: isValid ?? this.isValid,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      score: score ?? this.score,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
