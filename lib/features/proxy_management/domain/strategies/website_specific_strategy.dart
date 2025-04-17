import 'dart:math';

import '../../../../core/utils/logger.dart';
import '../entities/proxy.dart';
import 'rotation_strategy.dart';

/// A fingerprint for a website
class WebsiteFingerprint {
  /// The domain of the website
  final String domain;

  /// Whether the website uses IP-based blocking
  final bool usesIpBlocking;

  /// Whether the website uses session-based blocking
  final bool usesSessionBlocking;

  /// Whether the website uses geolocation restrictions
  final bool usesGeoRestrictions;

  /// Whether the website uses rate limiting
  final bool usesRateLimiting;

  /// The rate limit in requests per minute
  final int? rateLimitPerMinute;

  /// The preferred countries for this website
  final List<String> preferredCountries;

  /// The blocked countries for this website
  final List<String> blockedCountries;

  /// The success rate threshold for proxies
  final double successRateThreshold;

  /// Creates a new [WebsiteFingerprint]
  WebsiteFingerprint({
    required this.domain,
    this.usesIpBlocking = false,
    this.usesSessionBlocking = false,
    this.usesGeoRestrictions = false,
    this.usesRateLimiting = false,
    this.rateLimitPerMinute,
    this.preferredCountries = const [],
    this.blockedCountries = const [],
    this.successRateThreshold = 0.7,
  });

  @override
  String toString() {
    return 'WebsiteFingerprint{domain: $domain, '
        'usesIpBlocking: $usesIpBlocking, '
        'usesSessionBlocking: $usesSessionBlocking, '
        'usesGeoRestrictions: $usesGeoRestrictions, '
        'usesRateLimiting: $usesRateLimiting, '
        'rateLimitPerMinute: $rateLimitPerMinute, '
        'preferredCountries: $preferredCountries, '
        'blockedCountries: $blockedCountries, '
        'successRateThreshold: $successRateThreshold}';
  }
}

/// A proxy rotation strategy that adapts to specific websites
class WebsiteSpecificStrategy implements RotationStrategy {
  /// The website fingerprints by domain
  final Map<String, WebsiteFingerprint> _fingerprints = {};

  /// The proxy success rates by domain and proxy
  final Map<String, Map<String, double>> _successRatesByDomain = {};

  /// The proxy failure counts by domain and proxy
  final Map<String, Map<String, int>> _failureCountsByDomain = {};

  /// The proxy success counts by domain and proxy
  final Map<String, Map<String, int>> _successCountsByDomain = {};

  /// The default fingerprint to use for unknown domains
  final WebsiteFingerprint _defaultFingerprint;

  /// Random number generator for selection
  final Random _random;

  /// Logger for logging operations
  final Logger? logger;

  /// Creates a new [WebsiteSpecificStrategy]
  WebsiteSpecificStrategy({
    WebsiteFingerprint? defaultFingerprint,
    Random? random,
    this.logger,
  }) : _defaultFingerprint =
           defaultFingerprint ??
           WebsiteFingerprint(
             domain: '*',
             usesIpBlocking: true,
             usesRateLimiting: true,
             rateLimitPerMinute: 30,
           ),
       _random = random ?? Random();

  /// Adds a fingerprint for a domain
  void addFingerprint(WebsiteFingerprint fingerprint) {
    _fingerprints[fingerprint.domain] = fingerprint;
    logger?.info('Added fingerprint for ${fingerprint.domain}');
  }

  /// Gets the fingerprint for a domain
  WebsiteFingerprint getFingerprintForDomain(String domain) {
    return _fingerprints[domain] ?? _defaultFingerprint;
  }

  /// Records a successful request for a domain and proxy
  void recordSuccess(String domain, Proxy proxy) {
    final proxyKey = '${proxy.host}:${proxy.port}';

    // Initialize maps if needed
    _successCountsByDomain.putIfAbsent(domain, () => {});
    _failureCountsByDomain.putIfAbsent(domain, () => {});
    _successRatesByDomain.putIfAbsent(domain, () => {});

    // Update counts
    _successCountsByDomain[domain]![proxyKey] =
        (_successCountsByDomain[domain]![proxyKey] ?? 0) + 1;

    // Update success rate
    final successCount = _successCountsByDomain[domain]![proxyKey] ?? 0;
    final failureCount = _failureCountsByDomain[domain]![proxyKey] ?? 0;
    final totalCount = successCount + failureCount;

    if (totalCount > 0) {
      _successRatesByDomain[domain]![proxyKey] = successCount / totalCount;
    }
  }

