import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../entities/proxy.dart';
import '../entities/proxy_analytics.dart';

/// Service for tracking proxy usage analytics
abstract class ProxyAnalyticsService {
  /// Gets the current analytics data
  Future<ProxyAnalytics> getAnalytics();

  /// Records a proxy fetch operation
  Future<void> recordProxyFetch(List<Proxy> proxies);

  /// Records a proxy validation operation
  Future<void> recordProxyValidation(List<Proxy> proxies, List<bool> results);

  /// Records a request made through a proxy
  Future<void> recordRequest(
    Proxy proxy,
    bool success,
    int? responseTime,
    String source,
  );

  /// Resets the analytics data
  Future<void> resetAnalytics();
}

/// Implementation of [ProxyAnalyticsService] that uses SharedPreferences for storage
class ProxyAnalyticsServiceImpl implements ProxyAnalyticsService {
  /// SharedPreferences instance for storing analytics data
  final SharedPreferences _sharedPreferences;

  /// Key for storing analytics data in SharedPreferences
  static const String _analyticsKey = 'proxy_analytics';

  /// Current analytics data
  ProxyAnalytics? _analytics;

  /// Creates a new [ProxyAnalyticsServiceImpl] with the given [sharedPreferences]
  ProxyAnalyticsServiceImpl({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  @override
  Future<ProxyAnalytics> getAnalytics() async {
    if (_analytics != null) {
      return _analytics!;
    }

    final analyticsJson = _sharedPreferences.getString(_analyticsKey);
    if (analyticsJson != null) {
      try {
        _analytics = ProxyAnalytics.fromJson(
          Map<String, dynamic>.from(jsonDecode(analyticsJson) as Map),
        );
      } catch (e) {
        _analytics = ProxyAnalytics();
      }
    } else {
      _analytics = ProxyAnalytics();
    }

    return _analytics!;
  }

  @override
  Future<void> recordProxyFetch(List<Proxy> proxies) async {
    final analytics = await getAnalytics();
    _analytics = analytics.recordProxyFetch(proxies);
    await _saveAnalytics();
  }

  @override
  Future<void> recordProxyValidation(
    List<Proxy> proxies,
    List<bool> results,
  ) async {
    final analytics = await getAnalytics();
    _analytics = analytics.recordProxyValidation(proxies, results);
    await _saveAnalytics();
  }

  @override
  Future<void> recordRequest(
    Proxy proxy,
    bool success,
    int? responseTime,
    String source,
  ) async {
    final analytics = await getAnalytics();
    _analytics = analytics.recordRequest(proxy, success, responseTime, source);
    await _saveAnalytics();
  }

  @override
  Future<void> resetAnalytics() async {
    _analytics = ProxyAnalytics();
    await _saveAnalytics();
  }

  /// Saves the current analytics data to SharedPreferences
  Future<void> _saveAnalytics() async {
    if (_analytics != null) {
      await _sharedPreferences.setString(
        _analyticsKey,
        jsonEncode(_analytics!.toJson()),
      );
    }
  }
}
