/// Options for filtering proxies
class ProxyFilterOptions {
  /// Maximum number of proxies to return
  final int count;

  /// Whether to only include HTTPS proxies
  final bool onlyHttps;

  /// Filter by country code (ISO 3166-1 alpha-2)
  final String? countryCode;

  /// List of country codes to filter by
  final List<String>? countries;

  /// Filter by anonymity level (transparent, anonymous, elite)
  final String? anonymityLevel;

  /// Filter by minimum speed (in milliseconds)
  final int? minSpeed;

  /// Filter by maximum response time (in milliseconds)
  final int? maxResponseTime;

  /// Filter by minimum success rate (0.0 to 1.0)
  final double? minSuccessRate;

  /// Filter by protocol (http, https, socks4, socks5)
  final String? protocol;

  /// Filter by ISP
  final String? isp;

  /// List of ISPs to filter by
  final List<String>? isps;

  /// Filter by region/city
  final String? region;

  /// List of regions to filter by
  final List<String>? regions;

  /// Whether to only return proxies that support websockets
  final bool? requireWebsockets;

  /// Whether to only return proxies that support SOCKS protocol
  final bool? requireSocks;

  /// Specific SOCKS version to filter by
  final int? socksVersion;

  /// Whether to only return proxies that require authentication
  final bool? requireAuthentication;

  /// Whether to only return anonymous proxies
  final bool? requireAnonymous;

  /// Creates a new [ProxyFilterOptions] with the given parameters
  const ProxyFilterOptions({
    this.count = 10,
    this.onlyHttps = false,
    this.countryCode,
    this.countries,
    this.anonymityLevel,
    this.minSpeed,
    this.maxResponseTime,
    this.minSuccessRate,
    this.protocol,
    this.isp,
    this.isps,
    this.region,
    this.regions,
    this.requireWebsockets,
    this.requireSocks,
    this.socksVersion,
    this.requireAuthentication,
    this.requireAnonymous,
  });

  /// Creates a copy of this [ProxyFilterOptions] with the given parameters
  ProxyFilterOptions copyWith({
    int? count,
    bool? onlyHttps,
    String? countryCode,
    List<String>? countries,
    String? anonymityLevel,
    int? minSpeed,
    int? maxResponseTime,
    double? minSuccessRate,
    String? protocol,
    String? isp,
    List<String>? isps,
    String? region,
    List<String>? regions,
    bool? requireWebsockets,
    bool? requireSocks,
    int? socksVersion,
    bool? requireAuthentication,
    bool? requireAnonymous,
  }) {
    return ProxyFilterOptions(
      count: count ?? this.count,
      onlyHttps: onlyHttps ?? this.onlyHttps,
      countryCode: countryCode ?? this.countryCode,
      countries: countries ?? this.countries,
      anonymityLevel: anonymityLevel ?? this.anonymityLevel,
      minSpeed: minSpeed ?? this.minSpeed,
      maxResponseTime: maxResponseTime ?? this.maxResponseTime,
      minSuccessRate: minSuccessRate ?? this.minSuccessRate,
      protocol: protocol ?? this.protocol,
      isp: isp ?? this.isp,
      isps: isps ?? this.isps,
      region: region ?? this.region,
      regions: regions ?? this.regions,
      requireWebsockets: requireWebsockets ?? this.requireWebsockets,
      requireSocks: requireSocks ?? this.requireSocks,
      socksVersion: socksVersion ?? this.socksVersion,
      requireAuthentication:
          requireAuthentication ?? this.requireAuthentication,
      requireAnonymous: requireAnonymous ?? this.requireAnonymous,
    );
  }
}
