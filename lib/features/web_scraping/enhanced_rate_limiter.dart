import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'robots_txt_handler.dart';
import 'scraping_logger.dart';

/// An enhanced rate limiter for web scraping with advanced features
class EnhancedRateLimiter {
  /// Map of domains to their last request time
  final Map<String, DateTime> _lastRequestTime = {};

  /// Map of domains to their request queues
  final Map<String, Queue<_QueuedRequest>> _requestQueues = {};

  /// Map of domains to their rate limit status
  final Map<String, _RateLimitStatus> _rateLimitStatus = {};

  /// Default delay between requests to the same domain in milliseconds
  final int _defaultDelayMs;

  /// Custom delays for specific domains in milliseconds
  final Map<String, int> _domainDelays;

  /// Maximum retry attempts for rate-limited requests
  final int _maxRetries;

  /// Initial backoff time in milliseconds
  final int _initialBackoffMs;

  /// Maximum backoff time in milliseconds
  final int _maxBackoffMs;

  /// Backoff multiplier for exponential backoff
  final double _backoffMultiplier;

  /// The robots.txt handler for getting crawl delays
  final RobotsTxtHandler? _robotsTxtHandler;

  /// The logger for logging operations
  final ScrapingLogger _logger;

  /// Random number generator for jitter
  final Random _random = Random();

  /// Creates a new [EnhancedRateLimiter] with the given parameters
  ///
  /// [defaultDelayMs] is the default delay between requests to the same domain
  /// [domainDelays] is a map of domains to their custom delays
  /// [maxRetries] is the maximum number of retry attempts for rate-limited requests
  /// [initialBackoffMs] is the initial backoff time in milliseconds
  /// [maxBackoffMs] is the maximum backoff time in milliseconds
  /// [backoffMultiplier] is the backoff multiplier for exponential backoff
  /// [robotsTxtHandler] is the robots.txt handler for getting crawl delays
  /// [logger] is the logger for logging operations
  EnhancedRateLimiter({
    int defaultDelayMs = 1000,
    Map<String, int>? domainDelays,
    int maxRetries = 3,
    int initialBackoffMs = 1000,
    int maxBackoffMs = 60000,
    double backoffMultiplier = 2.0,
    RobotsTxtHandler? robotsTxtHandler,
    ScrapingLogger? logger,
  }) : _defaultDelayMs = defaultDelayMs,
       _domainDelays = domainDelays ?? {},
       _maxRetries = maxRetries,
       _initialBackoffMs = initialBackoffMs,
       _maxBackoffMs = maxBackoffMs,
       _backoffMultiplier = backoffMultiplier,
       _robotsTxtHandler = robotsTxtHandler,
       _logger = logger ?? ScrapingLogger();

