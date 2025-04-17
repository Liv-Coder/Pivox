import 'dart:math';

import '../../../../core/utils/logger.dart';
import '../entities/proxy.dart';

/// A session for a proxy
class ProxySession {
  /// The proxy for this session
  final Proxy proxy;

  /// The session ID
  final String sessionId;

  /// The user agent for this session
  final String userAgent;

  /// The cookies for this session
  final Map<String, String> cookies;

  /// The headers for this session
  final Map<String, String> headers;

  /// The creation time of this session
  final DateTime creationTime;

  /// The last access time of this session
  DateTime lastAccessTime;

  /// The number of requests made in this session
  int requestCount;

  /// Whether this session is active
  bool isActive;

  /// Creates a new [ProxySession]
  ProxySession({
    required this.proxy,
    required this.sessionId,
    required this.userAgent,
    Map<String, String>? cookies,
    Map<String, String>? headers,
    DateTime? creationTime,
    DateTime? lastAccessTime,
    this.requestCount = 0,
    this.isActive = true,
  }) : cookies = cookies ?? {},
       headers = headers ?? {},
       creationTime = creationTime ?? DateTime.now(),
       lastAccessTime = lastAccessTime ?? DateTime.now();

  /// Updates the last access time
  void updateLastAccessTime() {
    lastAccessTime = DateTime.now();
  }

  /// Increments the request count
  void incrementRequestCount() {
    requestCount++;
    updateLastAccessTime();
  }

  /// Adds a cookie to the session
  void addCookie(String name, String value) {
    cookies[name] = value;
    updateLastAccessTime();
  }

  /// Adds cookies to the session
  void addCookies(Map<String, String> newCookies) {
    cookies.addAll(newCookies);
    updateLastAccessTime();
  }

  /// Adds a header to the session
  void addHeader(String name, String value) {
    headers[name] = value;
    updateLastAccessTime();
  }

  /// Adds headers to the session
  void addHeaders(Map<String, String> newHeaders) {
    headers.addAll(newHeaders);
    updateLastAccessTime();
  }

  /// Gets the age of the session in seconds
  int get ageInSeconds {
    return DateTime.now().difference(creationTime).inSeconds;
  }

  /// Gets the idle time of the session in seconds
  int get idleTimeInSeconds {
    return DateTime.now().difference(lastAccessTime).inSeconds;
  }

  /// Gets the request rate per minute
  double get requestRatePerMinute {
    final ageInMinutes = ageInSeconds / 60.0;
    if (ageInMinutes <= 0) return 0.0;
    return requestCount / ageInMinutes;
  }

  /// Gets the formatted cookie string for HTTP headers
  String get cookieString {
    return cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  /// Gets the headers for this session
  Map<String, String> get sessionHeaders {
    final result = Map<String, String>.from(headers);
    if (cookies.isNotEmpty) {
      result['Cookie'] = cookieString;
    }
    result['User-Agent'] = userAgent;
    return result;
  }

  @override
  String toString() {
    return 'ProxySession{proxy: ${proxy.host}:${proxy.port}, '
        'sessionId: $sessionId, '
        'requestCount: $requestCount, '
        'age: ${ageInSeconds}s, '
        'idle: ${idleTimeInSeconds}s, '
        'active: $isActive}';
  }
}

/// Manager for proxy sessions
class ProxySessionManager {
  /// The sessions by session ID
  final Map<String, ProxySession> _sessionsById = {};

  /// The sessions by proxy
  final Map<String, List<ProxySession>> _sessionsByProxy = {};

  /// The sessions by domain
  final Map<String, Map<String, ProxySession>> _sessionsByDomain = {};

  /// The maximum number of sessions per proxy
  final int maxSessionsPerProxy;

  /// The maximum session age in seconds
  final int maxSessionAgeSeconds;

  /// The maximum session idle time in seconds
  final int maxSessionIdleSeconds;

  /// Random number generator for session IDs
  final Random _random;

  /// Logger for logging operations
  final Logger? logger;

  /// Creates a new [ProxySessionManager]
  ProxySessionManager({
    this.maxSessionsPerProxy = 5,
    this.maxSessionAgeSeconds = 3600, // 1 hour
    this.maxSessionIdleSeconds = 600, // 10 minutes
    Random? random,
    this.logger,
  }) : _random = random ?? Random();

