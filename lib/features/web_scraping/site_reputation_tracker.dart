/// Tracks the reputation and success rate of websites for scraping
class SiteReputationTracker {
  /// Map of domain to site reputation data
  final Map<String, SiteReputation> _siteReputations = {};

  /// Cache of problematic error patterns
  final Set<String> _knownErrorPatterns = {
    'connection closed before full header was received',
    'connection reset by peer',
    'failed to connect',
    'timeout',
    'ssl handshake',
    'certificate verify failed',
    'too many redirects',
    'proxy connection failed',
  };

  /// Maximum number of sites to track
  final int _maxSites;

  /// Creates a new [SiteReputationTracker]
  SiteReputationTracker({int maxSites = 100}) : _maxSites = maxSites;

  /// Records a successful scrape for the given URL
  void recordSuccess(String url) {
    final domain = _extractDomain(url);
    if (domain == null) return;

    _siteReputations.putIfAbsent(domain, () => SiteReputation(domain));
    _siteReputations[domain]!.recordSuccess();
    _pruneOldEntries();
  }

  /// Records a failed scrape for the given URL with the error message
  void recordFailure(String url, String errorMessage) {
    final domain = _extractDomain(url);
    if (domain == null) return;

    _siteReputations.putIfAbsent(domain, () => SiteReputation(domain));
    _siteReputations[domain]!.recordFailure(errorMessage);
    _pruneOldEntries();
  }

  /// Gets the reputation for the given URL
  SiteReputation? getReputation(String url) {
    final domain = _extractDomain(url);
    if (domain == null) return null;

    return _siteReputations[domain];
  }

  /// Checks if a site is problematic based on its reputation
  bool isProblematicSite(String url) {
    final domain = _extractDomain(url);
    if (domain == null) return false;

    // If we have reputation data, use it
    if (_siteReputations.containsKey(domain)) {
      final reputation = _siteReputations[domain]!;

      // Sites with low success rates are problematic
      if (reputation.successRate < 0.5 && reputation.totalAttempts >= 3) {
        return true;
      }

      // Sites with specific error patterns are problematic
      if (reputation.hasProblematicErrors) {
        return true;
      }
    }

    // Check for known problematic patterns in the URL
    if (url.contains('443') || url.contains(':443')) {
      return true; // Port 443 often has issues
    }

    return false;
  }

  /// Gets the optimal headers for the given URL based on past success
  Map<String, String> getOptimalHeaders(
    String url,
    Map<String, String> defaultHeaders,
  ) {
    final domain = _extractDomain(url);
    if (domain == null) return defaultHeaders;

    if (_siteReputations.containsKey(domain)) {
      final reputation = _siteReputations[domain]!;

      // If the site has a low success rate, add more browser-like headers
      if (reputation.successRate < 0.7) {
        final enhancedHeaders = Map<String, String>.from(defaultHeaders);
        enhancedHeaders['Accept'] =
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8';
        enhancedHeaders['Accept-Language'] = 'en-US,en;q=0.5';
        enhancedHeaders['Connection'] = 'keep-alive';
        enhancedHeaders['Upgrade-Insecure-Requests'] = '1';
        enhancedHeaders['Cache-Control'] = 'max-age=0';

        // Add more headers based on the specific error patterns
        if (reputation.hasErrorPattern('timeout')) {
          enhancedHeaders['Keep-Alive'] = 'timeout=15, max=100';
        }

        if (reputation.hasErrorPattern('ssl') ||
            reputation.hasErrorPattern('certificate')) {
          enhancedHeaders['Sec-Fetch-Dest'] = 'document';
          enhancedHeaders['Sec-Fetch-Mode'] = 'navigate';
          enhancedHeaders['Sec-Fetch-Site'] = 'none';
          enhancedHeaders['Sec-Fetch-User'] = '?1';
        }

        return enhancedHeaders;
      }
    }

    return defaultHeaders;
  }

  /// Gets the optimal timeout for the given URL based on past performance
  int getOptimalTimeout(String url, int defaultTimeout) {
    final domain = _extractDomain(url);
    if (domain == null) return defaultTimeout;

    if (_siteReputations.containsKey(domain)) {
      final reputation = _siteReputations[domain]!;

      // If the site has timeout issues, increase the timeout
      if (reputation.hasErrorPattern('timeout')) {
        return defaultTimeout * 2;
      }

      // If the site has connection issues, increase the timeout
      if (reputation.hasErrorPattern('connection')) {
        return defaultTimeout * 2;
      }
    }

    return defaultTimeout;
  }

