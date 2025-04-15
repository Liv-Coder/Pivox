# Proxy Quality Scoring System

The Proxy Quality Scoring System is a sophisticated mechanism for tracking and evaluating the performance of proxies over time. This system helps in making intelligent decisions about which proxies to use for different requests.

## Overview

The scoring system tracks multiple metrics for each proxy:

- **Success Rate**: The percentage of successful requests made through the proxy
- **Response Time**: The average time it takes for the proxy to respond
- **Uptime**: The percentage of time the proxy is available
- **Stability**: How consistent the proxy's response times are
- **Consecutive Successes/Failures**: Tracks streaks of successful or failed requests
- **Age**: How long the proxy has been in the system
- **Geographical Distance**: Proximity to the target server (if available)

## How It Works

### Score Calculation

The composite score is calculated using a weighted formula:

```dart
final score = (successRate * 0.30) +
    (responseTimeScore * 0.20) +
    (uptime * 0.15) +
    (stability * 0.15) +
    (ageScore * 0.05) +
    (geoDistanceScore * 0.05) +
    (consecutiveSuccessScore * 0.10);
```

This produces a value between 0.0 and 1.0, where higher values indicate better performing proxies.

### Recording Results

After each request, the proxy's score is updated:

- **Successful Request**: Increases success rate, updates average response time, improves uptime and stability
- **Failed Request**: Decreases success rate, uptime, and stability

### Using Scores

The scoring system integrates with the proxy rotation strategies, particularly:

- **Weighted Strategy**: Selects proxies based on their scores, giving higher probability to better performing proxies
- **Adaptive Strategy**: Uses scores along with other factors to learn and adapt selection over time

## Implementation

The core of the scoring system is the `ProxyScore` class:

```dart
class ProxyScore {
  final double successRate;
  final int averageResponseTime;
  final int successfulRequests;
  final int failedRequests;
  final int lastUsed;
  final double uptime;
  final double stability;
  final int ageHours;
  final double geoDistanceScore;
  final int consecutiveSuccesses;
  final int consecutiveFailures;
  
  // Methods for updating scores and calculating composite score
  ProxyScore recordSuccess(double responseTime) { ... }
  ProxyScore recordFailure() { ... }
  double calculateScore() { ... }
}
```

## Usage

To use the scoring system:

1. Ensure your proxies are `ProxyModel` instances which track scores
2. After each request, record the result:

```dart
// After a successful request
final updatedProxy = proxy.withSuccessfulRequest(responseTime);

// After a failed request
final updatedProxy = proxy.withFailedRequest();
```

3. Use a rotation strategy that takes advantage of scores:

```dart
// Use weighted strategy
proxyManager.setRotationStrategy(RotationStrategyType.weighted);

// Or use adaptive strategy
proxyManager.setRotationStrategy(RotationStrategyType.adaptive);
```

## Benefits

- **Improved Reliability**: Automatically favors proxies with better performance
- **Self-Healing**: Naturally phases out poorly performing proxies
- **Optimized Performance**: Reduces overall response times by preferring faster proxies
- **Intelligent Selection**: Makes data-driven decisions about proxy selection
