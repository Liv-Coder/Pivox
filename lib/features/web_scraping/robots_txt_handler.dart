import 'dart:async';
import 'package:http/http.dart' as http;

import '../proxy_management/presentation/managers/proxy_manager.dart';
import '../http_integration/http/http_proxy_client.dart';
import 'scraping_logger.dart';

/// A class for handling robots.txt files
class RobotsTxtHandler {
  /// Map of domains to their robots.txt rules
  final Map<String, RobotsTxtRules> _cachedRules = {};

  /// The HTTP client for fetching robots.txt files
  final http.Client _httpClient;

  /// The logger for logging operations
  final ScrapingLogger _logger;

  /// Default user agent for fetching robots.txt files
  final String _defaultUserAgent;

  /// Whether to respect robots.txt rules
  final bool _respectRobotsTxt;

  /// Cache expiration time in milliseconds
  final int _cacheExpirationMs;

  /// Creates a new [RobotsTxtHandler] with the given parameters
  ///
  /// [httpClient] is the HTTP client to use for fetching robots.txt files
  /// [logger] is the logger to use for logging operations
  /// [defaultUserAgent] is the default user agent to use for fetching robots.txt files
  /// [respectRobotsTxt] determines whether to respect robots.txt rules
  /// [cacheExpirationMs] is the cache expiration time in milliseconds
  RobotsTxtHandler({
    http.Client? httpClient,
    ProxyManager? proxyManager,
    ScrapingLogger? logger,
    String? defaultUserAgent,
    bool respectRobotsTxt = true,
    int cacheExpirationMs = 3600000, // 1 hour
  }) : _httpClient =
           httpClient ??
           (proxyManager != null
               ? ProxyHttpClient(
                 proxyManager: proxyManager,
                 useValidatedProxies: true,
                 rotateProxies: true,
               )
               : http.Client()),
       _logger = logger ?? ScrapingLogger(),
       _defaultUserAgent =
           defaultUserAgent ??
           'Mozilla/5.0 (compatible; PivoxBot/1.0; +https://github.com/Liv-Coder/Pivox-)',
       _respectRobotsTxt = respectRobotsTxt,
       _cacheExpirationMs = cacheExpirationMs;

  /// Checks if a URL is allowed to be crawled
  ///
  /// [url] is the URL to check
  /// [userAgent] is the user agent to check against
  Future<bool> isAllowed(String url, [String? userAgent]) async {
    if (!_respectRobotsTxt) {
      return true;
    }

    final effectiveUserAgent = userAgent ?? _defaultUserAgent;
    final domain = _extractDomain(url);
    final path = _extractPath(url);

    // Get the rules for this domain
    final rules = await getRules(domain);
    if (rules == null) {
      // If we don't have rules for this domain, assume allowed
      return true;
    }

    return rules.isAllowed(path, effectiveUserAgent);
  }

  /// Gets the robots.txt rules for a domain
  ///
  /// [domain] is the domain to get rules for
  Future<RobotsTxtRules?> getRules(String domain) async {
    if (!_respectRobotsTxt) {
      return RobotsTxtRules.empty();
    }

    // Check if we need to fetch the robots.txt file
    if (!_cachedRules.containsKey(domain) ||
        _cachedRules[domain]!.isExpired(_cacheExpirationMs)) {
      try {
        await _fetchRobotsTxt(domain);
      } catch (e) {
        _logger.error('Error fetching robots.txt for $domain: $e');
        // If we can't fetch the robots.txt file, return null
        return null;
      }
    }

    return _cachedRules[domain];
  }

  /// Fetches and parses the robots.txt file for a domain
  Future<void> _fetchRobotsTxt(String domain) async {
    final url = 'https://$domain/robots.txt';
    _logger.info('Fetching robots.txt from $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'User-Agent': _defaultUserAgent},
      );

      if (response.statusCode == 200) {
        final content = response.body;
        final rules = RobotsTxtRules.parse(content);
        _cachedRules[domain] = rules;
        _logger.info('Successfully parsed robots.txt for $domain');
      } else if (response.statusCode == 404) {
        // No robots.txt file, create empty rules
        _cachedRules[domain] = RobotsTxtRules.empty();
        _logger.info('No robots.txt found for $domain');
      } else {
        _logger.warning(
          'Failed to fetch robots.txt for $domain: ${response.statusCode}',
        );
        // If we can't fetch the robots.txt file, create empty rules
        _cachedRules[domain] = RobotsTxtRules.empty();
      }
    } catch (e) {
      _logger.error('Error fetching robots.txt for $domain: $e');
      // If we can't fetch the robots.txt file, create empty rules
      _cachedRules[domain] = RobotsTxtRules.empty();
      rethrow;
    }
  }

  /// Extracts the domain from a URL
  String _extractDomain(String url) {
    Uri uri;
    try {
      // Ensure URL has proper scheme
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      uri = Uri.parse(url);
    } catch (_) {
      return url;
    }

    return uri.host;
  }

  /// Extracts the path from a URL
  String _extractPath(String url) {
    Uri uri;
    try {
      // Ensure URL has proper scheme
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      uri = Uri.parse(url);
    } catch (_) {
      return '/';
    }

    return uri.path.isEmpty ? '/' : uri.path;
  }

  /// Clears the cached rules
  void clearCache() {
    _cachedRules.clear();
  }

  /// Closes the HTTP client
  void close() {
    _httpClient.close();
  }
}

/// A class for representing robots.txt rules
class RobotsTxtRules {
  /// Map of user agents to their disallowed paths
  final Map<String, List<String>> _disallowedPaths = {};

