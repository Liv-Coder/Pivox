import 'dart:math';

import '../../data/models/proxy_model.dart';
import '../entities/proxy.dart';
import 'proxy_rotation_strategy.dart';

/// Weighted proxy rotation strategy that selects proxies based on their performance scores
class WeightedRotationStrategy implements ProxyRotationStrategy {
  /// The list of proxies to rotate through
  final List<Proxy> _proxies;

  /// Random number generator for weighted selection
  final Random _random = Random();

  /// The minimum weight to assign to a proxy
  final double minWeight;

  /// The maximum weight to assign to a proxy
  final double maxWeight;

  /// Creates a new [WeightedRotationStrategy] with the given parameters
  WeightedRotationStrategy({
    required List<Proxy> proxies,
    this.minWeight = 1.0,
    this.maxWeight = 10.0,
  }) : _proxies = List.from(proxies);

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    // Calculate weights for each proxy
    final weights = <double>[];
    double totalWeight = 0;

    for (final proxy in proxies) {
      final weight = _calculateWeight(proxy);
      weights.add(weight);
      totalWeight += weight;
    }

    // If all weights are zero, use equal weights
    if (totalWeight <= 0) {
      final equalWeight = 1.0 / proxies.length;
      for (int i = 0; i < weights.length; i++) {
        weights[i] = equalWeight;
      }
      totalWeight = 1.0;
    }

    // Select a proxy based on its weight
    double randomValue = _random.nextDouble() * totalWeight;
    double cumulativeWeight = 0;

    for (int i = 0; i < proxies.length; i++) {
      cumulativeWeight += weights[i];
      if (randomValue <= cumulativeWeight) {
        return proxies[i];
      }
    }

    // Fallback to the last proxy
    return proxies.last;
  }

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    // Calculate weights for each proxy
    final weights = <double>[];
    double totalWeight = 0;

    for (final proxy in _proxies) {
      final weight = _calculateWeight(proxy);
      weights.add(weight);
      totalWeight += weight;
    }

    // If all weights are zero, use equal weights
    if (totalWeight <= 0) {
      final equalWeight = 1.0 / _proxies.length;
      for (int i = 0; i < weights.length; i++) {
        weights[i] = equalWeight;
      }
      totalWeight = 1.0;
    }

    // Select a proxy based on its weight
    double randomValue = _random.nextDouble() * totalWeight;
    double cumulativeWeight = 0;

    for (int i = 0; i < _proxies.length; i++) {
      cumulativeWeight += weights[i];
      if (randomValue <= cumulativeWeight) {
        return _proxies[i];
      }
    }

    // Fallback to the last proxy
    return _proxies.last;
  }

  @override
  void recordSuccess(Proxy proxy) {
    // No need to record success for this strategy
  }

  @override
  void recordFailure(Proxy proxy) {
    // No need to record failure for this strategy
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
  }

  /// Calculates the weight for a proxy based on its performance score
  double _calculateWeight(Proxy proxy) {
    if (proxy is! ProxyModel || proxy.score == null) {
      return minWeight;
    }

    final score = proxy.score!;

    // Calculate a weight based on success rate and response time
    double weight = score.successRate * 10;

    // Adjust weight based on response time (lower is better)
    if (score.averageResponseTime > 0) {
      final responseTimeFactor = 1000 / (score.averageResponseTime + 100);
      weight *= responseTimeFactor;
    }

    // Ensure the weight is within the specified range
    return weight.clamp(minWeight, maxWeight);
  }
}