  /// Records a failed request for a domain and proxy
  void recordFailure(String domain, Proxy proxy) {
    final proxyKey = '${proxy.host}:${proxy.port}';

    // Initialize maps if needed
    _successCountsByDomain.putIfAbsent(domain, () => {});
    _failureCountsByDomain.putIfAbsent(domain, () => {});
    _successRatesByDomain.putIfAbsent(domain, () => {});

    // Update counts
    _failureCountsByDomain[domain]![proxyKey] =
        (_failureCountsByDomain[domain]![proxyKey] ?? 0) + 1;

    // Update success rate
    final successCount = _successCountsByDomain[domain]![proxyKey] ?? 0;
    final failureCount = _failureCountsByDomain[domain]![proxyKey] ?? 0;
    final totalCount = successCount + failureCount;

    if (totalCount > 0) {
      _successRatesByDomain[domain]![proxyKey] = successCount / totalCount;
    }
  }

  /// Gets the success rate for a domain and proxy
  double getSuccessRate(String domain, Proxy proxy) {
    final proxyKey = '${proxy.host}:${proxy.port}';
    return _successRatesByDomain[domain]?[proxyKey] ?? 0.0;
  }

  /// Selects a proxy for a domain
  Proxy selectProxyForDomain(String domain, List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw Exception('No proxies available');
    }

    // Get the fingerprint for this domain
    final fingerprint = getFingerprintForDomain(domain);

    // Filter proxies based on the fingerprint
    List<Proxy> filteredProxies = proxies;

    // Filter by country if geo restrictions are used
    if (fingerprint.usesGeoRestrictions) {
      // Filter out blocked countries
      if (fingerprint.blockedCountries.isNotEmpty) {
        filteredProxies =
            filteredProxies
                .where(
                  (proxy) =>
                      proxy.country == null ||
                      !fingerprint.blockedCountries.contains(
                        proxy.country!.toLowerCase(),
                      ),
                )
                .toList();
      }

      // Prefer proxies from preferred countries
      if (fingerprint.preferredCountries.isNotEmpty) {
        final preferredProxies =
            filteredProxies
                .where(
                  (proxy) =>
                      proxy.country != null &&
                      fingerprint.preferredCountries.contains(
                        proxy.country!.toLowerCase(),
                      ),
                )
                .toList();

        if (preferredProxies.isNotEmpty) {
          filteredProxies = preferredProxies;
        }
      }
    }

    // Filter by success rate if IP blocking is used
    if (fingerprint.usesIpBlocking) {
      // Get success rates for this domain
      final successRates = _successRatesByDomain[domain] ?? {};

      // Filter proxies with success rate above threshold
      final goodProxies =
          filteredProxies.where((proxy) {
            final proxyKey = '${proxy.host}:${proxy.port}';
            final successRate = successRates[proxyKey] ?? 0.0;
            final totalRequests =
                (_successCountsByDomain[domain]?[proxyKey] ?? 0) +
                (_failureCountsByDomain[domain]?[proxyKey] ?? 0);

            // If we have enough data, use the success rate
            if (totalRequests >= 3) {
              return successRate >= fingerprint.successRateThreshold;
            }

            // Otherwise, use the proxy's overall score if available
            return (proxy.score?.successRate ?? 0.0) >=
                fingerprint.successRateThreshold;
          }).toList();

      if (goodProxies.isNotEmpty) {
        filteredProxies = goodProxies;
      }
    }

    // If no proxies match the criteria, use the original list
    if (filteredProxies.isEmpty) {
      filteredProxies = proxies;
    }

    // Select a proxy based on weighted scores
    return _selectByScore(filteredProxies, domain);
  }

  /// Selects a proxy based on score
  Proxy _selectByScore(List<Proxy> proxies, String domain) {
    if (proxies.length == 1) {
      return proxies.first;
    }

    // Calculate weights based on scores
    final weights = <double>[];
    double totalWeight = 0.0;

    for (final proxy in proxies) {
      // Get the domain-specific success rate
      final proxyKey = '${proxy.host}:${proxy.port}';
      final domainSuccessRate = _successRatesByDomain[domain]?[proxyKey] ?? 0.0;

      // Calculate weight based on domain success rate and overall score
      final weight =
          domainSuccessRate * 0.7 + (proxy.score?.compositeScore ?? 0.5) * 0.3;
      weights.add(max(0.1, weight)); // Ensure a minimum weight
      totalWeight += weights.last;
    }

    // Normalize weights
    for (int i = 0; i < weights.length; i++) {
      weights[i] = weights[i] / totalWeight;
    }

    // Select a proxy based on weights
    final randomValue = _random.nextDouble();
    double cumulativeWeight = 0.0;

    for (int i = 0; i < proxies.length; i++) {
      cumulativeWeight += weights[i];
      if (randomValue <= cumulativeWeight) {
        return proxies[i];
      }
    }

    // Fallback (should never reach here)
    return proxies.last;
  }

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    // This method is called without a domain context
    // Use a generic selection based on overall scores
    if (proxies.isEmpty) {
      throw Exception('No proxies available');
    }

    return _selectByScore(proxies, '*');
  }

  @override
  String get name => 'WebsiteSpecific';

  @override
  String get description => 'Adapts proxy selection to specific websites';
}
