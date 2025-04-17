import 'dart:async';
import 'dart:collection';

import '../../../core/utils/logger.dart';

/// A rate limiter that enforces rate limits for different domains
class RateLimiter {
  /// The default requests per minute
  final int defaultRequestsPerMinute;

  /// The default requests per hour
  final int defaultRequestsPerHour;

  /// The default requests per day
  final int defaultRequestsPerDay;

  /// Domain-specific rate limits (requests per minute)
  final Map<String, int> _domainLimitsPerMinute = {};

  /// Domain-specific rate limits (requests per hour)
  final Map<String, int> _domainLimitsPerHour = {};

  /// Domain-specific rate limits (requests per day)
  final Map<String, int> _domainLimitsPerDay = {};

  /// Request timestamps for each domain (per minute)
  final Map<String, Queue<DateTime>> _requestTimestampsPerMinute = {};

  /// Request timestamps for each domain (per hour)
  final Map<String, Queue<DateTime>> _requestTimestampsPerHour = {};

  /// Request timestamps for each domain (per day)
  final Map<String, Queue<DateTime>> _requestTimestampsPerDay = {};

  /// Pending requests for each domain
  final Map<String, List<Completer<void>>> _pendingRequests = {};

  /// Logger for logging rate limiting operations
  final Logger? logger;

  /// Creates a new [RateLimiter]
  RateLimiter({
    this.defaultRequestsPerMinute = 30,
    this.defaultRequestsPerHour = 500,
    this.defaultRequestsPerDay = 5000,
    this.logger,
  });

  /// Sets the rate limit for a specific domain
  void setDomainLimit(
    String domain, {
    int? requestsPerMinute,
    int? requestsPerHour,
    int? requestsPerDay,
  }) {
    if (requestsPerMinute != null) {
      _domainLimitsPerMinute[domain] = requestsPerMinute;
    }
    if (requestsPerHour != null) {
      _domainLimitsPerHour[domain] = requestsPerHour;
    }
    if (requestsPerDay != null) {
      _domainLimitsPerDay[domain] = requestsPerDay;
    }
  }

  /// Gets the rate limit for a specific domain (requests per minute)
  int getRateLimitPerMinute(String domain) {
    return _domainLimitsPerMinute[domain] ?? defaultRequestsPerMinute;
  }

  /// Gets the rate limit for a specific domain (requests per hour)
  int getRateLimitPerHour(String domain) {
    return _domainLimitsPerHour[domain] ?? defaultRequestsPerHour;
  }

  /// Gets the rate limit for a specific domain (requests per day)
  int getRateLimitPerDay(String domain) {
    return _domainLimitsPerDay[domain] ?? defaultRequestsPerDay;
  }

  /// Waits until a request can be made to the given domain
  Future<void> waitForPermission(String domain) async {
    final now = DateTime.now();

    // Initialize request timestamps if needed
    _requestTimestampsPerMinute[domain] ??= Queue<DateTime>();
    _requestTimestampsPerHour[domain] ??= Queue<DateTime>();
    _requestTimestampsPerDay[domain] ??= Queue<DateTime>();

    // Clean up old timestamps
    _cleanupOldTimestamps(domain, now);

    // Check if we're within rate limits
    final minuteLimit = getRateLimitPerMinute(domain);
    final hourLimit = getRateLimitPerHour(domain);
    final dayLimit = getRateLimitPerDay(domain);

    final minuteCount = _requestTimestampsPerMinute[domain]!.length;
    final hourCount = _requestTimestampsPerHour[domain]!.length;
    final dayCount = _requestTimestampsPerDay[domain]!.length;

    if (minuteCount < minuteLimit &&
        hourCount < hourLimit &&
        dayCount < dayLimit) {
      // We're within rate limits, so we can proceed immediately
      _recordRequest(domain, now);
      return;
    }

    // We need to wait for a slot to open up
    logger?.info(
      'Rate limit reached for $domain. Waiting for a slot to open up.',
    );

    // Calculate wait time
    final waitTime = _calculateWaitTime(domain, now);

    if (waitTime <= Duration.zero) {
      // No need to wait
      _recordRequest(domain, now);
      return;
    }

    // Create a completer for this request
    final completer = Completer<void>();
    _pendingRequests[domain] ??= [];
    _pendingRequests[domain]!.add(completer);

    // Schedule processing of this request
    Timer(waitTime, () {
      _processNextRequest(domain);
    });

    // Wait for our turn
    return completer.future;
  }

  /// Records a request to the given domain
  void _recordRequest(String domain, DateTime timestamp) {
    _requestTimestampsPerMinute[domain]!.add(timestamp);
    _requestTimestampsPerHour[domain]!.add(timestamp);
    _requestTimestampsPerDay[domain]!.add(timestamp);
  }

  /// Cleans up old timestamps for the given domain
  void _cleanupOldTimestamps(String domain, DateTime now) {
    // Remove timestamps older than 1 minute
    while (_requestTimestampsPerMinute[domain]!.isNotEmpty &&
        now.difference(_requestTimestampsPerMinute[domain]!.first).inMinutes >=
            1) {
      _requestTimestampsPerMinute[domain]!.removeFirst();
    }

    // Remove timestamps older than 1 hour
    while (_requestTimestampsPerHour[domain]!.isNotEmpty &&
        now.difference(_requestTimestampsPerHour[domain]!.first).inHours >= 1) {
      _requestTimestampsPerHour[domain]!.removeFirst();
    }

    // Remove timestamps older than 1 day
    while (_requestTimestampsPerDay[domain]!.isNotEmpty &&
        now.difference(_requestTimestampsPerDay[domain]!.first).inDays >= 1) {
      _requestTimestampsPerDay[domain]!.removeFirst();
    }
  }

