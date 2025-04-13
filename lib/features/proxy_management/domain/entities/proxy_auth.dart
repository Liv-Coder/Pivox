/// Authentication method for proxies
enum ProxyAuthMethod {
  /// No authentication
  none,
  
  /// Basic authentication (username/password)
  basic,
  
  /// Digest authentication
  digest,
  
  /// NTLM authentication
  ntlm,
}

/// Authentication credentials for a proxy
class ProxyAuth {
  /// Username for authentication
  final String username;
  
  /// Password for authentication
  final String password;
  
  /// Authentication method
  final ProxyAuthMethod method;
  
  /// Domain for NTLM authentication
  final String? domain;
  
  /// Creates a new [ProxyAuth] instance
  const ProxyAuth({
    required this.username,
    required this.password,
    this.method = ProxyAuthMethod.basic,
    this.domain,
  });
  
  /// Creates a new [ProxyAuth] instance with basic authentication
  factory ProxyAuth.basic({
    required String username,
    required String password,
  }) {
    return ProxyAuth(
      username: username,
      password: password,
      method: ProxyAuthMethod.basic,
    );
  }
  
  /// Creates a new [ProxyAuth] instance with digest authentication
  factory ProxyAuth.digest({
    required String username,
    required String password,
  }) {
    return ProxyAuth(
      username: username,
      password: password,
      method: ProxyAuthMethod.digest,
    );
  }
  
  /// Creates a new [ProxyAuth] instance with NTLM authentication
  factory ProxyAuth.ntlm({
    required String username,
    required String password,
    required String domain,
  }) {
    return ProxyAuth(
      username: username,
      password: password,
      method: ProxyAuthMethod.ntlm,
      domain: domain,
    );
  }
  
  /// Creates a copy of this [ProxyAuth] with the given parameters
  ProxyAuth copyWith({
    String? username,
    String? password,
    ProxyAuthMethod? method,
    String? domain,
  }) {
    return ProxyAuth(
      username: username ?? this.username,
      password: password ?? this.password,
      method: method ?? this.method,
      domain: domain ?? this.domain,
    );
  }
  
  /// Converts this [ProxyAuth] to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'method': method.index,
      if (domain != null) 'domain': domain,
    };
  }
  
  /// Creates a [ProxyAuth] from a JSON map
  factory ProxyAuth.fromJson(Map<String, dynamic> json) {
    return ProxyAuth(
      username: json['username'] as String,
      password: json['password'] as String,
      method: ProxyAuthMethod.values[json['method'] as int],
      domain: json['domain'] as String?,
    );
  }
}
