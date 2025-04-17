import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/proxy_model.dart';

/// Interface for local data source to cache proxies
abstract class ProxyLocalDataSource {
  /// Caches a list of proxies
  ///
  /// [proxies] is the list of proxies to cache
  Future<void> cacheProxies(List<ProxyModel> proxies);

  /// Gets the cached proxies
  Future<List<ProxyModel>> getCachedProxies();

  /// Caches a list of validated proxies
  ///
  /// [proxies] is the list of validated proxies to cache
  Future<void> cacheValidatedProxies(List<ProxyModel> proxies);

  /// Gets the cached validated proxies
  Future<List<ProxyModel>> getCachedValidatedProxies();
}

/// Implementation of [ProxyLocalDataSource] using SharedPreferences
class ProxyLocalDataSourceImpl implements ProxyLocalDataSource {
  /// SharedPreferences instance for storing data
  final SharedPreferences sharedPreferences;

  /// Key for storing proxies in SharedPreferences
  static const String cachedProxiesKey = 'CACHED_PROXIES';

  /// Key for storing validated proxies in SharedPreferences
  static const String cachedValidatedProxiesKey = 'CACHED_VALIDATED_PROXIES';

  /// Creates a new [ProxyLocalDataSourceImpl] with the given [sharedPreferences]
  const ProxyLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheProxies(List<ProxyModel> proxies) async {
    final jsonList = proxies.map((proxy) => proxy.toJson()).toList();
    final jsonString = json.encode(jsonList);

    await sharedPreferences.setString(cachedProxiesKey, jsonString);
  }

  @override
  Future<List<ProxyModel>> getCachedProxies() async {
    final jsonString = sharedPreferences.getString(cachedProxiesKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((item) => ProxyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ProxyFetchException('Failed to parse cached proxies: $e');
    }
  }

  @override
  Future<void> cacheValidatedProxies(List<ProxyModel> proxies) async {
    final jsonList = proxies.map((proxy) => proxy.toJson()).toList();
    final jsonString = json.encode(jsonList);

    await sharedPreferences.setString(cachedValidatedProxiesKey, jsonString);
  }

  @override
  Future<List<ProxyModel>> getCachedValidatedProxies() async {
    final jsonString = sharedPreferences.getString(cachedValidatedProxiesKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((item) => ProxyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ProxyFetchException('Failed to parse cached validated proxies: $e');
    }
  }
}
