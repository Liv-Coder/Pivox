import 'dart:math';

import '../entities/proxy.dart';
import '../../data/models/proxy_model.dart';

/// Abstract class for proxy rotation strategies
abstract class ProxyRotationStrategy {
  /// Selects the next proxy from the given list
  Proxy selectProxy(List<Proxy> proxies);

  /// Gets the next proxy from the internal list
  Proxy? getNextProxy();

  /// Records a successful request with a proxy
  void recordSuccess(Proxy proxy);

  /// Records a failed request with a proxy
  void recordFailure(Proxy proxy);

  /// Updates the internal list of proxies
  void updateProxies(List<Proxy> proxies);
}

/// Round-robin proxy rotation strategy
class RoundRobinStrategy implements ProxyRotationStrategy {
  /// Current index in the proxy list
  int _currentIndex = 0;

  /// Internal list of proxies
  final List<Proxy> _proxies = [];

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    final proxy = proxies[_currentIndex];
    _currentIndex = (_currentIndex + 1) % proxies.length;
    return proxy;
  }

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    final proxy = _proxies[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _proxies.length;
    return proxy;
  }

  @override
  void recordSuccess(Proxy proxy) {
    // Round-robin strategy doesn't need to track success
  }

  @override
  void recordFailure(Proxy proxy) {
    // Round-robin strategy doesn't need to track failure
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
    _currentIndex = 0;
  }
}

/// Random proxy rotation strategy
class RandomStrategy implements ProxyRotationStrategy {
  /// Random number generator
  final _random = Random();

  /// Internal list of proxies
  final List<Proxy> _proxies = [];

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    final index = _random.nextInt(proxies.length);
    return proxies[index];
  }

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    final index = _random.nextInt(_proxies.length);
    return _proxies[index];
  }

  @override
  void recordSuccess(Proxy proxy) {
    // Random strategy doesn't need to track success
  }

  @override
  void recordFailure(Proxy proxy) {
    // Random strategy doesn't need to track failure
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
  }
}

/// Weighted random proxy rotation strategy based on proxy scores
class WeightedStrategy implements ProxyRotationStrategy {
  /// Random number generator
  final _random = Random();

  /// Internal list of proxies
  final List<Proxy> _proxies = [];

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    // Calculate total weight
    double totalWeight = 0;
    final weights = <double>[];

    for (final proxy in proxies) {
      // Default weight is 1.0 if no score is available
      double weight = 1.0;
      if (proxy is ProxyModel && proxy.score != null) {
        weight = proxy.score!.calculateScore();
      }
      weights.add(weight);
      totalWeight += weight;
    }

    // Generate a random value between 0 and totalWeight
    final random = _random.nextDouble();
    final target = random * totalWeight;

    // Find the proxy that corresponds to the random value
    double cumulativeWeight = 0;
    for (int i = 0; i < proxies.length; i++) {
      cumulativeWeight += weights[i];
      if (cumulativeWeight >= target) {
        return proxies[i];
      }
    }

    // Fallback to the last proxy (should not happen)
    return proxies.last;
  }

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    // Calculate total weight
    double totalWeight = 0;
    final weights = <double>[];

    for (final proxy in _proxies) {
      // Default weight is 1.0 if no score is available
      double weight = 1.0;
      if (proxy is ProxyModel && proxy.score != null) {
        weight = proxy.score!.calculateScore();
      }
      weights.add(weight);
      totalWeight += weight;
    }

    // Generate a random value between 0 and totalWeight
    final random = _random.nextDouble();
    final target = random * totalWeight;

    // Find the proxy that corresponds to the random value
    double cumulativeWeight = 0;
    for (int i = 0; i < _proxies.length; i++) {
      cumulativeWeight += weights[i];
      if (cumulativeWeight >= target) {
        return _proxies[i];
      }
    }

    // Fallback to the last proxy (should not happen)
    return _proxies.last;
  }

  @override
  void recordSuccess(Proxy proxy) {
    // Weighted strategy doesn't need to track success directly
    // as it uses the proxy score which is updated elsewhere
  }

  @override
  void recordFailure(Proxy proxy) {
    // Weighted strategy doesn't need to track failure directly
    // as it uses the proxy score which is updated elsewhere
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
  }
}

/// Least recently used proxy rotation strategy
class LeastRecentlyUsedStrategy implements ProxyRotationStrategy {
  /// Internal list of proxies
  final List<Proxy> _proxies = [];

  /// Map of last used timestamps
  final Map<String, int> _lastUsedMap = {};

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    // Sort proxies by last used timestamp (ascending)
    final sortedProxies = List<Proxy>.from(proxies)..sort((a, b) {
      int aLastUsed = 0;
      int bLastUsed = 0;

      if (a is ProxyModel && a.score != null) {
        aLastUsed = a.score!.lastUsed;
      }

      if (b is ProxyModel && b.score != null) {
        bLastUsed = b.score!.lastUsed;
      }

      return aLastUsed.compareTo(bLastUsed);
    });

    return sortedProxies.first;
  }

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty) {
      return null;
    }

    // Sort proxies by last used timestamp (ascending)
    final sortedProxies = List<Proxy>.from(_proxies)..sort((a, b) {
      final aKey = '${a.ip}:${a.port}';
      final bKey = '${b.ip}:${b.port}';
      final aLastUsed = _lastUsedMap[aKey] ?? 0;
      final bLastUsed = _lastUsedMap[bKey] ?? 0;
      return aLastUsed.compareTo(bLastUsed);
    });

    final proxy = sortedProxies.first;
    final proxyKey = '${proxy.ip}:${proxy.port}';
    _lastUsedMap[proxyKey] = DateTime.now().millisecondsSinceEpoch;

    return proxy;
  }

  @override
  void recordSuccess(Proxy proxy) {
    final proxyKey = '${proxy.ip}:${proxy.port}';
    _lastUsedMap[proxyKey] = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void recordFailure(Proxy proxy) {
    // LRU strategy doesn't need special handling for failures
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
  }
}

/// Factory for creating proxy rotation strategies
class ProxyRotationStrategyFactory {
  /// Creates a proxy rotation strategy based on the given type
  static ProxyRotationStrategy create(RotationStrategyType type) {
    switch (type) {
      case RotationStrategyType.roundRobin:
        return RoundRobinStrategy();
      case RotationStrategyType.random:
        return RandomStrategy();
      case RotationStrategyType.weighted:
        return WeightedStrategy();
      case RotationStrategyType.leastRecentlyUsed:
        return LeastRecentlyUsedStrategy();
    }
  }
}

/// Enum for proxy rotation strategy types
enum RotationStrategyType {
  /// Round-robin strategy
  roundRobin,

  /// Random strategy
  random,

  /// Weighted random strategy based on proxy scores
  weighted,

  /// Least recently used strategy
  leastRecentlyUsed,
}
