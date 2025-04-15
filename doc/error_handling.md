# Enhanced Error Handling and Retry Logic

The Enhanced Error Handling and Retry Logic system provides robust mechanisms for handling proxy-related errors and implementing intelligent retry strategies.

## Error Types

The system defines specific error types for different proxy-related issues:

- **NoProxiesAvailableError**: Thrown when no proxies are available
- **ProxyConnectionError**: Thrown when a connection to a proxy fails
- **ProxyAuthenticationError**: Thrown when authentication with a proxy fails
- **ProxyTimeoutError**: Thrown when a proxy request times out
- **ProxyBlockedError**: Thrown when a proxy is blocked or banned by the target
- **AllProxiesExhaustedError**: Thrown when all available proxies have been tried without success
- **ProxyValidationError**: Thrown when a proxy fails validation
- **ProxyRateLimitedError**: Thrown when a proxy is rate limited
- **ProxyInvalidResponseError**: Thrown when a proxy returns an invalid response

These specific error types allow for more precise error handling and recovery strategies.

## Retry Policy

The `ProxyRetryPolicy` class implements sophisticated retry logic with features like:

- **Exponential Backoff**: Increasing delay between retries
- **Jitter**: Random variation in retry delays to prevent thundering herd problems
- **Configurable Retry Limits**: Control how many retries are attempted
- **Selective Retry**: Only retry for specific error types

### Example Retry Policies

#### No Retry
```dart
final policy = ProxyRetryPolicy.noRetry();
```

#### Fixed Delay
```dart
final policy = ProxyRetryPolicy.fixedDelay(
  maxRetries: 3,
  delay: Duration(seconds: 1),
);
```

#### Exponential Backoff
```dart
final policy = ProxyRetryPolicy.exponentialBackoff(
  maxRetries: 5,
  initialBackoff: Duration(milliseconds: 500),
  maxBackoff: Duration(seconds: 30),
  backoffMultiplier: 2.0,
  useJitter: true,
);
```

## Usage

### Basic Usage

```dart
final policy = ProxyRetryPolicy.exponentialBackoff();

try {
  final result = await policy.execute(() async {
    // Your proxy operation here
    return await makeRequestWithProxy(url, proxy);
  });
  // Handle successful result
} catch (e) {
  // Handle error after all retries have failed
}
```

### Advanced Usage

```dart
final policy = ProxyRetryPolicy(
  maxRetries: 3,
  initialBackoff: Duration(milliseconds: 500),
  maxBackoff: Duration(seconds: 10),
  backoffMultiplier: 2.0,
  useJitter: true,
  retryableExceptions: {
    ProxyConnectionError,
    ProxyTimeoutError,
    ProxyRateLimitedError,
  },
);

try {
  final result = await policy.execute(() async {
    try {
      return await makeRequestWithProxy(url, proxy);
    } catch (e) {
      // Convert generic errors to specific proxy errors
      if (e is TimeoutException) {
        throw ProxyTimeoutError(
          host: proxy.ip,
          port: proxy.port,
          timeoutMs: 10000,
        );
      }
      rethrow;
    }
  });
  // Handle successful result
} catch (e) {
  if (e is ProxyBlockedError) {
    // Handle blocked proxy
  } else if (e is ProxyRateLimitedError) {
    // Handle rate limited proxy
  } else {
    // Handle other errors
  }
}
```

## Benefits

- **Improved Resilience**: Automatically recover from transient errors
- **Reduced Failure Rate**: Multiple retry attempts increase chances of success
- **Intelligent Backoff**: Avoid overwhelming services with immediate retries
- **Specific Error Handling**: Handle different error types with appropriate strategies
- **Better Diagnostics**: More specific error types provide better insights into issues
