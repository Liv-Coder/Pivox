/// Represents a proxy server
class Proxy {
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

  /// Region or city of the proxy server (optional)
  final String? region;

  /// Internet Service Provider of the proxy (optional)
  final String? isp;

  /// Maximum speed of the proxy in Mbps (optional)
  final double? speed;

  /// Whether the proxy supports websockets (optional)
  final bool? supportsWebsockets;

  /// Whether the proxy supports SOCKS protocol (optional)
  final bool? supportsSocks;

  /// SOCKS version if applicable (optional)
  final int? socksVersion;

  /// Username for authenticated proxies (optional)
  final String? username;

  /// Password for authenticated proxies (optional)
  final String? password;

  /// Creates a new [Proxy] instance
  const Proxy({
    required this.ip,
    required this.port,
    this.countryCode,
    this.isHttps = false,
    this.anonymityLevel,
    this.region,
    this.isp,
    this.speed,
    this.supportsWebsockets,
    this.supportsSocks,
    this.socksVersion,
    this.username,
    this.password,
  });

  /// Returns true if this proxy requires authentication
  bool get isAuthenticated => username != null && password != null;

  /// Returns the proxy URL in the format 'http(s)://ip:port'
  String get url => '${isHttps ? 'https' : 'http'}://$ip:$port';

  /// Returns a string representation of the proxy in the format 'ip:port'
  @override
  String toString() => '$ip:$port';
}
