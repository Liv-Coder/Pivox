import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'scraping_logger.dart';

/// A manager for dynamically fetching and using user agents
class DynamicUserAgentManager {
  /// List of user agents to rotate through
  final List<String> _userAgents = [];

  /// Map of site-specific user agents
  final Map<String, List<String>> _siteSpecificUserAgents = {};

  /// Random number generator
  final Random _random;

  /// Logger for logging user agent operations
  final ScrapingLogger? _logger;

  /// Whether the manager has been initialized
  bool _initialized = false;

  /// Creates a new [DynamicUserAgentManager]
  DynamicUserAgentManager({
    List<String>? initialUserAgents,
    Random? random,
    ScrapingLogger? logger,
  }) : _random = random ?? Random(),
       _logger = logger {
    if (initialUserAgents != null && initialUserAgents.isNotEmpty) {
      _userAgents.addAll(initialUserAgents);
      _initialized = true;
    } else {
      _userAgents.addAll(_defaultUserAgents);
    }
    
    // Initialize site-specific user agents
    _initializeSiteSpecificUserAgents();
  }

  /// Initializes the manager by fetching user agents from the web
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _logger?.info('Initializing dynamic user agent manager');
    
    try {
      // Try to fetch user agents from the web
      await _fetchUserAgentsFromWeb();
    } catch (e) {
      _logger?.error('Failed to fetch user agents from web: $e');
      _logger?.info('Using default user agents');
    }
    
