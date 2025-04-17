import 'dart:math';

import '../entities/proxy.dart';
import 'rotation_strategy.dart';

/// A proxy rotation strategy that selects proxies based on geographic location
class GeographicRotationStrategy implements RotationStrategy {
  /// The target country code
  final String? targetCountry;

  /// The target region
  final String? targetRegion;

  /// The maximum latency in milliseconds
  final int? maxLatency;

  /// Whether to prefer proxies in the same region as the target
  final bool preferSameRegion;

  /// Whether to use latency-based selection
  final bool useLatencyBasedSelection;

  /// Random number generator for selection
  final Random _random;

  /// Creates a new [GeographicRotationStrategy]
  GeographicRotationStrategy({
    this.targetCountry,
    this.targetRegion,
    this.maxLatency,
    this.preferSameRegion = true,
    this.useLatencyBasedSelection = true,
    Random? random,
  }) : _random = random ?? Random();

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw Exception('No proxies available');
    }

    // Filter proxies by country if specified
    List<Proxy> filteredProxies = proxies;
    if (targetCountry != null && targetCountry!.isNotEmpty) {
      final countryProxies = proxies.where(
        (proxy) => proxy.country?.toLowerCase() == targetCountry!.toLowerCase(),
      ).toList();
      
      if (countryProxies.isNotEmpty) {
        filteredProxies = countryProxies;
      }
    }

    // Filter proxies by region if specified and preferSameRegion is true
    if (preferSameRegion && targetRegion != null && targetRegion!.isNotEmpty) {
      final regionProxies = filteredProxies.where(
        (proxy) => proxy.region?.toLowerCase() == targetRegion!.toLowerCase(),
      ).toList();
      
      if (regionProxies.isNotEmpty) {
        filteredProxies = regionProxies;
      }
    }

    // Filter proxies by latency if specified
    if (useLatencyBasedSelection && maxLatency != null && maxLatency! > 0) {
      final lowLatencyProxies = filteredProxies.where(
        (proxy) => proxy.latency != null && proxy.latency! <= maxLatency!,
      ).toList();
      
      if (lowLatencyProxies.isNotEmpty) {
        filteredProxies = lowLatencyProxies;
      }
    }

    // If no proxies match the criteria, use the original list
    if (filteredProxies.isEmpty) {
      filteredProxies = proxies;
    }

    // If using latency-based selection, select based on weighted latency
    if (useLatencyBasedSelection) {
      return _selectByLatency(filteredProxies);
    }

    // Otherwise, select randomly
    return filteredProxies[_random.nextInt(filteredProxies.length)];
  }

  /// Selects a proxy based on latency (lower latency = higher chance of selection)
  Proxy _selectByLatency(List<Proxy> proxies) {
    if (proxies.length == 1) {
      return proxies.first;
    }

    // Calculate weights based on inverse latency
    final weights = <double>[];
    double totalWeight = 0.0;

    for (final proxy in proxies) {
      // Use a default latency if not available
      final latency = proxy.latency ?? 1000;
      
      // Calculate weight as inverse of latency (lower latency = higher weight)
      // Add a small constant to avoid division by zero
      final weight = 1.0 / (latency + 10);
      weights.add(weight);
      totalWeight += weight;
    }

    // Normalize weights
    for (int i = 0; i < weights.length; i++) {
      weights[i] = weights[i] / totalWeight;
    }

    // Select a proxy based on weights
    final randomValue = _random.nextDouble();
    double cumulativeWeight = 0.0;

    for (int i = 0; i < proxies.length; i++) {
      cumulativeWeight += weights[i];
      if (randomValue <= cumulativeWeight) {
        return proxies[i];
      }
    }

    // Fallback (should never reach here)
    return proxies.last;
  }

  @override
  String get name => 'Geographic';

  @override
  String get description => 'Selects proxies based on geographic location';
}
