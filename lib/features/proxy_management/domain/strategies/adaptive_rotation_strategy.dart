import 'dart:math';

import '../../domain/entities/proxy.dart';
import '../../data/models/proxy_model.dart';
import 'proxy_rotation_strategy.dart';

/// A rotation strategy that adapts to the performance of proxies
///
/// This strategy uses a combination of factors to select the best proxy:
/// - Success rate
/// - Response time
/// - Uptime
/// - Consecutive successes/failures
/// - Time since last use
class AdaptiveRotationStrategy implements ProxyRotationStrategy {
  /// The list of proxies to rotate through
  final List<Proxy> _proxies = [];

  /// The index of the last selected proxy
  int _lastIndex = -1;

  /// The random number generator
  final Random _random = Random();

  /// The learning rate for adapting weights (0.0 to 1.0)
  final double learningRate;

  /// The exploration rate for trying new proxies (0.0 to 1.0)
  final double explorationRate;

  /// The minimum weight for a proxy
  final double minWeight;

  /// The maximum weight for a proxy
  final double maxWeight;

  /// The decay factor for weights over time
  final double decayFactor;

  /// The weights for each proxy
  final Map<String, double> _weights = {};

  /// The performance history for each proxy
  final Map<String, List<bool>> _history = {};

  /// The timestamp of the last use for each proxy
  final Map<String, int> _lastUsed = {};

  /// Creates a new [AdaptiveRotationStrategy]
  AdaptiveRotationStrategy({
    this.learningRate = 0.1,
    this.explorationRate = 0.2,
    this.minWeight = 0.1,
    this.maxWeight = 10.0,
    this.decayFactor = 0.99,
  });

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);

    // Initialize weights for new proxies
    for (final proxy in proxies) {
      final key = _getProxyKey(proxy);
      if (!_weights.containsKey(key)) {
        _weights[key] = 1.0;
        _history[key] = [];
      }
    }

    // Remove weights for proxies that are no longer in the list
    final keysToRemove = <String>[];
    for (final key in _weights.keys) {
      if (!proxies.any((p) => _getProxyKey(p) == key)) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _weights.remove(key);
      _history.remove(key);
      _lastUsed.remove(key);
    }
  }

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }
    return selectProxy(_proxies);
  }

  /// Selects a proxy from the given list
  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw Exception('No proxies available');
    }

    // Update the proxy list if it has changed
    if (_proxies.isEmpty || _proxies.length != proxies.length) {
      updateProxies(proxies);
    }

    // Apply time-based weight decay
    _applyWeightDecay();

    // Decide whether to explore or exploit
    if (_random.nextDouble() < explorationRate) {
      // Exploration: select a random proxy
      final index = _random.nextInt(proxies.length);
      _lastIndex = index;
      final proxy = proxies[index];

      // Record the time of use
      _lastUsed[_getProxyKey(proxy)] = DateTime.now().millisecondsSinceEpoch;

      return proxy;
    } else {
      // Exploitation: select the best proxy based on weights
      return _selectBestProxy(proxies);
    }
  }

  /// Selects the best proxy based on weights and other factors
  Proxy _selectBestProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw Exception('No proxies available');
    }

    // Calculate the total weight
    double totalWeight = 0.0;
    final weights = <double>[];

    for (final proxy in proxies) {
      final key = _getProxyKey(proxy);
      final baseWeight = _weights[key] ?? 1.0;

      // Adjust weight based on proxy score if available
      double adjustedWeight = baseWeight;
      if (proxy is ProxyModel && proxy.score != null) {
        final score = proxy.score!.calculateScore();
        adjustedWeight = baseWeight * (1.0 + score);
      }

      // Adjust weight based on time since last use
      final lastUsed = _lastUsed[key] ?? 0;
      final timeSinceLastUse = DateTime.now().millisecondsSinceEpoch - lastUsed;
      final timeBonus = timeSinceLastUse / 60000; // Bonus per minute
      adjustedWeight = adjustedWeight * (1.0 + timeBonus.clamp(0.0, 5.0) * 0.1);

      // Clamp the weight
      final clampedWeight = adjustedWeight.clamp(minWeight, maxWeight);

      weights.add(clampedWeight);
      totalWeight += clampedWeight;
    }

    // If all weights are zero, use equal weights
    if (totalWeight <= 0.0) {
      final equalWeight = 1.0 / proxies.length;
      for (var i = 0; i < weights.length; i++) {
        weights[i] = equalWeight;
      }
      totalWeight = 1.0;
    }

    // Select a proxy using weighted random selection
    final selection = _random.nextDouble() * totalWeight;
    double cumulativeWeight = 0.0;

    for (var i = 0; i < proxies.length; i++) {
      cumulativeWeight += weights[i];
      if (cumulativeWeight >= selection) {
        _lastIndex = i;
        final proxy = proxies[i];

        // Record the time of use
        _lastUsed[_getProxyKey(proxy)] = DateTime.now().millisecondsSinceEpoch;

        return proxy;
      }
    }

    // Fallback to the last proxy (should not happen)
    _lastIndex = proxies.length - 1;
    return proxies[_lastIndex];
  }

  @override
  void recordSuccess(Proxy proxy) {
    recordResult(proxy, true);
  }

  @override
  void recordFailure(Proxy proxy) {
    recordResult(proxy, false);
  }

  /// Records the result of using a proxy
  void recordResult(Proxy proxy, bool success) {
    final key = _getProxyKey(proxy);

    // Update history
    final history = _history[key] ?? [];
    history.add(success);

    // Keep only the last 10 results
    if (history.length > 10) {
      history.removeAt(0);
    }
    _history[key] = history;

    // Update weight based on the most recent result
    final currentWeight = _weights[key] ?? 1.0;
    final targetWeight =
        success
            ? currentWeight * (1.0 + learningRate)
            : currentWeight * (1.0 - learningRate);
    _weights[key] = targetWeight.clamp(minWeight, maxWeight);
  }

  /// Applies weight decay based on time
  void _applyWeightDecay() {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in _weights.keys) {
      final lastUsed = _lastUsed[key] ?? 0;
      final hoursSinceLastUse = (now - lastUsed) / (1000 * 60 * 60);

      // Apply decay if not used recently
      if (hoursSinceLastUse > 1.0) {
        final decayAmount = pow(decayFactor, hoursSinceLastUse);
        _weights[key] = (_weights[key]! * decayAmount).clamp(
          minWeight,
          maxWeight,
        );
      }
    }
  }

  /// Gets a unique key for a proxy
  String _getProxyKey(Proxy proxy) {
    return '${proxy.ip}:${proxy.port}';
  }

  @override
  String toString() => 'AdaptiveRotationStrategy';
}
