import 'dart:math';

import '../proxy_management/domain/entities/proxy.dart';
import 'site_reputation_tracker.dart';

/// Defines the strategy for scraping a website
class ScrapingStrategy {
  /// The number of retries to use
  final int retries;

  /// The timeout in milliseconds
  final int timeout;

  /// The headers to use
  final Map<String, String> headers;

  /// The initial backoff in milliseconds
  final int initialBackoff;

  /// The backoff multiplier
  final double backoffMultiplier;

  /// The maximum backoff in milliseconds
  final int maxBackoff;

  /// Whether to use a random user agent
  final bool useRandomUserAgent;

  /// Whether to rotate proxies on each retry
  final bool rotateProxiesOnRetry;

  /// Whether to validate proxies before using them
  final bool validateProxies;

  /// Creates a new [ScrapingStrategy]
  ScrapingStrategy({
    required this.retries,
    required this.timeout,
    required this.headers,
    required this.initialBackoff,
    required this.backoffMultiplier,
    required this.maxBackoff,
    required this.useRandomUserAgent,
    required this.rotateProxiesOnRetry,
    required this.validateProxies,
  });

  /// Creates a copy of this strategy with the given parameters
  ScrapingStrategy copyWith({
    int? retries,
    int? timeout,
    Map<String, String>? headers,
    int? initialBackoff,
    double? backoffMultiplier,
    int? maxBackoff,
    bool? useRandomUserAgent,
    bool? rotateProxiesOnRetry,
    bool? validateProxies,
  }) {
    return ScrapingStrategy(
      retries: retries ?? this.retries,
      timeout: timeout ?? this.timeout,
      headers: headers ?? Map.from(this.headers),
      initialBackoff: initialBackoff ?? this.initialBackoff,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      maxBackoff: maxBackoff ?? this.maxBackoff,
      useRandomUserAgent: useRandomUserAgent ?? this.useRandomUserAgent,
      rotateProxiesOnRetry: rotateProxiesOnRetry ?? this.rotateProxiesOnRetry,
      validateProxies: validateProxies ?? this.validateProxies,
    );
  }
}

/// Generates adaptive scraping strategies based on site reputation and error patterns
class AdaptiveScrapingStrategy {
  /// The site reputation tracker
  final SiteReputationTracker _reputationTracker;

  /// The default strategy to use
  final ScrapingStrategy _defaultStrategy;

