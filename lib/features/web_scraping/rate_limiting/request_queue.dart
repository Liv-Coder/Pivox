import 'dart:async';

import '../../../core/utils/logger.dart';
import 'rate_limiter.dart';

/// Priority level for a request
enum RequestPriority {
  /// Low priority (background tasks)
  low,

  /// Normal priority (default)
  normal,

  /// High priority (user-initiated tasks)
  high,

  /// Critical priority (must be processed immediately)
  critical,
}

/// A request in the queue
class QueuedRequest<T> {
  /// The domain of the request
  final String domain;

  /// The priority of the request
  final RequestPriority priority;

  /// The function to execute
  final Future<T> Function() execute;

  /// The completer for the request
  final Completer<T> completer;

  /// The time the request was added to the queue
  final DateTime queueTime;

  /// Creates a new [QueuedRequest]
  QueuedRequest({
    required this.domain,
    required this.priority,
    required this.execute,
    required this.completer,
  }) : queueTime = DateTime.now();
}

/// A queue for managing and prioritizing web scraping requests
class RequestQueue {
  /// The rate limiter to use
  final RateLimiter rateLimiter;

  /// The maximum number of concurrent requests
  final int maxConcurrentRequests;

  /// The maximum queue size
  final int maxQueueSize;

  /// The queue of requests
  final List<QueuedRequest> _queue = [];

  /// The currently executing requests
  final Set<QueuedRequest> _executingRequests = {};

  /// Whether the queue is currently processing requests
  bool _isProcessing = false;

  /// Logger for logging queue operations
  final Logger? logger;

  /// Creates a new [RequestQueue]
  RequestQueue({
    required this.rateLimiter,
    this.maxConcurrentRequests = 5,
    this.maxQueueSize = 100,
    this.logger,
  });

  /// Adds a request to the queue
  Future<T> enqueue<T>({
    required String domain,
    required Future<T> Function() execute,
    RequestPriority priority = RequestPriority.normal,
  }) {
    // Check if the queue is full
    if (_queue.length >= maxQueueSize) {
      throw Exception('Request queue is full');
    }

    // Create a completer for the request
    final completer = Completer<T>();

    // Create a queued request
    final request = QueuedRequest<T>(
      domain: domain,
      priority: priority,
      execute: execute,
      completer: completer,
    );

    // Add the request to the queue
    _queue.add(request as QueuedRequest<dynamic>);

    // Start processing the queue if it's not already processing
    if (!_isProcessing) {
      _processQueue();
    }

    return completer.future;
  }

  /// Processes the queue
  Future<void> _processQueue() async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      while (_queue.isNotEmpty &&
          _executingRequests.length < maxConcurrentRequests) {
        // Get the next request with highest priority
        _queue.sort((a, b) {
          // First compare by priority (higher priority first)
          final priorityComparison = b.priority.index.compareTo(
            a.priority.index,
          );
          if (priorityComparison != 0) {
            return priorityComparison;
          }

          // Then compare by queue time (older first)
          return a.queueTime.compareTo(b.queueTime);
        });

        final request = _queue.removeAt(0);

        // Add it to the executing requests
        _executingRequests.add(request);

        // Execute the request
        _executeRequest(request);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Executes a request
  Future<void> _executeRequest(QueuedRequest request) async {
    try {
      // Wait for rate limiting permission
      await rateLimiter.waitForPermission(request.domain);

      // Execute the request
      final result = await request.execute();

      // Complete the request
      request.completer.complete(result);
    } catch (e, stackTrace) {
      // Complete the request with an error
      if (!request.completer.isCompleted) {
        request.completer.completeError(e, stackTrace);
      }
    } finally {
      // Remove the request from the executing requests
      _executingRequests.remove(request);

      // Continue processing the queue
      if (_queue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  /// Gets the number of requests in the queue
  int get queueSize => _queue.length;

  /// Gets the number of currently executing requests
  int get executingRequestCount => _executingRequests.length;

  /// Gets the total number of requests (queued + executing)
  int get totalRequestCount => queueSize + executingRequestCount;

  /// Clears the queue
  void clear() {
    // Complete any queued requests with an error
    final queuedRequests = _queue.toList();
    _queue.clear();

    for (final request in queuedRequests) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(Exception('Request queue was cleared'));
      }
    }

    // Note: We don't cancel executing requests, they will complete normally
  }

  /// Pauses the queue (stops processing new requests)
  void pause() {
    _isProcessing = false;
  }

  /// Resumes the queue (starts processing new requests)
  void resume() {
    if (!_isProcessing &&
        (_queue.isNotEmpty || _executingRequests.isNotEmpty)) {
      _processQueue();
    }
  }
}
