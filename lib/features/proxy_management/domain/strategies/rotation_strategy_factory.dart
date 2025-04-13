import '../entities/proxy.dart';
import 'advanced_rotation_strategy.dart';
import 'geo_rotation_strategy.dart';
import 'proxy_rotation_strategy.dart';
import 'random_rotation_strategy.dart';
import 'round_robin_rotation_strategy.dart';
import 'weighted_rotation_strategy.dart';

/// Type of proxy rotation strategy
enum RotationStrategyType {
  /// Round-robin rotation strategy
  roundRobin,
  
  /// Random rotation strategy
  random,
  
  /// Advanced rotation strategy
  advanced,
  
  /// Weighted rotation strategy
  weighted,
  
  /// Geo-based rotation strategy
  geoBased,
}

/// Factory for creating proxy rotation strategies
class RotationStrategyFactory {
  /// Creates a new proxy rotation strategy of the specified type
  static ProxyRotationStrategy createStrategy({
    required RotationStrategyType type,
    required List<Proxy> proxies,
  }) {
    switch (type) {
      case RotationStrategyType.roundRobin:
        return RoundRobinRotationStrategy(proxies: proxies);
      case RotationStrategyType.random:
        return RandomRotationStrategy(proxies: proxies);
      case RotationStrategyType.advanced:
        return AdvancedRotationStrategy(proxies: proxies);
      case RotationStrategyType.weighted:
        return WeightedRotationStrategy(proxies: proxies);
      case RotationStrategyType.geoBased:
        return GeoRotationStrategy(proxies: proxies);
    }
  }
  
  /// Returns the name of the specified rotation strategy type
  static String getStrategyName(RotationStrategyType type) {
    switch (type) {
      case RotationStrategyType.roundRobin:
        return 'Round Robin';
      case RotationStrategyType.random:
        return 'Random';
      case RotationStrategyType.advanced:
        return 'Advanced';
      case RotationStrategyType.weighted:
        return 'Weighted';
      case RotationStrategyType.geoBased:
        return 'Geo-Based';
    }
  }
  
  /// Returns the description of the specified rotation strategy type
  static String getStrategyDescription(RotationStrategyType type) {
    switch (type) {
      case RotationStrategyType.roundRobin:
        return 'Rotates through proxies in sequence';
      case RotationStrategyType.random:
        return 'Selects a random proxy each time';
      case RotationStrategyType.advanced:
        return 'Uses multiple factors to select the next proxy';
      case RotationStrategyType.weighted:
        return 'Selects proxies based on their performance scores';
      case RotationStrategyType.geoBased:
        return 'Rotates through proxies from different countries';
    }
  }
}