  /// Creates a new session for a proxy and domain
  ProxySession createSession({
    required Proxy proxy,
    required String domain,
    String? userAgent,
    Map<String, String>? cookies,
    Map<String, String>? headers,
  }) {
    // Clean up old sessions
    _cleanupSessions();

    // Check if we already have a session for this proxy and domain
    final existingSession = getSession(proxy: proxy, domain: domain);
    if (existingSession != null && existingSession.isActive) {
      logger?.info(
        'Using existing session for ${proxy.host}:${proxy.port} on $domain',
      );
      existingSession.updateLastAccessTime();
      return existingSession;
    }

    // Check if we have too many sessions for this proxy
    final proxyKey = '${proxy.host}:${proxy.port}';
    final proxySessions = _sessionsByProxy[proxyKey] ?? [];
    if (proxySessions.length >= maxSessionsPerProxy) {
      // Remove the oldest session
      logger?.info('Removing oldest session for ${proxy.host}:${proxy.port}');
      final oldestSession = proxySessions.reduce(
        (a, b) => a.lastAccessTime.isBefore(b.lastAccessTime) ? a : b,
      );
      _removeSession(oldestSession);
    }

    // Create a new session
    final sessionId = _generateSessionId();
    final session = ProxySession(
      proxy: proxy,
      sessionId: sessionId,
      userAgent: userAgent ?? _generateUserAgent(),
      cookies: cookies,
      headers: headers,
    );

    // Add the session to the maps
    _sessionsById[sessionId] = session;
    _sessionsByProxy.putIfAbsent(proxyKey, () => []).add(session);
    _sessionsByDomain
        .putIfAbsent(domain, () => {})
        .putIfAbsent(proxyKey, () => session);

    logger?.info(
      'Created new session for ${proxy.host}:${proxy.port} on $domain',
    );
    return session;
  }

  /// Gets a session for a proxy and domain
  ProxySession? getSession({required Proxy proxy, required String domain}) {
    // Clean up old sessions
    _cleanupSessions();

    // Check if we have a session for this proxy and domain
    final proxyKey = '${proxy.host}:${proxy.port}';
    final domainSessions = _sessionsByDomain[domain];
    if (domainSessions != null) {
      final session = domainSessions[proxyKey];
      if (session != null && session.isActive) {
        return session;
      }
    }

    return null;
  }

  /// Gets all sessions for a proxy
  List<ProxySession> getSessionsForProxy(Proxy proxy) {
    // Clean up old sessions
    _cleanupSessions();

    // Get all sessions for this proxy
    final proxyKey = '${proxy.host}:${proxy.port}';
    return _sessionsByProxy[proxyKey] ?? [];
  }

  /// Gets all sessions for a domain
  List<ProxySession> getSessionsForDomain(String domain) {
    // Clean up old sessions
    _cleanupSessions();

    // Get all sessions for this domain
    final domainSessions = _sessionsByDomain[domain];
    if (domainSessions != null) {
      return domainSessions.values.toList();
    }

    return [];
  }

  /// Removes a session
  void _removeSession(ProxySession session) {
    // Remove from sessionsById
    _sessionsById.remove(session.sessionId);

    // Remove from sessionsByProxy
    final proxyKey = '${session.proxy.host}:${session.proxy.port}';
    final proxySessions = _sessionsByProxy[proxyKey];
    if (proxySessions != null) {
      proxySessions.remove(session);
      if (proxySessions.isEmpty) {
        _sessionsByProxy.remove(proxyKey);
      }
    }

    // Remove from sessionsByDomain
    for (final domainSessions in _sessionsByDomain.values) {
      domainSessions.remove(proxyKey);
    }

    // Remove empty domain maps
    _sessionsByDomain.removeWhere((_, sessions) => sessions.isEmpty);

    logger?.info(
      'Removed session ${session.sessionId} for ${session.proxy.host}:${session.proxy.port}',
    );
  }

  /// Cleans up old sessions
  void _cleanupSessions() {
    final now = DateTime.now();
    final sessionsToRemove = <ProxySession>[];

    // Find sessions to remove
    for (final session in _sessionsById.values) {
      final ageInSeconds = now.difference(session.creationTime).inSeconds;
      final idleTimeInSeconds =
          now.difference(session.lastAccessTime).inSeconds;

      if (ageInSeconds > maxSessionAgeSeconds ||
          idleTimeInSeconds > maxSessionIdleSeconds ||
          !session.isActive) {
        sessionsToRemove.add(session);
      }
    }

    // Remove the sessions
    for (final session in sessionsToRemove) {
      _removeSession(session);
    }

    if (sessionsToRemove.isNotEmpty) {
      logger?.info('Cleaned up ${sessionsToRemove.length} old sessions');
    }
  }

  /// Invalidates a session
  void invalidateSession(String sessionId) {
    final session = _sessionsById[sessionId];
    if (session != null) {
      session.isActive = false;
      _removeSession(session);
    }
  }

  /// Invalidates all sessions for a proxy
  void invalidateSessionsForProxy(Proxy proxy) {
    final proxyKey = '${proxy.host}:${proxy.port}';
    final proxySessions = _sessionsByProxy[proxyKey]?.toList() ?? [];

    for (final session in proxySessions) {
      session.isActive = false;
      _removeSession(session);
    }
  }

  /// Invalidates all sessions for a domain
  void invalidateSessionsForDomain(String domain) {
    final domainSessions = _sessionsByDomain[domain]?.values.toList() ?? [];

    for (final session in domainSessions) {
      session.isActive = false;
      _removeSession(session);
    }
  }

  /// Invalidates all sessions
  void invalidateAllSessions() {
    final allSessions = _sessionsById.values.toList();

    for (final session in allSessions) {
      session.isActive = false;
      _removeSession(session);
    }
  }

  /// Gets the number of active sessions
  int get activeSessionCount => _sessionsById.length;

  /// Generates a random session ID
  String _generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        16,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }

  /// Generates a random user agent
  String _generateUserAgent() {
    const userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59',
    ];
    return userAgents[_random.nextInt(userAgents.length)];
  }
}
