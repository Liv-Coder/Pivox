import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/proxy.dart';
import '../models/proxy_model.dart';

/// Cache tier levels for proxies
enum CacheTier {
  /// Primary cache for frequently used proxies
  primary,

  /// Secondary cache for occasionally used proxies
  secondary,

  /// Tertiary cache for rarely used proxies
  tertiary,
}

/// Manager for caching proxies in a tiered system
class ProxyCacheManager {
  /// SharedPreferences instance for persistent storage
  final SharedPreferences _sharedPreferences;

  /// Maximum number of proxies in the primary cache
  final int _primaryCacheSize;

  /// Maximum number of proxies in the secondary cache
  final int _secondaryCacheSize;

  /// Maximum number of proxies in the tertiary cache
  final int _tertiaryCacheSize;

  /// Key for the primary cache in SharedPreferences
  static const String _primaryCacheKey = 'pivox_primary_cache';

  /// Key for the secondary cache in SharedPreferences
  static const String _secondaryCacheKey = 'pivox_secondary_cache';

  /// Key for the tertiary cache in SharedPreferences
  static const String _tertiaryCacheKey = 'pivox_tertiary_cache';

  /// Key for the cache usage statistics in SharedPreferences
  static const String _cacheStatsKey = 'pivox_cache_stats';

  /// In-memory cache for primary tier
  final List<ProxyModel> _primaryCache = [];

  /// In-memory cache for secondary tier
  final List<ProxyModel> _secondaryCache = [];

  /// In-memory cache for tertiary tier
  final List<ProxyModel> _tertiaryCache = [];

  /// Usage statistics for cached proxies
  final Map<String, int> _usageStats = {};

  /// Creates a new [ProxyCacheManager] with the given parameters
  ProxyCacheManager({
    required SharedPreferences sharedPreferences,
    int primaryCacheSize = 10,
    int secondaryCacheSize = 50,
    int tertiaryCacheSize = 200,
  }) : _sharedPreferences = sharedPreferences,
       _primaryCacheSize = primaryCacheSize,
       _secondaryCacheSize = secondaryCacheSize,
       _tertiaryCacheSize = tertiaryCacheSize;

  /// Initializes the cache manager
  Future<void> initialize() async {
    await _loadCaches();
    await _loadUsageStats();
  }

  /// Loads all caches from persistent storage
  Future<void> _loadCaches() async {
    _loadCacheTier(CacheTier.primary);
    _loadCacheTier(CacheTier.secondary);
    _loadCacheTier(CacheTier.tertiary);
  }

  /// Loads a specific cache tier from persistent storage
  void _loadCacheTier(CacheTier tier) {
    final key = _getCacheKey(tier);
    final cacheJson = _sharedPreferences.getString(key);

    if (cacheJson != null) {
      final cacheList = jsonDecode(cacheJson) as List<dynamic>;
      final proxies =
          cacheList
              .map((item) => ProxyModel.fromJson(item as Map<String, dynamic>))
              .toList();

      switch (tier) {
        case CacheTier.primary:
          _primaryCache.clear();
          _primaryCache.addAll(proxies);
          break;
        case CacheTier.secondary:
          _secondaryCache.clear();
          _secondaryCache.addAll(proxies);
          break;
        case CacheTier.tertiary:
          _tertiaryCache.clear();
          _tertiaryCache.addAll(proxies);
          break;
      }
    }
  }

  /// Loads usage statistics from persistent storage
  Future<void> _loadUsageStats() async {
    final statsJson = _sharedPreferences.getString(_cacheStatsKey);

    if (statsJson != null) {
      final stats = jsonDecode(statsJson) as Map<String, dynamic>;
      _usageStats.clear();
      stats.forEach((key, value) {
        _usageStats[key] = value as int;
      });
    }
  }

  /// Saves all caches to persistent storage
  Future<void> _saveCaches() async {
    await _saveCacheTier(CacheTier.primary);
    await _saveCacheTier(CacheTier.secondary);
    await _saveCacheTier(CacheTier.tertiary);
  }

  /// Saves a specific cache tier to persistent storage
  Future<void> _saveCacheTier(CacheTier tier) async {
    final key = _getCacheKey(tier);
    final cache = _getCacheForTier(tier);

    final cacheJson = jsonEncode(cache.map((proxy) => proxy.toJson()).toList());
    await _sharedPreferences.setString(key, cacheJson);
  }

  /// Saves usage statistics to persistent storage
  Future<void> _saveUsageStats() async {
    final statsJson = jsonEncode(_usageStats);
    await _sharedPreferences.setString(_cacheStatsKey, statsJson);
  }

  /// Gets the cache key for a specific tier
  String _getCacheKey(CacheTier tier) {
    switch (tier) {
      case CacheTier.primary:
        return _primaryCacheKey;
      case CacheTier.secondary:
        return _secondaryCacheKey;
      case CacheTier.tertiary:
        return _tertiaryCacheKey;
    }
  }

  /// Gets the cache list for a specific tier
  List<ProxyModel> _getCacheForTier(CacheTier tier) {
    switch (tier) {
      case CacheTier.primary:
        return _primaryCache;
      case CacheTier.secondary:
        return _secondaryCache;
      case CacheTier.tertiary:
        return _tertiaryCache;
    }
  }

  /// Gets the maximum size for a specific tier
  int _getMaxSizeForTier(CacheTier tier) {
    switch (tier) {
      case CacheTier.primary:
        return _primaryCacheSize;
      case CacheTier.secondary:
        return _secondaryCacheSize;
      case CacheTier.tertiary:
        return _tertiaryCacheSize;
    }
  }