  /// List of user agents to rotate through
  final List<String> _userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPad; CPU OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Android 11; Mobile; rv:68.0) Gecko/68.0 Firefox/88.0',
    'Mozilla/5.0 (Linux; Android 11; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
  ];

  /// Random number generator
  final Random _random = Random();

  /// Creates a new [AdaptiveScrapingStrategy]
  AdaptiveScrapingStrategy({
    SiteReputationTracker? reputationTracker,
    ScrapingStrategy? defaultStrategy,
  }) : _reputationTracker = reputationTracker ?? SiteReputationTracker(),
       _defaultStrategy =
           defaultStrategy ??
           ScrapingStrategy(
             retries: 3,
             timeout: 30000,
             headers: {
               'User-Agent':
                   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
               'Accept':
                   'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
             },
             initialBackoff: 1000,
             backoffMultiplier: 1.5,
             maxBackoff: 10000,
             useRandomUserAgent: false,
             rotateProxiesOnRetry: true,
             validateProxies: true,
           );

  /// Gets the site reputation tracker
  SiteReputationTracker get reputationTracker => _reputationTracker;

  /// Gets the optimal strategy for the given URL
  ScrapingStrategy getStrategyForUrl(String url) {
    final isProblematic = _reputationTracker.isProblematicSite(url);
    final reputation = _reputationTracker.getReputation(url);

    // Start with the default strategy
    ScrapingStrategy strategy = _defaultStrategy;

    // If the site is problematic, adjust the strategy
    if (isProblematic) {
      strategy = strategy.copyWith(
        retries: strategy.retries * 2,
        timeout: strategy.timeout * 2,
        initialBackoff:
            (strategy.initialBackoff * 0.5).toInt(), // Shorter initial backoff
        useRandomUserAgent: true,
        rotateProxiesOnRetry: true,
        validateProxies: true,
      );
    }

    // If we have reputation data, further refine the strategy
    if (reputation != null) {
      // Adjust headers based on reputation
      final headers = _reputationTracker.getOptimalHeaders(
        url,
        strategy.headers,
      );

      // Adjust timeout based on reputation
      final timeout = _reputationTracker.getOptimalTimeout(
        url,
        strategy.timeout,
      );

      // Adjust retries based on reputation
      final retries = _reputationTracker.getOptimalRetries(
        url,
        strategy.retries,
      );

      strategy = strategy.copyWith(
        headers: headers,
        timeout: timeout,
        retries: retries,
      );

      // If the site has specific error patterns, make further adjustments
      if (reputation.hasErrorPattern('timeout')) {
        strategy = strategy.copyWith(
          timeout: strategy.timeout * 2,
          backoffMultiplier: 2.0, // More aggressive backoff
        );
      }

      if (reputation.hasErrorPattern('connection closed') ||
          reputation.hasErrorPattern('connection reset')) {
        strategy = strategy.copyWith(
          initialBackoff:
              (strategy.initialBackoff * 0.3)
                  .toInt(), // Even shorter initial backoff
          rotateProxiesOnRetry: true,
        );
      }

      if (reputation.hasErrorPattern('ssl') ||
          reputation.hasErrorPattern('certificate')) {
        // Add SSL-specific headers
        final sslHeaders = Map<String, String>.from(strategy.headers);
        sslHeaders['Sec-Fetch-Dest'] = 'document';
        sslHeaders['Sec-Fetch-Mode'] = 'navigate';
        sslHeaders['Sec-Fetch-Site'] = 'none';
        sslHeaders['Sec-Fetch-User'] = '?1';

        strategy = strategy.copyWith(headers: sslHeaders);
      }
    }

    // If using random user agent, select one
    if (strategy.useRandomUserAgent) {
      final headers = Map<String, String>.from(strategy.headers);
      headers['User-Agent'] = _getRandomUserAgent();
      strategy = strategy.copyWith(headers: headers);
    }

    return strategy;
  }

  /// Records a successful scrape for the given URL
  void recordSuccess(String url) {
    _reputationTracker.recordSuccess(url);
  }

  /// Records a failed scrape for the given URL with the error message
  void recordFailure(String url, String errorMessage) {
    _reputationTracker.recordFailure(url, errorMessage);
  }

  /// Gets a random user agent
  String _getRandomUserAgent() {
    return _userAgents[_random.nextInt(_userAgents.length)];
  }

  /// Gets the optimal proxy for the given URL and error pattern
  Proxy? selectOptimalProxy(
    String url,
    List<Proxy> availableProxies,
    String? lastErrorMessage,
  ) {
    if (availableProxies.isEmpty) return null;

    // If we have an error message, try to select a proxy that might work better
    if (lastErrorMessage != null) {
      final lowerError = lastErrorMessage.toLowerCase();

      // For connection issues, prefer proxies with different IPs
      if (lowerError.contains('connection closed') ||
          lowerError.contains('connection reset') ||
          lowerError.contains('timeout')) {
        // Try to find a proxy with a different IP class
        final lastProxy = availableProxies.last;
        final differentClassProxies = availableProxies.where(
          (p) => !p.ip.startsWith(lastProxy.ip.split('.').first),
        );

        if (differentClassProxies.isNotEmpty) {
          return differentClassProxies.first;
        }
      }

      // For SSL issues, prefer proxies with different IPs
      if (lowerError.contains('ssl') || lowerError.contains('certificate')) {
        // Try to find a different proxy
        if (availableProxies.length > 1) {
          return availableProxies[1]; // Return the second proxy in the list
        }
      }
    }

    // Default to the first available proxy
    return availableProxies.first;
  }
}