    _initialized = true;
  }

  /// Fetches user agents from the web
  Future<void> _fetchUserAgentsFromWeb() async {
    try {
      // We'll use a public API that provides user agents
      final response = await http.get(
        Uri.parse('https://www.useragents.me/api'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final fetchedAgents = (data['data'] as List)
              .map((item) => item['ua'] as String?)
              .where((ua) => ua != null && ua.isNotEmpty)
              .cast<String>()
              .toList();
          
          if (fetchedAgents.isNotEmpty) {
            _logger?.info('Fetched ${fetchedAgents.length} user agents from web');
            _userAgents.addAll(fetchedAgents);
          }
        }
      }
    } catch (e) {
      _logger?.error('Error fetching user agents: $e');
      throw Exception('Failed to fetch user agents: $e');
    }
  }

  /// Initializes site-specific user agents
  void _initializeSiteSpecificUserAgents() {
    // Add user agents that work well with specific sites
    _siteSpecificUserAgents['onlinekhabar.com'] = [
      // Chrome on Windows
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36',
      // Firefox on Windows
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0',
      // Edge on Windows
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36 Edg/118.0.2088.76',
      // Mobile Chrome on Android
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36',
    ];
    
    _siteSpecificUserAgents['vegamovies'] = [
      // Chrome on Windows
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
      // Firefox on Windows
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0',
      // Mobile Chrome on Android
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36',
    ];
  }

  /// Gets a random user agent
  String getRandomUserAgent() {
    if (_userAgents.isEmpty) {
      return _defaultUserAgents.first;
    }

    final index = _random.nextInt(_userAgents.length);
    final userAgent = _userAgents[index];
    _logger?.info('Using random user agent: ${_truncateUserAgent(userAgent)}');
    return userAgent;
  }

  /// Gets a random user agent for a specific site
  String getRandomUserAgentForSite(String url) {
    // Extract domain from URL
    final domain = _extractDomain(url);
    
    // Check if we have specific user agents for this domain
    for (final siteDomain in _siteSpecificUserAgents.keys) {
      if (domain.contains(siteDomain)) {
        final siteAgents = _siteSpecificUserAgents[siteDomain]!;
        if (siteAgents.isNotEmpty) {
          final userAgent = siteAgents[_random.nextInt(siteAgents.length)];
          _logger?.info('Using site-specific user agent for $siteDomain: ${_truncateUserAgent(userAgent)}');
          return userAgent;
        }
      }
    }
    
    // Fall back to a random user agent
    return getRandomUserAgent();
  }

  /// Gets a user agent that mimics a specific browser
  String getUserAgentByType(BrowserType type) {
    List<String> matchingAgents = [];
    
    // Filter user agents by type
    for (final agent in _userAgents) {
      switch (type) {
        case BrowserType.chrome:
          if (agent.contains('Chrome/') && !agent.contains('Edg/') && !agent.contains('OPR/')) {
            matchingAgents.add(agent);
          }
          break;
        case BrowserType.firefox:
          if (agent.contains('Firefox/')) {
            matchingAgents.add(agent);
          }
          break;
        case BrowserType.safari:
          if (agent.contains('Safari/') && !agent.contains('Chrome/')) {
            matchingAgents.add(agent);
          }
          break;
        case BrowserType.edge:
          if (agent.contains('Edg/')) {
            matchingAgents.add(agent);
          }
          break;
        case BrowserType.opera:
          if (agent.contains('OPR/')) {
            matchingAgents.add(agent);
          }
          break;
        case BrowserType.mobile:
          if (agent.contains('Mobile') || agent.contains('Android') || agent.contains('iPhone')) {
            matchingAgents.add(agent);
          }
          break;
      }
    }
    
    // If no matching agents, use default for that type
    if (matchingAgents.isEmpty) {
      switch (type) {
        case BrowserType.chrome:
          return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36';
        case BrowserType.firefox:
          return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0';
        case BrowserType.safari:
          return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15';
        case BrowserType.edge:
          return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36 Edg/118.0.2088.76';
        case BrowserType.opera:
          return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36 OPR/104.0.0.0';
        case BrowserType.mobile:
          return 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36';
      }
    }
    
    // Return a random matching agent
    final userAgent = matchingAgents[_random.nextInt(matchingAgents.length)];
    _logger?.info('Using ${type.name} user agent: ${_truncateUserAgent(userAgent)}');
    return userAgent;
  }

  /// Gets a sequence of user agents to try for a problematic site
  List<String> getUserAgentSequenceForProblematicSite(String url) {
    final result = <String>[];
    
    // First, add site-specific user agents
    final domain = _extractDomain(url);
    for (final siteDomain in _siteSpecificUserAgents.keys) {
      if (domain.contains(siteDomain)) {
        result.addAll(_siteSpecificUserAgents[siteDomain]!);
      }
    }
    
    // Then add one of each browser type
    result.add(getUserAgentByType(BrowserType.chrome));
    result.add(getUserAgentByType(BrowserType.firefox));
    result.add(getUserAgentByType(BrowserType.edge));
    result.add(getUserAgentByType(BrowserType.safari));
    result.add(getUserAgentByType(BrowserType.mobile));
    
    // Add a few random ones
    for (int i = 0; i < 3; i++) {
      result.add(getRandomUserAgent());
    }
    
    // Remove duplicates
    return result.toSet().toList();
  }

  /// Adds a user agent to the list
  void addUserAgent(String userAgent) {
    if (!_userAgents.contains(userAgent)) {
      _userAgents.add(userAgent);
      _logger?.info('Added user agent: ${_truncateUserAgent(userAgent)}');
    }
  }

  /// Adds a site-specific user agent
  void addSiteSpecificUserAgent(String domain, String userAgent) {
    if (!_siteSpecificUserAgents.containsKey(domain)) {
      _siteSpecificUserAgents[domain] = [];
    }
    
    if (!_siteSpecificUserAgents[domain]!.contains(userAgent)) {
      _siteSpecificUserAgents[domain]!.add(userAgent);
      _logger?.info('Added site-specific user agent for $domain: ${_truncateUserAgent(userAgent)}');
    }
  }

  /// Gets the list of user agents
  List<String> getUserAgents() {
    return List.unmodifiable(_userAgents);
  }

  /// Gets the site-specific user agents for a domain
  List<String> getSiteSpecificUserAgents(String domain) {
    return List.unmodifiable(_siteSpecificUserAgents[domain] ?? []);
  }

  /// Extracts the domain from a URL
  String _extractDomain(String url) {
    // Remove protocol
    var domain = url.replaceAll(RegExp(r'https?://'), '');
    
    // Remove path and query
    domain = domain.split('/').first;
    
    // Remove port
    domain = domain.split(':').first;
    
    return domain;
  }

  /// Truncates a user agent string for logging
  String _truncateUserAgent(String userAgent) {
    if (userAgent.length <= 50) {
      return userAgent;
    }
    return '${userAgent.substring(0, 47)}...';
  }

  /// Default list of user agents (latest versions as of 2023)
  static const List<String> _defaultUserAgents = [
    // Chrome
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
    
    // Firefox
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/119.0',
    'Mozilla/5.0 (X11; Linux i686; rv:109.0) Gecko/20100101 Firefox/119.0',
    
    // Safari
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15',
    
    // Edge
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36 Edg/118.0.2088.76',
    
    // Opera
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36 OPR/104.0.0.0',
    
    // Mobile
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 13; SM-S901B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
    
    // Tablets
    'Mozilla/5.0 (iPad; CPU OS 17_0_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Linux; Android 13; SM-X906C Build/TP1A.220624.014) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36',
  ];
}

/// Browser types for user agent selection
enum BrowserType {
  /// Chrome browser
  chrome,
  
  /// Firefox browser
  firefox,
  
  /// Safari browser
  safari,
  
  /// Edge browser
  edge,
  
  /// Opera browser
  opera,
  
  /// Mobile browsers
  mobile,
}