  /// Adds a proxy to the cache
  ///
  /// The proxy is added to the appropriate tier based on its usage statistics
  Future<void> addProxy(ProxyModel proxy) async {
    final proxyKey = '${proxy.ip}:${proxy.port}';

    // Increment usage count
    _usageStats[proxyKey] = (_usageStats[proxyKey] ?? 0) + 1;

    // Determine which tier to use based on usage count
    final usageCount = _usageStats[proxyKey] ?? 0;
    final tier = _getTierForUsageCount(usageCount);

    // Remove from current tier if it exists
    _removeProxyFromAllTiers(proxy);

    // Add to the appropriate tier
    final cache = _getCacheForTier(tier);
    cache.add(proxy);

    // Ensure the cache doesn't exceed its maximum size
    _enforceCacheSize(tier);

    // Save changes
    await _saveCaches();
    await _saveUsageStats();
  }

  /// Gets the appropriate tier for a given usage count
  CacheTier _getTierForUsageCount(int usageCount) {
    if (usageCount >= 10) {
      return CacheTier.primary;
    } else if (usageCount >= 3) {
      return CacheTier.secondary;
    } else {
      return CacheTier.tertiary;
    }
  }

  /// Removes a proxy from all tiers
  void _removeProxyFromAllTiers(Proxy proxy) {
    final proxyKey = '${proxy.ip}:${proxy.port}';

    _primaryCache.removeWhere((p) => '${p.ip}:${p.port}' == proxyKey);
    _secondaryCache.removeWhere((p) => '${p.ip}:${p.port}' == proxyKey);
    _tertiaryCache.removeWhere((p) => '${p.ip}:${p.port}' == proxyKey);
  }

  /// Ensures a cache tier doesn't exceed its maximum size
  void _enforceCacheSize(CacheTier tier) {
    final cache = _getCacheForTier(tier);
    final maxSize = _getMaxSizeForTier(tier);

    if (cache.length > maxSize) {
      // Sort by last used timestamp (most recent first)
      cache.sort((a, b) {
        final aLastUsed = a.score?.lastUsed ?? 0;
        final bLastUsed = b.score?.lastUsed ?? 0;
        return bLastUsed.compareTo(aLastUsed);
      });

      // Keep only the most recently used proxies
      while (cache.length > maxSize) {
        final removedProxy = cache.removeLast();

        // Move to a lower tier if possible
        if (tier == CacheTier.primary) {
          _secondaryCache.add(removedProxy);
          _enforceCacheSize(CacheTier.secondary);
        } else if (tier == CacheTier.secondary) {
          _tertiaryCache.add(removedProxy);
          _enforceCacheSize(CacheTier.tertiary);
        }
      }
    }
  }

  /// Gets all proxies from a specific tier
  List<ProxyModel> getProxiesFromTier(CacheTier tier) {
    return List.unmodifiable(_getCacheForTier(tier));
  }

  /// Gets all cached proxies from all tiers
  List<ProxyModel> getAllProxies() {
    final allProxies = <ProxyModel>[];
    allProxies.addAll(_primaryCache);
    allProxies.addAll(_secondaryCache);
    allProxies.addAll(_tertiaryCache);
    return allProxies;
  }

  /// Gets the most frequently used proxies
  List<ProxyModel> getMostFrequentlyUsedProxies({int count = 10}) {
    final allProxies = getAllProxies();

    // Sort by usage count (highest first)
    allProxies.sort((a, b) {
      final aKey = '${a.ip}:${a.port}';
      final bKey = '${b.ip}:${b.port}';
      final aCount = _usageStats[aKey] ?? 0;
      final bCount = _usageStats[bKey] ?? 0;
      return bCount.compareTo(aCount);
    });

    // Return the top N proxies
    return allProxies.take(count).toList();
  }

  /// Gets the most recently used proxies
  List<ProxyModel> getMostRecentlyUsedProxies({int count = 10}) {
    final allProxies = getAllProxies();

    // Sort by last used timestamp (most recent first)
    allProxies.sort((a, b) {
      final aLastUsed = a.score?.lastUsed ?? 0;
      final bLastUsed = b.score?.lastUsed ?? 0;
      return bLastUsed.compareTo(aLastUsed);
    });

    // Return the top N proxies
    return allProxies.take(count).toList();
  }

  /// Gets the best performing proxies based on their scores
  List<ProxyModel> getBestPerformingProxies({int count = 10}) {
    final allProxies =
        getAllProxies().where((proxy) => proxy.score != null).toList();

    // Sort by score (highest first)
    allProxies.sort((a, b) {
      final aScore = a.score?.calculateScore() ?? 0;
      final bScore = b.score?.calculateScore() ?? 0;
      return bScore.compareTo(aScore);
    });

    // Return the top N proxies
    return allProxies.take(count).toList();
  }

  /// Clears all caches
  Future<void> clearAllCaches() async {
    _primaryCache.clear();
    _secondaryCache.clear();
    _tertiaryCache.clear();
    _usageStats.clear();

    await _sharedPreferences.remove(_primaryCacheKey);
    await _sharedPreferences.remove(_secondaryCacheKey);
    await _sharedPreferences.remove(_tertiaryCacheKey);
    await _sharedPreferences.remove(_cacheStatsKey);
  }

  /// Gets cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'primaryCacheSize': _primaryCache.length,
      'secondaryCacheSize': _secondaryCache.length,
      'tertiaryCacheSize': _tertiaryCache.length,
      'totalCachedProxies':
          _primaryCache.length + _secondaryCache.length + _tertiaryCache.length,
      'uniqueProxiesTracked': _usageStats.length,
    };
  }
}
