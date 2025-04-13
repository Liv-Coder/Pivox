import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/proxy.dart';
import '../../domain/repositories/proxy_repository.dart';
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

  /// Creates a new [ProxyRepositoryImpl] with the given dependencies
  const ProxyRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.client,
  });

  @override
  Future<List<Proxy>> fetchProxies({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  }) async {
    try {
      // Try to get proxies from the remote data source
      final remoteProxies = await remoteDataSource.fetchProxies(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      );
      
      // Cache the fetched proxies
      await localDataSource.cacheProxies(remoteProxies);
      
      return remoteProxies;
    } catch (e) {
      // If remote fetch fails, try to get cached proxies
      try {
        final cachedProxies = await localDataSource.getCachedProxies();
        
        // Filter cached proxies based on the parameters
        final filteredProxies = cachedProxies.where((proxy) {
          if (onlyHttps && !proxy.isHttps) return false;
          
          if (countries != null && countries.isNotEmpty && 
              proxy.countryCode != null && 
              !countries.contains(proxy.countryCode)) {
            return false;
          }
          
          return true;
        }).toList();
        
        return filteredProxies.take(count).toList();
      } catch (_) {
        // If both remote and cache fail, rethrow the original exception
        throw ProxyFetchException('Failed to fetch proxies: $e');
      }
    }
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
      
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      
      // Close the client
      httpClient.close();
      
      // Check if the response is successful
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Proxy>> getValidatedProxies({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
  }) async {
    try {
      // Try to get cached validated proxies first
      final cachedValidatedProxies = await localDataSource.getCachedValidatedProxies();
      
      // Filter cached validated proxies based on the parameters
      final filteredProxies = cachedValidatedProxies.where((proxy) {
        if (onlyHttps && !proxy.isHttps) return false;
        
        if (countries != null && countries.isNotEmpty && 
            proxy.countryCode != null && 
            !countries.contains(proxy.countryCode)) {
          return false;
        }
        
        return true;
      }).toList();
      
      if (filteredProxies.isNotEmpty) {
        return filteredProxies.take(count).toList();
      }
      
      // If no cached validated proxies, fetch new proxies and validate them
      final proxies = await fetchProxies(
        count: count * 3, // Fetch more to increase chances of finding valid ones
        onlyHttps: onlyHttps,
        countries: countries,
      );
      
      final validatedProxies = <ProxyModel>[];
      
      for (final proxy in proxies) {
        if (validatedProxies.length >= count) break;
        
        final isValid = await validateProxy(proxy);
        
        if (isValid) {
          final proxyModel = proxy is ProxyModel
              ? proxy
              : ProxyModel.fromEntity(proxy);
          
          validatedProxies.add(proxyModel);
        }
      }
      
      // Cache the validated proxies
      await localDataSource.cacheValidatedProxies(validatedProxies);
      
      return validatedProxies;
    } catch (e) {
      throw ProxyFetchException('Failed to get validated proxies: $e');
    }
  }
}
