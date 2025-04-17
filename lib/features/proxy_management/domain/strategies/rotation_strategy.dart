import '../entities/proxy.dart';

/// Interface for proxy rotation strategies
abstract class RotationStrategy {
  /// Selects a proxy from the given list
  Proxy selectProxy(List<Proxy> proxies);

  /// Gets the name of the strategy
  String get name;

  /// Gets the description of the strategy
  String get description;
}
