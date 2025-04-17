import 'dart:async';
import 'dart:math';

import 'proxy_error.dart';

/// A policy for retrying proxy operations
class ProxyRetryPolicy {
  /// The maximum number of retries
  final int maxRetries;

  /// The initial backoff duration
  final Duration initialBackoff;

  /// The maximum backoff duration
  final Duration maxBackoff;

  /// The backoff multiplier
  final double backoffMultiplier;

  /// Whether to add jitter to the backoff
  final bool useJitter;

  /// The set of retryable exception types
  final Set<Type> retryableExceptions;

  /// Creates a new [ProxyRetryPolicy]
  const ProxyRetryPolicy({
    this.maxRetries = 3,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
    this.retryableExceptions = const {
      ProxyConnectionError,
      ProxyTimeoutError,
      ProxyRateLimitedError,
    },
  });

  /// Creates a new [ProxyRetryPolicy] with no retries
  factory ProxyRetryPolicy.noRetry() {
    return const ProxyRetryPolicy(maxRetries: 0);
  }

  /// Creates a new [ProxyRetryPolicy] with a fixed delay
  factory ProxyRetryPolicy.fixedDelay({
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    Set<Type>? retryableExceptions,
  }) {
    return ProxyRetryPolicy(
      maxRetries: maxRetries,
      initialBackoff: delay,
      maxBackoff: delay,
      backoffMultiplier: 1.0,
      useJitter: false,
      retryableExceptions:
          retryableExceptions ??
          const {
            ProxyConnectionError,
            ProxyTimeoutError,
            ProxyRateLimitedError,
          },
    );
  }

  /// Creates a new [ProxyRetryPolicy] with exponential backoff
  factory ProxyRetryPolicy.exponentialBackoff({
    int maxRetries = 3,
    Duration initialBackoff = const Duration(milliseconds: 500),
    Duration maxBackoff = const Duration(seconds: 30),
    double backoffMultiplier = 2.0,
    bool useJitter = true,
    Set<Type>? retryableExceptions,
  }) {
    return ProxyRetryPolicy(
      maxRetries: maxRetries,
      initialBackoff: initialBackoff,
      maxBackoff: maxBackoff,
      backoffMultiplier: backoffMultiplier,
      useJitter: useJitter,
      retryableExceptions:
          retryableExceptions ??
          const {
            ProxyConnectionError,
            ProxyTimeoutError,
            ProxyRateLimitedError,
          },
    );
  }

  /// Executes an operation with retry logic
  Future<T> execute<T>(Future<T> Function() operation) async {
    int retryCount = 0;
    Duration backoff = initialBackoff;
    final random = Random();

    while (true) {
      try {
        return await operation();
      } catch (e) {
        // Check if we've reached the maximum number of retries
        if (retryCount >= maxRetries) {
          rethrow;
        }

        // Check if the exception is retryable
        if (!_isRetryable(e)) {
          rethrow;
        }

        // Calculate the next backoff duration
        final nextBackoff = _calculateNextBackoff(backoff, retryCount, random);

        // Wait for the backoff duration
        await Future.delayed(nextBackoff);

        // Increment the retry count and update the backoff
        retryCount++;
        backoff = Duration(
          milliseconds: (backoff.inMilliseconds * backoffMultiplier).toInt(),
        );
        if (backoff > maxBackoff) {
          backoff = maxBackoff;
        }
      }
    }
  }

  /// Checks if an exception is retryable
  bool _isRetryable(Object exception) {
    return retryableExceptions.contains(exception.runtimeType);
  }

  /// Calculates the next backoff duration
  Duration _calculateNextBackoff(
    Duration currentBackoff,
    int retryCount,
    Random random,
  ) {
    if (!useJitter) {
      return currentBackoff;
    }

    // Add jitter to avoid thundering herd problem
    final jitterFactor = 0.5 + random.nextDouble() * 0.5; // 0.5 to 1.0
    final jitteredMs = (currentBackoff.inMilliseconds * jitterFactor).toInt();
    return Duration(milliseconds: jitteredMs);
  }

  /// Creates a copy of this [ProxyRetryPolicy] with the given parameters
  ProxyRetryPolicy copyWith({
    int? maxRetries,
    Duration? initialBackoff,
    Duration? maxBackoff,
    double? backoffMultiplier,
    bool? useJitter,
    Set<Type>? retryableExceptions,
  }) {
    return ProxyRetryPolicy(
      maxRetries: maxRetries ?? this.maxRetries,
      initialBackoff: initialBackoff ?? this.initialBackoff,
      maxBackoff: maxBackoff ?? this.maxBackoff,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      useJitter: useJitter ?? this.useJitter,
      retryableExceptions: retryableExceptions ?? this.retryableExceptions,
    );
  }
}
