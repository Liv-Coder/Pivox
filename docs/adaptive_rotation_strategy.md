# Adaptive Proxy Rotation Strategy

The Adaptive Proxy Rotation Strategy is an intelligent proxy selection mechanism that learns from past performance and adapts its selection criteria over time.

## Overview

Unlike static rotation strategies, the Adaptive Strategy:

- Learns from the success and failure of each proxy
- Adjusts weights dynamically based on performance
- Balances exploration of new proxies with exploitation of known good proxies
- Considers multiple factors including response time, success rate, and time since last use

## How It Works

### Weight-Based Selection

The strategy assigns and maintains weights for each proxy. These weights are adjusted based on:

- Success/failure of requests
- Historical performance patterns
- Time since last use (to prevent overuse of a single proxy)

### Exploration vs. Exploitation

The strategy balances two competing needs:

- **Exploration**: Trying different proxies to discover their performance characteristics
- **Exploitation**: Using proxies that are known to perform well

This is controlled by the `explorationRate` parameter (default: 0.2), which determines the probability of selecting a random proxy instead of using the weighted selection.

### Weight Decay

To prevent stale information from dominating decisions, weights decay over time if a proxy hasn't been used recently. This ensures that:

- Proxies that haven't been used for a while get a chance to be selected again
- Recent performance has more influence than older performance

## Implementation

The core implementation is in the `AdaptiveRotationStrategy` class:

```dart
class AdaptiveRotationStrategy implements ProxyRotationStrategy {
  final double learningRate;
  final double explorationRate;
  final double minWeight;
  final double maxWeight;
  final double decayFactor;
  
  // Maps to track proxy performance
  final Map<String, double> _weights = {};
  final Map<String, List<bool>> _history = {};
  final Map<String, int> _lastUsed = {};
  
  // Methods for selecting proxies and recording results
  Proxy selectProxy(List<Proxy> proxies) { ... }
  void recordSuccess(Proxy proxy) { ... }
  void recordFailure(Proxy proxy) { ... }
}
```

## Usage

To use the Adaptive Rotation Strategy:

```dart
// Set the rotation strategy to adaptive
proxyManager.setRotationStrategy(RotationStrategyType.adaptive);

// Get the next proxy
final proxy = proxyManager.getNextProxy();

// Make your request using the proxy
final response = await makeRequest(url, proxy: proxy);

// Record the result
if (response.isSuccessful) {
  proxyManager.recordSuccess(proxy);
} else {
  proxyManager.recordFailure(proxy);
}
```

## Benefits

- **Self-Optimizing**: Automatically learns which proxies perform best
- **Resilient**: Adapts to changing proxy performance over time
- **Balanced**: Prevents overuse of any single proxy
- **Efficient**: Maximizes the value of your proxy pool by favoring better proxies

## Configuration

The strategy can be configured with several parameters:

- `learningRate`: How quickly the strategy adapts to new information (default: 0.1)
- `explorationRate`: Probability of trying a random proxy (default: 0.2)
- `minWeight`: Minimum weight for any proxy (default: 0.1)
- `maxWeight`: Maximum weight for any proxy (default: 10.0)
- `decayFactor`: How quickly weights decay over time (default: 0.99)