  /// Executes a function with rate limiting
  ///
  /// [url] is the URL to rate limit
  /// [fn] is the function to execute
  /// [userAgent] is the user agent to use for robots.txt crawl delay
  /// [priority] is the priority of the request (higher values = higher priority)
  Future<T> execute<T>({
    required String url,
    required Future<T> Function() fn,
    String? userAgent,
    int priority = 0,
  }) async {
    final domain = _extractDomain(url);

    // Check if the domain is rate limited
    if (_isRateLimited(domain)) {
      final retryAfter = _rateLimitStatus[domain]!.retryAfter;
      _logger.warning(
        'Domain $domain is rate limited. Retry after ${retryAfter.toIso8601String()}',
      );

      // Wait until the rate limit expires
      final now = DateTime.now();
      if (retryAfter.isAfter(now)) {
        final waitTime = retryAfter.difference(now).inMilliseconds;
        _logger.info('Waiting ${waitTime}ms for rate limit to expire');
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }

    // Get the crawl delay from robots.txt if available
    int? robotsDelay;
    if (_robotsTxtHandler != null && userAgent != null) {
      try {
        final rules = await _robotsTxtHandler.getRules(domain);
        robotsDelay = rules?.getCrawlDelay(userAgent);

        if (robotsDelay != null) {
          _logger.info(
            'Using robots.txt crawl delay of ${robotsDelay}ms for $domain',
          );
        }
      } catch (e) {
        _logger.warning('Error getting robots.txt crawl delay: $e');
      }
    }

    // Create a completer for this request
    final completer = Completer<T>();

    // Create a queued request
    final queuedRequest = _QueuedRequest<T>(
      fn: fn,
      completer: completer,
      priority: priority,
      createdAt: DateTime.now(),
    );

    // Add the request to the queue
    _requestQueues.putIfAbsent(domain, () => Queue<_QueuedRequest>());
    _requestQueues[domain]!.add(queuedRequest);

    // Sort the queue by priority (higher priority first)
    final queue = _requestQueues[domain]!;
    final sortedList =
        queue.toList()..sort((a, b) {
          // First sort by priority (higher first)
          final priorityDiff = b.priority - a.priority;
          if (priorityDiff != 0) return priorityDiff;

          // Then sort by creation time (earlier first)
          return a.createdAt.compareTo(b.createdAt);
        });

    // Clear the queue and add the sorted items back
    queue.clear();
    queue.addAll(sortedList);

    // Process the queue if this is the only request
    if (_requestQueues[domain]!.length == 1) {
      _processQueue(domain, robotsDelay);
    }

    // Return the future from the completer
    return completer.future;
  }

  /// Processes the request queue for a domain
  Future<void> _processQueue(String domain, int? robotsDelay) async {
    final queue = _requestQueues[domain]!;

    // Determine the delay to use
    // Priority: 1. Rate limit status, 2. Robots.txt, 3. Domain-specific, 4. Default
    int getDelay() {
      if (_isRateLimited(domain)) {
        final retryAfter = _rateLimitStatus[domain]!.retryAfter;
        final now = DateTime.now();
        if (retryAfter.isAfter(now)) {
          return retryAfter.difference(now).inMilliseconds;
        }
      }

      if (robotsDelay != null) {
        return robotsDelay;
      }

      return _domainDelays[domain] ?? _defaultDelayMs;
    }

    while (queue.isNotEmpty) {
      final request = queue.first;
      final now = DateTime.now();
      final delay = getDelay();

      // Check if we need to wait
      if (_lastRequestTime.containsKey(domain)) {
        final lastRequest = _lastRequestTime[domain]!;
        final elapsed = now.difference(lastRequest).inMilliseconds;

        if (elapsed < delay) {
          // Wait for the remaining time
          final waitTime = delay - elapsed;

          // Add some jitter to avoid thundering herd problem (±10%)
          final jitter =
              (waitTime * 0.1 * (_random.nextDouble() * 2 - 1)).toInt();
          final effectiveWaitTime = max(0, waitTime + jitter);

          _logger.info(
            'Waiting ${effectiveWaitTime}ms before next request to $domain',
          );
          await Future.delayed(Duration(milliseconds: effectiveWaitTime));
        }
      }

      // Update the last request time
      _lastRequestTime[domain] = DateTime.now();

      // Execute the request
      try {
        final result = await request.fn();
        request.completer.complete(result);

        // Reset rate limit status on success
        _rateLimitStatus.remove(domain);
      } catch (e) {
        // Check if this is a rate limit error
        if (_isRateLimitError(e)) {
          _handleRateLimitError(domain, e);

          // If we have retries left, requeue the request
          if (!request.completer.isCompleted) {
            final status = _rateLimitStatus[domain]!;
            if (status.retryCount < _maxRetries) {
              _logger.warning(
                'Rate limited on $domain. Retry ${status.retryCount + 1}/$_maxRetries after ${status.currentBackoff}ms',
              );

              // Wait for the backoff period
              await Future.delayed(
                Duration(milliseconds: status.currentBackoff),
              );

              // Increment retry count and update backoff
              status.retryCount++;
              status.currentBackoff = min(
                _maxBackoffMs,
                (status.currentBackoff * _backoffMultiplier).toInt(),
              );

              // Add the request back to the queue with higher priority
              queue.add(request);
              continue;
            }
          }

          // If we've exhausted retries, complete with error
          if (!request.completer.isCompleted) {
            request.completer.completeError(e);
          }
        } else {
          // For non-rate-limit errors, just complete with the error
          request.completer.completeError(e);
        }
      }

      // Remove the request from the queue
      queue.removeFirst();
    }
  }

  /// Checks if a domain is currently rate limited
  bool _isRateLimited(String domain) {
    if (!_rateLimitStatus.containsKey(domain)) {
      return false;
    }

    final status = _rateLimitStatus[domain]!;
    final now = DateTime.now();

    return status.retryAfter.isAfter(now);
  }

  /// Checks if an error is a rate limit error
  bool _isRateLimitError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('rate limit') ||
        errorStr.contains('too many requests') ||
        errorStr.contains('429');
  }

