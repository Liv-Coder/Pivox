import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../../core/config/proxy_source_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/parallel_processor.dart';
import '../../domain/entities/proxy.dart';
import '../../domain/repositories/proxy_repository.dart';
import '../../domain/services/proxy_analytics_service.dart';
import '../datasources/proxy_local_datasource.dart';
import '../datasources/proxy_remote_datasource.dart';
import '../models/proxy_model.dart';

/// Implementation of [ProxyRepository]
class ProxyRepositoryImpl implements ProxyRepository {
  /// Remote data source for fetching proxies
  final ProxyRemoteDataSource remoteDataSource;

  /// Local data source for caching proxies
  final ProxyLocalDataSource localDataSource;

  /// HTTP client for validating proxies
  final http.Client client;

  /// Parallel processor for validating proxies
  final ParallelProcessor<Proxy, bool> _parallelProcessor;

  /// Maximum number of concurrent validation tasks
  final int maxConcurrentValidations;

  /// Configuration for proxy sources
  final ProxySourceConfig sourceConfig;

  /// Analytics service for tracking proxy usage
  final ProxyAnalyticsService? analyticsService;

  /// Creates a new [ProxyRepositoryImpl] with the given dependencies
  ProxyRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.client,
    this.maxConcurrentValidations = 5,
    this.sourceConfig = const ProxySourceConfig(),
    this.analyticsService,
  }) : _parallelProcessor = ParallelProcessor<Proxy, bool>(
         maxConcurrency: maxConcurrentValidations,
       );

  @override
  Future<List<Proxy>> fetchProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(),
  }) async {
    try {
      // Try to get proxies from the remote data source
      final remoteProxies = await remoteDataSource.fetchProxies(
        count: options.count,
        onlyHttps: options.onlyHttps,
        countries: options.countries,
      );

      // Cache the fetched proxies
      await localDataSource.cacheProxies(remoteProxies);

      // Apply additional filters that the remote data source might not support
      final filteredProxies = _applyAdvancedFilters(remoteProxies, options);

      // Track analytics
      if (analyticsService != null) {
        await analyticsService!.recordProxyFetch(filteredProxies);
      }

      return filteredProxies.take(options.count).toList();
    } catch (e) {
      // If remote fetch fails, try to get cached proxies
      try {
        final cachedProxies = await localDataSource.getCachedProxies();

        // Apply all filters to cached proxies
        final filteredProxies = _applyAdvancedFilters(cachedProxies, options);

        return filteredProxies.take(options.count).toList();
      } catch (_) {
        // If both remote and cache fail, rethrow the original exception
        throw ProxyFetchException('Failed to fetch proxies: $e');
      }
    }
  }

  @override
  Future<List<Proxy>> fetchProxiesLegacy({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  }) {
    return fetchProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
    );
  }

  /// Applies advanced filters to a list of proxies
  List<Proxy> _applyAdvancedFilters(
    List<Proxy> proxies,
    ProxyFilterOptions options,
  ) {
    return proxies.where((proxy) {
      // Basic filters
      if (options.onlyHttps && !proxy.isHttps) return false;

      if (options.countries != null &&
          options.countries!.isNotEmpty &&
          proxy.countryCode != null &&
          !options.countries!.contains(proxy.countryCode)) {
        return false;
      }

      // Advanced filters
      if (options.regions != null &&
          options.regions!.isNotEmpty &&
          proxy.region != null &&
          !options.regions!.contains(proxy.region)) {
        return false;
      }

      if (options.isps != null &&
          options.isps!.isNotEmpty &&
          proxy.isp != null &&
          !options.isps!.contains(proxy.isp)) {
        return false;
      }

      if (options.minSpeed != null &&
          proxy.speed != null &&
          proxy.speed! < options.minSpeed!) {
        return false;
      }

      if (options.requireWebsockets == true &&
          (proxy.supportsWebsockets == null || !proxy.supportsWebsockets!)) {
        return false;
      }

      if (options.requireSocks == true &&
          (proxy.supportsSocks == null || !proxy.supportsSocks!)) {
        return false;
      }

      if (options.socksVersion != null &&
          (proxy.socksVersion == null ||
              proxy.socksVersion != options.socksVersion)) {
        return false;
      }

      if (options.requireAuthentication == true && !proxy.isAuthenticated) {
        return false;
      }

      if (options.requireAnonymous == true &&
          (proxy.anonymityLevel == null ||
              !proxy.anonymityLevel!.toLowerCase().contains('anonymous'))) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<bool> validateProxy(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
  }) async {
    final url = testUrl ?? 'https://www.google.com';
    final uri = Uri.parse(url);

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = Duration(milliseconds: timeout);

      // Set up the proxy
      httpClient.findProxy = (uri) {
        return 'PROXY ${proxy.ip}:${proxy.port}';
      };

      // Set up authentication if needed
      if (proxy.isAuthenticated) {
        httpClient.authenticate = (Uri url, String scheme, String? realm) {
          httpClient.addCredentials(
            url,
            realm ?? '',
            HttpClientBasicCredentials(proxy.username!, proxy.password!),
          );
          return Future.value(true);
        };
      }

      // Record start time for response time measurement
      final startTime = DateTime.now().millisecondsSinceEpoch;

      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      // Calculate response time
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final responseTime = endTime - startTime;

      // Close the client
      httpClient.close();

      // Check if the response is successful
      final success = response.statusCode >= 200 && response.statusCode < 300;

      // Track analytics
      if (analyticsService != null) {
        await analyticsService!.recordRequest(
          proxy,
          success,
          responseTime,
          'validation',
        );
      }

      return success;
    } catch (e) {
      // Track analytics for failed request
      if (analyticsService != null) {
        await analyticsService!.recordRequest(proxy, false, null, 'validation');
      }

      return false;
    }
  }

  @override
  Future<List<Proxy>> getValidatedProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(count: 10),
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      // Try to get cached validated proxies first
      final cachedValidatedProxies =
          await localDataSource.getCachedValidatedProxies();

      // Apply all filters to cached validated proxies
      final filteredProxies = _applyAdvancedFilters(
        cachedValidatedProxies,
        options,
      );

      if (filteredProxies.isNotEmpty) {
        return filteredProxies.take(options.count).toList();
      }

      // If no cached validated proxies, fetch new proxies and validate them
      final proxies = await fetchProxies(
        options: ProxyFilterOptions(
          count:
              options.count *
              3, // Fetch more to increase chances of finding valid ones
          onlyHttps: options.onlyHttps,
          countries: options.countries,
          regions: options.regions,
          isps: options.isps,
          minSpeed: options.minSpeed,
          requireWebsockets: options.requireWebsockets,
          requireSocks: options.requireSocks,
          socksVersion: options.socksVersion,
          requireAuthentication: options.requireAuthentication,
          requireAnonymous: options.requireAnonymous,
        ),
      );

      // Validate proxies in parallel
      final validationResults = await _parallelProcessor.process(
        items: proxies,
        processFunction:
            (proxy) => validateProxy(proxy, testUrl: 'https://www.google.com'),
        onProgress: onProgress,
      );

      // Track analytics
      if (analyticsService != null) {
        await analyticsService!.recordProxyValidation(
          proxies,
          validationResults,
        );
      }

      // Collect validated proxies
      final validatedProxies = <ProxyModel>[];

      for (var i = 0; i < proxies.length; i++) {
        if (validatedProxies.length >= options.count) break;

        if (validationResults[i]) {
          final proxy = proxies[i];
          final proxyModel =
              proxy is ProxyModel ? proxy : ProxyModel.fromEntity(proxy);

          validatedProxies.add(proxyModel);
        }
      }

      // Cache the validated proxies
      await localDataSource.cacheValidatedProxies(validatedProxies);

      return validatedProxies;
    } catch (e) {
      throw ProxyValidationException('Failed to get validated proxies: $e');
    }
  }

  @override
  Future<List<Proxy>> getValidatedProxiesLegacy({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) {
    return getValidatedProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
      onProgress: onProgress,
    );
  }
}