  /// Calculates the wait time for the given domain
  Duration _calculateWaitTime(String domain, DateTime now) {
    Duration minuteWait = Duration.zero;
    Duration hourWait = Duration.zero;
    Duration dayWait = Duration.zero;

    final minuteLimit = getRateLimitPerMinute(domain);
    final hourLimit = getRateLimitPerHour(domain);
    final dayLimit = getRateLimitPerDay(domain);

    final minuteCount = _requestTimestampsPerMinute[domain]!.length;
    final hourCount = _requestTimestampsPerHour[domain]!.length;
    final dayCount = _requestTimestampsPerDay[domain]!.length;

    // Calculate wait time for minute limit
    if (minuteCount >= minuteLimit &&
        _requestTimestampsPerMinute[domain]!.isNotEmpty) {
      final oldestTimestamp = _requestTimestampsPerMinute[domain]!.first;
      final minuteElapsed = now.difference(oldestTimestamp);
      if (minuteElapsed < const Duration(minutes: 1)) {
        minuteWait = const Duration(minutes: 1) - minuteElapsed;
      }
    }

    // Calculate wait time for hour limit
    if (hourCount >= hourLimit &&
        _requestTimestampsPerHour[domain]!.isNotEmpty) {
      final oldestTimestamp = _requestTimestampsPerHour[domain]!.first;
      final hourElapsed = now.difference(oldestTimestamp);
      if (hourElapsed < const Duration(hours: 1)) {
        hourWait = const Duration(hours: 1) - hourElapsed;
      }
    }

    // Calculate wait time for day limit
    if (dayCount >= dayLimit && _requestTimestampsPerDay[domain]!.isNotEmpty) {
      final oldestTimestamp = _requestTimestampsPerDay[domain]!.first;
      final dayElapsed = now.difference(oldestTimestamp);
      if (dayElapsed < const Duration(days: 1)) {
        dayWait = const Duration(days: 1) - dayElapsed;
      }
    }

    // Return the longest wait time
    return [minuteWait, hourWait, dayWait].reduce((a, b) => a > b ? a : b);
  }

  /// Processes the next pending request for the given domain
  void _processNextRequest(String domain) {
    final now = DateTime.now();

    // Clean up old timestamps
    _cleanupOldTimestamps(domain, now);

    // Check if we have any pending requests
    if (_pendingRequests[domain] == null || _pendingRequests[domain]!.isEmpty) {
      return;
    }

    // Check if we're within rate limits
    final minuteLimit = getRateLimitPerMinute(domain);
    final hourLimit = getRateLimitPerHour(domain);
    final dayLimit = getRateLimitPerDay(domain);

    final minuteCount = _requestTimestampsPerMinute[domain]!.length;
    final hourCount = _requestTimestampsPerHour[domain]!.length;
    final dayCount = _requestTimestampsPerDay[domain]!.length;

    if (minuteCount < minuteLimit &&
        hourCount < hourLimit &&
        dayCount < dayLimit) {
      // We're within rate limits, so we can process the next request
      final completer = _pendingRequests[domain]!.removeAt(0);
      _recordRequest(domain, now);
      completer.complete();

      // Process the next request if we have any
      if (_pendingRequests[domain]!.isNotEmpty) {
        // Add a small delay to avoid processing all requests at once
        Timer(const Duration(milliseconds: 100), () {
          _processNextRequest(domain);
        });
      }
    } else {
      // We need to wait for a slot to open up
      final waitTime = _calculateWaitTime(domain, now);

      // Schedule processing of the next request
      Timer(waitTime, () {
        _processNextRequest(domain);
      });
    }
  }

  /// Gets the current request count for the given domain (per minute)
  int getCurrentRequestCountPerMinute(String domain) {
    _requestTimestampsPerMinute[domain] ??= Queue<DateTime>();
    _cleanupOldTimestamps(domain, DateTime.now());
    return _requestTimestampsPerMinute[domain]!.length;
  }

  /// Gets the current request count for the given domain (per hour)
  int getCurrentRequestCountPerHour(String domain) {
    _requestTimestampsPerHour[domain] ??= Queue<DateTime>();
    _cleanupOldTimestamps(domain, DateTime.now());
    return _requestTimestampsPerHour[domain]!.length;
  }

  /// Gets the current request count for the given domain (per day)
  int getCurrentRequestCountPerDay(String domain) {
    _requestTimestampsPerDay[domain] ??= Queue<DateTime>();
    _cleanupOldTimestamps(domain, DateTime.now());
    return _requestTimestampsPerDay[domain]!.length;
  }

  /// Gets the number of pending requests for the given domain
  int getPendingRequestCount(String domain) {
    return _pendingRequests[domain]?.length ?? 0;
  }

  /// Clears all rate limiting data
  void clear() {
    _requestTimestampsPerMinute.clear();
    _requestTimestampsPerHour.clear();
    _requestTimestampsPerDay.clear();

    // Complete any pending requests with an error
    for (final domain in _pendingRequests.keys) {
      for (final completer in _pendingRequests[domain]!) {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Rate limiter was cleared'));
        }
      }
    }
    _pendingRequests.clear();
  }
}