  /// Handles a rate limit error
  void _handleRateLimitError(String domain, dynamic error) {
    // Parse retry-after from error if available
    int? retryAfterSeconds;
    final errorStr = error.toString();

    // Try to extract retry-after value
    final retryAfterRegex = RegExp(
      r'retry[- ]after:?\s*(\d+)',
      caseSensitive: false,
    );
    final match = retryAfterRegex.firstMatch(errorStr);
    if (match != null) {
      retryAfterSeconds = int.tryParse(match.group(1) ?? '');
    }

    // Calculate retry time
    final now = DateTime.now();
    final retryAfter = now.add(
      Duration(
        seconds:
            retryAfterSeconds ?? 60, // Default to 60 seconds if not specified
      ),
    );

    // Create or update rate limit status
    if (_rateLimitStatus.containsKey(domain)) {
      final status = _rateLimitStatus[domain]!;
      status.retryAfter = retryAfter;
      status.currentBackoff = min(
        _maxBackoffMs,
        (status.currentBackoff * _backoffMultiplier).toInt(),
      );
    } else {
      _rateLimitStatus[domain] = _RateLimitStatus(
        retryAfter: retryAfter,
        retryCount: 0,
        currentBackoff: _initialBackoffMs,
      );
    }

    _logger.warning(
      'Rate limit detected for $domain. Retry after ${retryAfter.toIso8601String()}',
    );
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

  /// Sets a custom delay for a domain
  void setDomainDelay(String domain, int delayMs) {
    _domainDelays[domain] = delayMs;
    _logger.info('Set custom delay of ${delayMs}ms for $domain');
  }

  /// Gets the current delay for a domain
  int getDomainDelay(String domain) {
    return _domainDelays[domain] ?? _defaultDelayMs;
  }

  /// Clears rate limit status for a domain
  void clearRateLimit(String domain) {
    _rateLimitStatus.remove(domain);
    _logger.info('Cleared rate limit status for $domain');
  }

  /// Clears all rate limit statuses
  void clearAllRateLimits() {
    _rateLimitStatus.clear();
    _logger.info('Cleared all rate limit statuses');
  }
}

/// A request in the rate limiter queue
class _QueuedRequest<T> {
  /// The function to execute
  final Future<T> Function() fn;

  /// The completer for the request
  final Completer<T> completer;

  /// The priority of the request (higher values = higher priority)
  final int priority;

  /// The time when the request was created
  final DateTime createdAt;

  /// Creates a new [_QueuedRequest] with the given parameters
  _QueuedRequest({
    required this.fn,
    required this.completer,
    required this.priority,
    required this.createdAt,
  });
}

/// Rate limit status for a domain
class _RateLimitStatus {
  /// The time when the rate limit expires
  DateTime retryAfter;

  /// The number of retry attempts
  int retryCount;

  /// The current backoff time in milliseconds
  int currentBackoff;

  /// Creates a new [_RateLimitStatus] with the given parameters
  _RateLimitStatus({
    required this.retryAfter,
    required this.retryCount,
    required this.currentBackoff,
  });
}
