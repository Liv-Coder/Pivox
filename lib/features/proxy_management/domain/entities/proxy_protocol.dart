/// Protocol used by a proxy
enum ProxyProtocol {
  /// HTTP proxy
  http,

  /// HTTPS proxy
  https,

  /// SOCKS4 proxy
  socks4,

  /// SOCKS5 proxy
  socks5,
}

/// Extension methods for [ProxyProtocol]
extension ProxyProtocolExtension on ProxyProtocol {
  /// Returns the string representation of the protocol
  String get name {
    switch (this) {
      case ProxyProtocol.http:
        return 'HTTP';
      case ProxyProtocol.https:
        return 'HTTPS';
      case ProxyProtocol.socks4:
        return 'SOCKS4';
      case ProxyProtocol.socks5:
        return 'SOCKS5';
    }
  }

  /// Returns true if this is a SOCKS protocol
  bool get isSocks =>
      this == ProxyProtocol.socks4 || this == ProxyProtocol.socks5;

  /// Returns true if this is an HTTP protocol
  bool get isHttp => this == ProxyProtocol.http || this == ProxyProtocol.https;

  /// Returns the SOCKS version if this is a SOCKS protocol
  int? get socksVersion {
    switch (this) {
      case ProxyProtocol.socks4:
        return 4;
      case ProxyProtocol.socks5:
        return 5;
      default:
        return null;
    }
  }
}
