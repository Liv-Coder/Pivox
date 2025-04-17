/// Represents a proxy server with its details
class ProxyModel {
  /// IP address of the proxy server
  final String ip;

  /// Port number of the proxy server
  final int port;

  /// Country code of the proxy server (optional)
  final String? countryCode;

  /// Whether the proxy supports HTTPS
  final bool isHttps;

  /// Anonymity level of the proxy (e.g., 'elite', 'anonymous', 'transparent')
  final String? anonymityLevel;

  /// Last time the proxy was checked (in milliseconds since epoch)
  final int? lastChecked;

  /// Response time of the proxy in milliseconds (optional)
  final int? responseTime;

  /// Creates a new [ProxyModel] instance
  const ProxyModel({
    required this.ip,
    required this.port,
    this.countryCode,
    this.isHttps = false,
    this.anonymityLevel,
    this.lastChecked,
    this.responseTime,
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
    };
  }

  /// Returns the proxy URL in the format 'http(s)://ip:port'
  String get url => '${isHttps ? 'https' : 'http'}://$ip:$port';

  /// Returns a string representation of the proxy in the format 'ip:port'
  @override
  String toString() => '$ip:$port';
}
