import 'dart:async';

import '../../data/cache/proxy_cache_manager.dart';
import '../../data/models/proxy_model.dart';
import '../entities/proxy_filter_options.dart';
import '../entities/proxy_validation_options.dart';
import '../repositories/proxy_repository.dart';

/// Service for preloading and background validation of proxies
class ProxyPreloaderService {
  /// Repository for fetching and validating proxies
  final ProxyRepository _repository;

  /// Cache manager for storing preloaded proxies
  final ProxyCacheManager _cacheManager;

  /// Timer for periodic validation
  Timer? _validationTimer;

  /// Whether the service is currently preloading proxies
  bool _isPreloading = false;

  /// Whether the service is currently validating proxies
  bool _isValidating = false;

  /// The interval for periodic validation
  final Duration _validationInterval;

  /// Creates a new [ProxyPreloaderService] with the given parameters
  ProxyPreloaderService({
    required ProxyRepository repository,
    required ProxyCacheManager cacheManager,
    Duration validationInterval = const Duration(minutes: 30),
  }) : _repository = repository,
       _cacheManager = cacheManager,
       _validationInterval = validationInterval;

  /// Starts the preloader service
  Future<void> start() async {
    // Preload proxies immediately
    await preloadProxies();

    // Start periodic validation
    _validationTimer = Timer.periodic(_validationInterval, (_) {
      validateCachedProxies();
    });
  }

  /// Stops the preloader service
  void stop() {
    _validationTimer?.cancel();
    _validationTimer = null;
  }

  /// Preloads proxies into the cache
  Future<void> preloadProxies() async {
    if (_isPreloading) return;

    _isPreloading = true;

    try {
      // Fetch proxies from all sources
      final proxies = await _repository.fetchProxies(
        options: const ProxyFilterOptions(count: 100, onlyHttps: true),
      );

      // Convert to proxy models
      final proxyModels = proxies.whereType<ProxyModel>().toList();

      // Add to cache
      for (final proxy in proxyModels) {
        await _cacheManager.addProxy(proxy);
      }

      // Validate the proxies in the background
      validateCachedProxies();
    } finally {
      _isPreloading = false;
    }
  }

  /// Validates cached proxies in the background
  Future<void> validateCachedProxies() async {
    if (_isValidating) return;

    _isValidating = true;

    try {
      // Get proxies from primary cache first
      final primaryProxies = _cacheManager.getProxiesFromTier(
        CacheTier.primary,
      );

      // Validate primary proxies
      await _validateProxies(primaryProxies);

      // Get proxies from secondary cache
      final secondaryProxies = _cacheManager.getProxiesFromTier(
        CacheTier.secondary,
      );

      // Validate a subset of secondary proxies
      final secondarySubset = secondaryProxies.take(20).toList();
      await _validateProxies(secondarySubset);

      // Get proxies from tertiary cache
      final tertiaryProxies = _cacheManager.getProxiesFromTier(
        CacheTier.tertiary,
      );

      // Validate a small subset of tertiary proxies
      final tertiarySubset = tertiaryProxies.take(10).toList();
      await _validateProxies(tertiarySubset);
    } finally {
      _isValidating = false;
    }
  }

  /// Validates a list of proxies
  Future<void> _validateProxies(List<ProxyModel> proxies) async {
    if (proxies.isEmpty) return;

    // Validate proxies in parallel
    final results = await _repository.validateProxies(
      proxies,
      options: const ProxyValidationOptions(
        testUrl: 'https://www.google.com',
        timeout: 5000,
        updateScore: true,
      ),
    );

    // Update the cache with the validated proxies
    for (int i = 0; i < proxies.length; i++) {
      final proxy = proxies[i];
      final isValid = results[i];

      if (isValid) {
        // Update the proxy in the cache
        await _cacheManager.addProxy(proxy);
      }
    }
  }

  /// Gets preloaded proxies from the cache
  List<ProxyModel> getPreloadedProxies({int count = 10}) {
    // First try to get proxies from the primary cache
    var proxies = _cacheManager.getProxiesFromTier(CacheTier.primary);

    // If we don't have enough, get from the secondary cache
    if (proxies.length < count) {
      proxies = [
        ...proxies,
        ..._cacheManager.getProxiesFromTier(CacheTier.secondary),
      ];
    }

    // If we still don't have enough, get from the tertiary cache
    if (proxies.length < count) {
      proxies = [
        ...proxies,
        ..._cacheManager.getProxiesFromTier(CacheTier.tertiary),
      ];
    }

    // Sort by score
    proxies.sort((a, b) {
      final aScore = a.score?.calculateScore() ?? 0;
      final bScore = b.score?.calculateScore() ?? 0;
      return bScore.compareTo(aScore);
    });

    // Return the top N proxies
    return proxies.take(count).toList();
  }

  /// Gets the cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cacheManager.getCacheStats();
  }
}
