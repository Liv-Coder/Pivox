import 'proxy_auth.dart';
import 'proxy_protocol.dart';
import 'proxy_score.dart';

/// Represents a proxy server
class Proxy {
  /// IP address of the proxy server
  final String ip;

  /// Port number of the proxy server
  final int port;

  /// Country code of the proxy server (optional)
  final String? countryCode;

  /// Country name of the proxy server (optional)
  final String? country;

  /// Whether the proxy supports HTTPS
  /// @deprecated Use protocol instead
  final bool isHttps;

  /// Protocol used by the proxy
  final ProxyProtocol protocol;

  /// Anonymity level of the proxy (e.g., 'elite', 'anonymous', 'transparent')
  final String? anonymityLevel;

  /// Region or city of the proxy server (optional)
  final String? region;

  /// Internet Service Provider of the proxy (optional)
  final String? isp;

  /// Maximum speed of the proxy in Mbps (optional)
  final double? speed;

  /// Latency of the proxy in milliseconds (optional)
  final int? latency;

  /// Whether the proxy supports websockets (optional)
  final bool? supportsWebsockets;

  /// Whether the proxy supports SOCKS protocol (optional)
  /// @deprecated Use protocol instead
  bool? get supportsSocks => protocol.isSocks;

  /// SOCKS version if applicable (optional)
  /// @deprecated Use protocol instead
  int? get socksVersion => protocol.socksVersion;

  /// Authentication credentials (optional)
  final ProxyAuth? auth;

  /// Performance and reliability score for this proxy
  final ProxyScore? score;

  /// Username for authenticated proxies (optional)
  /// @deprecated Use auth instead
  String? get username => auth?.username;

  /// Password for authenticated proxies (optional)
  /// @deprecated Use auth instead
  String? get password => auth?.password;

  /// Creates a new [Proxy] instance
  const Proxy({
    required this.ip,
    required this.port,
    this.countryCode,
    this.country,
    this.isHttps = false,
    this.protocol = ProxyProtocol.http,
    this.anonymityLevel,
    this.region,
    this.isp,
    this.speed,
    this.latency,
    this.supportsWebsockets,
    this.auth,
    this.score,
    String? username,
    String? password,
  }) : assert(
         (username == null && password == null) || auth == null,
         'Cannot provide both username/password and auth',
       );

  /// Creates a new [Proxy] with HTTP protocol
  factory Proxy.http({
    required String ip,
    required int port,
    String? countryCode,
    String? anonymityLevel,
    String? region,
    String? isp,
    double? speed,
    bool? supportsWebsockets,
    ProxyAuth? auth,
  }) {
    return Proxy(
      ip: ip,
      port: port,
      countryCode: countryCode,
      isHttps: false,
      protocol: ProxyProtocol.http,
      anonymityLevel: anonymityLevel,
      region: region,
      isp: isp,
      speed: speed,
      supportsWebsockets: supportsWebsockets,
      auth: auth,
    );
  }

  /// Creates a new [Proxy] with HTTPS protocol
  factory Proxy.https({
    required String ip,
    required int port,
    String? countryCode,
    String? anonymityLevel,
    String? region,
    String? isp,
    double? speed,
    bool? supportsWebsockets,
    ProxyAuth? auth,
  }) {
    return Proxy(
      ip: ip,
      port: port,
      countryCode: countryCode,
      isHttps: true,
      protocol: ProxyProtocol.https,
      anonymityLevel: anonymityLevel,
      region: region,
      isp: isp,
      speed: speed,
      supportsWebsockets: supportsWebsockets,
      auth: auth,
    );
  }

  /// Creates a new [Proxy] with SOCKS4 protocol
  factory Proxy.socks4({
    required String ip,
    required int port,
    String? countryCode,
    String? anonymityLevel,
    String? region,
    String? isp,
    double? speed,
    bool? supportsWebsockets,
    ProxyAuth? auth,
  }) {
    return Proxy(
      ip: ip,
      port: port,
      countryCode: countryCode,
      isHttps: false,
      protocol: ProxyProtocol.socks4,
      anonymityLevel: anonymityLevel,
      region: region,
      isp: isp,
      speed: speed,
      supportsWebsockets: supportsWebsockets,
      auth: auth,
    );
  }

  /// Creates a new [Proxy] with SOCKS5 protocol
  factory Proxy.socks5({
    required String ip,
    required int port,
    String? countryCode,
    String? anonymityLevel,
    String? region,
    String? isp,
    double? speed,
    bool? supportsWebsockets,
    ProxyAuth? auth,
  }) {
    return Proxy(
      ip: ip,
      port: port,
      countryCode: countryCode,
      isHttps: false,
      protocol: ProxyProtocol.socks5,
      anonymityLevel: anonymityLevel,
      region: region,
      isp: isp,
      speed: speed,
      supportsWebsockets: supportsWebsockets,
      auth: auth,
    );
  }

  /// Returns true if this proxy requires authentication
  bool get isAuthenticated =>
      auth != null || (username != null && password != null);

  /// Returns the authentication method
  ProxyAuthMethod get authMethod => auth?.method ?? ProxyAuthMethod.basic;

  /// Creates a new [Proxy] with the given authentication credentials
  Proxy withAuth(ProxyAuth auth) {
    return Proxy(
      ip: ip,
      port: port,
      countryCode: countryCode,
      isHttps: isHttps,
      protocol: protocol,
      anonymityLevel: anonymityLevel,
      region: region,
      isp: isp,
      speed: speed,
      supportsWebsockets: supportsWebsockets,
      auth: auth,
    );
  }

  /// Creates a new [Proxy] with basic authentication
  Proxy withBasicAuth(String username, String password) {
    return withAuth(ProxyAuth.basic(username: username, password: password));
  }

  /// Returns the proxy URL in the format 'http(s)://ip:port'
  String get url => '${isHttps ? 'https' : 'http'}://$ip:$port';

  /// Returns the host (IP address) of the proxy
  String get host => ip;

  /// Returns a string representation of the proxy in the format 'ip:port'
  @override
  String toString() => '$ip:$port';
}