  /// Map of user agents to their allowed paths
  final Map<String, List<String>> _allowedPaths = {};

  /// Map of user agents to their crawl delays
  final Map<String, int> _crawlDelays = {};

  /// The time when the rules were created
  final DateTime _createdAt = DateTime.now();

  /// Creates a new empty [RobotsTxtRules]
  RobotsTxtRules.empty();

  /// Parses robots.txt content into rules
  factory RobotsTxtRules.parse(String content) {
    final rules = RobotsTxtRules.empty();
    final lines = content.split('\n');
    String? currentUserAgent;

    for (var line in lines) {
      // Remove comments
      final commentIndex = line.indexOf('#');
      if (commentIndex >= 0) {
        line = line.substring(0, commentIndex);
      }

      // Trim whitespace
      line = line.trim();
      if (line.isEmpty) continue;

      // Parse the line
      if (line.toLowerCase().startsWith('user-agent:')) {
        final userAgent = _extractValue(line, 'user-agent:');
        if (userAgent.isNotEmpty) {
          currentUserAgent = userAgent.toLowerCase();
        }
      } else if (line.toLowerCase().startsWith('disallow:')) {
        if (currentUserAgent != null) {
          final path = _extractValue(line, 'disallow:');
          if (path.isNotEmpty) {
            rules._disallowedPaths.putIfAbsent(currentUserAgent, () => []);
            rules._disallowedPaths[currentUserAgent]!.add(path);
          }
        }
      } else if (line.toLowerCase().startsWith('allow:')) {
        if (currentUserAgent != null) {
          final path = _extractValue(line, 'allow:');
          if (path.isNotEmpty) {
            rules._allowedPaths.putIfAbsent(currentUserAgent, () => []);
            rules._allowedPaths[currentUserAgent]!.add(path);
          }
        }
      } else if (line.toLowerCase().startsWith('crawl-delay:')) {
        if (currentUserAgent != null) {
          final delayStr = _extractValue(line, 'crawl-delay:');
          if (delayStr.isNotEmpty) {
            try {
              final delay = int.parse(delayStr);
              rules._crawlDelays[currentUserAgent] = delay;
            } catch (_) {
              // Ignore invalid crawl delays
            }
          }
        }
      }
    }

    return rules;
  }

  /// Extracts a value from a line
  static String _extractValue(String line, String prefix) {
    final prefixLength = prefix.length;
    if (line.length <= prefixLength) return '';
    return line.substring(prefixLength).trim();
  }

  /// Checks if a path is allowed for a user agent
  bool isAllowed(String path, String userAgent) {
    // Normalize the path
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    // Check if there are rules for this user agent
    final userAgentLower = userAgent.toLowerCase();
    final specificRules = _findSpecificUserAgent(userAgentLower);
    final wildcardRules = _disallowedPaths['*'] ?? [];

    // If no rules for this user agent or wildcard, assume allowed
    if (specificRules == null && wildcardRules.isEmpty) {
      return true;
    }

    // Check specific rules first
    if (specificRules != null) {
      // Check allowed paths first (they take precedence)
      final allowedPaths = _allowedPaths[specificRules] ?? [];
      for (final allowedPath in allowedPaths) {
        if (_pathMatches(path, allowedPath)) {
          return true;
        }
      }

      // Check disallowed paths
      final disallowedPaths = _disallowedPaths[specificRules] ?? [];
      for (final disallowedPath in disallowedPaths) {
        if (_pathMatches(path, disallowedPath)) {
          return false;
        }
      }
    }

    // Check wildcard rules if no specific rules matched
    // Check allowed paths first (they take precedence)
    final wildcardAllowedPaths = _allowedPaths['*'] ?? [];
    for (final allowedPath in wildcardAllowedPaths) {
      if (_pathMatches(path, allowedPath)) {
        return true;
      }
    }

    // Check disallowed paths
    for (final disallowedPath in wildcardRules) {
      if (_pathMatches(path, disallowedPath)) {
        return false;
      }
    }

    // If no rules matched, assume allowed
    return true;
  }

  /// Finds the most specific user agent that matches the given user agent
  String? _findSpecificUserAgent(String userAgent) {
    // Check for exact match
    if (_disallowedPaths.containsKey(userAgent)) {
      return userAgent;
    }

    // Check for partial matches
    for (final agent in _disallowedPaths.keys) {
      if (agent != '*' && userAgent.contains(agent)) {
        return agent;
      }
    }

    return null;
  }

  /// Checks if a path matches a pattern
  bool _pathMatches(String path, String pattern) {
    // Exact match
    if (pattern == path) {
      return true;
    }

    // Wildcard match
    if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return path.startsWith(prefix);
    }

    // Directory match
    if (pattern.endsWith('/')) {
      return path.startsWith(pattern);
    }

    return false;
  }

  /// Gets the crawl delay for a user agent in milliseconds
  int? getCrawlDelay(String userAgent) {
    final userAgentLower = userAgent.toLowerCase();
    final specificAgent = _findSpecificUserAgent(userAgentLower);

    if (specificAgent != null && _crawlDelays.containsKey(specificAgent)) {
      return _crawlDelays[specificAgent]! * 1000; // Convert to milliseconds
    }

    // Check wildcard
    if (_crawlDelays.containsKey('*')) {
      return _crawlDelays['*']! * 1000; // Convert to milliseconds
    }

    return null;
  }

  /// Checks if the rules are expired
  bool isExpired(int expirationMs) {
    final now = DateTime.now();
    final age = now.difference(_createdAt).inMilliseconds;
    return age > expirationMs;
  }
}