  /// Gets the optimal number of retries for the given URL based on past performance
  int getOptimalRetries(String url, int defaultRetries) {
    final domain = _extractDomain(url);
    if (domain == null) return defaultRetries;

    if (_siteReputations.containsKey(domain)) {
      final reputation = _siteReputations[domain]!;

      // If the site has a low success rate, increase the retries
      if (reputation.successRate < 0.5) {
        return defaultRetries * 2;
      }

      // If the site has specific error patterns, adjust retries
      if (reputation.hasProblematicErrors) {
        return defaultRetries * 2;
      }
    }

    return defaultRetries;
  }

  /// Checks if the given error message contains any known problematic patterns
  bool hasProblematicErrorPattern(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    for (final pattern in _knownErrorPatterns) {
      if (lowerError.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Extracts the domain from a URL
  String? _extractDomain(String url) {
    try {
      // Ensure URL has a scheme
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Prunes old entries to keep the map size under control
  void _pruneOldEntries() {
    if (_siteReputations.length <= _maxSites) return;

    // Sort by last access time and remove the oldest
    final entries =
        _siteReputations.entries.toList()..sort(
          (a, b) => a.value.lastAccessTime.compareTo(b.value.lastAccessTime),
        );

    // Remove the oldest entries
    for (int i = 0; i < entries.length - _maxSites; i++) {
      _siteReputations.remove(entries[i].key);
    }
  }
}

/// Represents the reputation of a website for scraping
class SiteReputation {
  /// The domain of the site
  final String domain;

  /// Number of successful scrapes
  int _successCount = 0;

  /// Number of failed scrapes
  int _failureCount = 0;

  /// Map of error patterns to occurrence count
  final Map<String, int> _errorPatterns = {};

  /// Last access time
  DateTime _lastAccessTime = DateTime.now();

  /// Creates a new [SiteReputation] for the given domain
  SiteReputation(this.domain);

  /// Records a successful scrape
  void recordSuccess() {
    _successCount++;
    _lastAccessTime = DateTime.now();
  }

  /// Records a failed scrape with the error message
  void recordFailure(String errorMessage) {
    _failureCount++;
    _lastAccessTime = DateTime.now();

    // Extract error patterns
    final lowerError = errorMessage.toLowerCase();

    // Check for common error patterns
    final patterns = [
      'connection closed',
      'connection reset',
      'timeout',
      'ssl',
      'certificate',
      'proxy',
      'redirect',
      'refused',
      'failed to connect',
    ];

    for (final pattern in patterns) {
      if (lowerError.contains(pattern)) {
        _errorPatterns[pattern] = (_errorPatterns[pattern] ?? 0) + 1;
      }
    }
  }

  /// Gets the success rate (0.0 to 1.0)
  double get successRate {
    final total = totalAttempts;
    if (total == 0) return 0.0;
    return _successCount / total;
  }

  /// Gets the total number of scrape attempts
  int get totalAttempts => _successCount + _failureCount;

  /// Gets the last access time
  DateTime get lastAccessTime => _lastAccessTime;

  /// Checks if the site has the given error pattern
  bool hasErrorPattern(String pattern) {
    return _errorPatterns.containsKey(pattern) && _errorPatterns[pattern]! > 0;
  }

  /// Checks if the site has any problematic error patterns
  bool get hasProblematicErrors {
    final problematicPatterns = [
      'connection closed',
      'connection reset',
      'timeout',
      'ssl',
      'certificate',
    ];

    for (final pattern in problematicPatterns) {
      if (hasErrorPattern(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Gets the most common error pattern
  String? get mostCommonErrorPattern {
    if (_errorPatterns.isEmpty) return null;

    String? mostCommon;
    int maxCount = 0;

    _errorPatterns.forEach((pattern, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = pattern;
      }
    });

    return mostCommon;
  }

  @override
  String toString() {
    return 'SiteReputation{domain: $domain, successRate: ${(successRate * 100).toStringAsFixed(1)}%, '
        'attempts: $totalAttempts, errors: $_errorPatterns}';
  }
}
