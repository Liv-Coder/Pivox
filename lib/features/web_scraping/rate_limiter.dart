import 'dart:async';
import 'dart:collection';

/// A rate limiter for web scraping to avoid overwhelming target websites
class RateLimiter {
  /// Map of domains to their last request time
  final Map<String, DateTime> _lastRequestTime = {};

  /// Map of domains to their request queues
  final Map<String, Queue<_QueuedRequest>> _requestQueues = {};

  /// Default delay between requests to the same domain in milliseconds
  final int _defaultDelayMs;

  /// Custom delays for specific domains in milliseconds
  final Map<String, int> _domainDelays;

  /// Creates a new [RateLimiter] with the given parameters
  ///
  /// [defaultDelayMs] is the default delay between requests to the same domain
  /// [domainDelays] is a map of domains to their custom delays
  RateLimiter({int defaultDelayMs = 1000, Map<String, int>? domainDelays})
    : _defaultDelayMs = defaultDelayMs,
      _domainDelays = domainDelays ?? {};

  /// Executes a function with rate limiting
  ///
  /// [url] is the URL to rate limit
  /// [fn] is the function to execute
  Future<T> execute<T>({
    required String url,
    required Future<T> Function() fn,
  }) async {
    final domain = _extractDomain(url);
    // We'll use the domain to look up the delay when processing the queue

    // Create a completer for this request
    final completer = Completer<T>();

    // Create a queued request
    final queuedRequest = _QueuedRequest<T>(fn: fn, completer: completer);

    // Add the request to the queue
    _requestQueues.putIfAbsent(domain, () => Queue<_QueuedRequest>());
    _requestQueues[domain]!.add(queuedRequest);

    // Process the queue if this is the only request
    if (_requestQueues[domain]!.length == 1) {
      _processQueue(domain);
    }

    // Return the future from the completer
    return completer.future;
  }

  /// Processes the request queue for a domain
  Future<void> _processQueue(String domain) async {
    final queue = _requestQueues[domain]!;
    final delay = _domainDelays[domain] ?? _defaultDelayMs;

    while (queue.isNotEmpty) {
      final request = queue.first;
      final now = DateTime.now();

      // Check if we need to wait
      if (_lastRequestTime.containsKey(domain)) {
        final lastRequest = _lastRequestTime[domain]!;
        final elapsed = now.difference(lastRequest).inMilliseconds;

        if (elapsed < delay) {
          // Wait for the remaining time
          await Future.delayed(Duration(milliseconds: delay - elapsed));
        }
      }

      // Update the last request time
      _lastRequestTime[domain] = DateTime.now();

      // Execute the request
      try {
        final result = await request.fn();
        request.completer.complete(result);
      } catch (e) {
        request.completer.completeError(e);
      }

      // Remove the request from the queue
      queue.removeFirst();
    }
  }

  /// Extracts the domain from a URL
  String _extractDomain(String url) {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return url;
    }

    return uri.host;
  }

  /// Sets a custom delay for a domain
  void setDomainDelay(String domain, int delayMs) {
    _domainDelays[domain] = delayMs;
  }

  /// Gets the current delay for a domain
  int getDomainDelay(String domain) {
    return _domainDelays[domain] ?? _defaultDelayMs;
  }
}

/// A request in the rate limiter queue
class _QueuedRequest<T> {
  /// The function to execute
  final Future<T> Function() fn;

  /// The completer for the request
  final Completer<T> completer;

  /// Creates a new [_QueuedRequest] with the given parameters
  _QueuedRequest({required this.fn, required this.completer});
}
