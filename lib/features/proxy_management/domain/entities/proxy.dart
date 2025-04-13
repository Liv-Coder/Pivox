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
  
  /// Creates a new [Proxy] instance
  const Proxy({
    required this.ip,
    required this.port,
    this.countryCode,
    this.isHttps = false,
    this.anonymityLevel,
  });
  
  /// Returns the proxy URL in the format 'http(s)://ip:port'
  String get url => '${isHttps ? 'https' : 'http'}://$ip:$port';
  
  /// Returns a string representation of the proxy in the format 'ip:port'
  @override
  String toString() => '$ip:$port';
}
