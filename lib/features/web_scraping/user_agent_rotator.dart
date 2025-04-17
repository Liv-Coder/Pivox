import 'dart:math';

/// A rotator for user agents to avoid detection
class UserAgentRotator {
  /// List of user agents to rotate through
  final List<String> _userAgents;

  /// Random number generator
  final Random _random;

  /// Creates a new [UserAgentRotator] with the given user agents
  ///
  /// If no user agents are provided, a default list will be used
  UserAgentRotator({List<String>? userAgents, Random? random})
    : _userAgents = userAgents ?? _defaultUserAgents,
      _random = random ?? Random();

  /// Gets a random user agent
  String getRandomUserAgent() {
    if (_userAgents.isEmpty) {
      return '';
    }

    return _userAgents[_random.nextInt(_userAgents.length)];
  }

  /// Gets the next user agent in sequence
  String getNextUserAgent() {
    if (_userAgents.isEmpty) {
      return '';
    }

    final index = _random.nextInt(_userAgents.length);
    return _userAgents[index];
  }

  /// Adds a user agent to the list
  void addUserAgent(String userAgent) {
    if (!_userAgents.contains(userAgent)) {
      _userAgents.add(userAgent);
    }
  }

  /// Removes a user agent from the list
  void removeUserAgent(String userAgent) {
    _userAgents.remove(userAgent);
  }

  /// Gets the list of user agents
  List<String> getUserAgents() {
    return List.unmodifiable(_userAgents);
  }

  /// Default list of user agents
  static const List<String> _defaultUserAgents = [
    // Chrome
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',

    // Firefox
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (X11; Linux i686; rv:89.0) Gecko/20100101 Firefox/89.0',

    // Safari
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',

    // Edge
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59',

    // Opera
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 OPR/77.0.4054.277',

    // Mobile
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Android 11; Mobile; rv:68.0) Gecko/68.0 Firefox/89.0',
    'Mozilla/5.0 (Linux; Android 11; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
  ];
}
