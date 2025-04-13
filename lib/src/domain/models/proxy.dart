class Proxy {
  final String host;
  final int port;
  final String? username;
  final String? password;
  final ProxyType type;
  final DateTime lastChecked;
  final int responseTime;
  final bool isActive;

  Proxy({
    required this.host,
    required this.port,
    this.username,
    this.password,
    required this.type,
    required this.lastChecked,
    required this.responseTime,
    this.isActive = true,
  });
}

enum ProxyType { http, https, socks4, socks5 }