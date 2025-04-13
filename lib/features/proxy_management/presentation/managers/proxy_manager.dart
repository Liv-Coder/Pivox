import 'dart:math';

import '../../domain/entities/proxy.dart';
import '../../domain/usecases/get_proxies.dart';
import '../../domain/usecases/get_validated_proxies.dart';
import '../../domain/usecases/validate_proxy.dart';
import '../../../../core/errors/exceptions.dart';

/// Manager for proxy operations
class ProxyManager {
  /// Use case for getting proxies
  final GetProxies getProxies;
  
  /// Use case for validating proxies
  final ValidateProxy validateProxy;
  
  /// Use case for getting validated proxies
  final GetValidatedProxies getValidatedProxies;
  
  /// List of currently available proxies
  List<Proxy> _proxies = [];
  
  /// List of currently validated proxies
  List<Proxy> _validatedProxies = [];
  
  /// Current proxy index for rotation
  int _currentProxyIndex = 0;
  
  /// Random number generator for random proxy selection
  final Random _random = Random();

  /// Creates a new [ProxyManager] with the given use cases
  ProxyManager({
    required this.getProxies,
    required this.validateProxy,
    required this.getValidatedProxies,
  });

  /// Fetches proxies from various sources
  /// 
  /// [count] is the number of proxies to fetch
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  Future<List<Proxy>> fetchProxies({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  }) async {
    _proxies = await getProxies(
      count: count,
      onlyHttps: onlyHttps,
      countries: countries,
    );
    
    return _proxies;
  }
  
  /// Gets a list of validated proxies
  /// 
  /// [count] is the number of proxies to return
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  Future<List<Proxy>> fetchValidatedProxies({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
  }) async {
    _validatedProxies = await getValidatedProxies(
      count: count,
      onlyHttps: onlyHttps,
      countries: countries,
    );
    
    return _validatedProxies;
  }
  
  /// Gets the next proxy in the rotation
  /// 
  /// [validated] determines whether to use validated proxies
  Proxy getNextProxy({bool validated = true}) {
    final proxies = validated ? _validatedProxies : _proxies;
    
    if (proxies.isEmpty) {
      throw NoValidProxiesException();
    }
    
    _currentProxyIndex = (_currentProxyIndex + 1) % proxies.length;
    return proxies[_currentProxyIndex];
  }
  
  /// Gets a random proxy
  /// 
  /// [validated] determines whether to use validated proxies
  Proxy getRandomProxy({bool validated = true}) {
    final proxies = validated ? _validatedProxies : _proxies;
    
    if (proxies.isEmpty) {
      throw NoValidProxiesException();
    }
    
    return proxies[_random.nextInt(proxies.length)];
  }
  
  /// Validates a specific proxy
  /// 
  /// [proxy] is the proxy to validate
  /// [testUrl] is the URL to use for testing
  /// [timeout] is the timeout in milliseconds
  Future<bool> validateSpecificProxy(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
  }) {
    return validateProxy(
      proxy,
      testUrl: testUrl,
      timeout: timeout,
    );
  }
  
  /// Gets the current list of proxies
  List<Proxy> get proxies => List.unmodifiable(_proxies);
  
  /// Gets the current list of validated proxies
  List<Proxy> get validatedProxies => List.unmodifiable(_validatedProxies);
}
