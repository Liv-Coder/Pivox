import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/proxy_management/data/datasources/proxy_local_datasource.dart';
import '../../features/proxy_management/data/datasources/proxy_remote_datasource.dart';
import '../../features/proxy_management/data/repositories/proxy_repository_impl.dart';
import '../../features/proxy_management/domain/usecases/get_proxies.dart';
import '../../features/proxy_management/domain/usecases/get_validated_proxies.dart';
import '../../features/proxy_management/domain/usecases/validate_proxy.dart';
import '../../features/proxy_management/presentation/managers/proxy_manager.dart';
import '../../features/http_integration/http/http_proxy_client.dart';
import '../../features/http_integration/dio/dio_proxy_interceptor.dart';

/// A builder class for simplifying Pivox initialization
class PivoxBuilder {
  /// HTTP client for making requests
  http.Client? _httpClient;
  
  /// SharedPreferences instance for caching
  SharedPreferences? _sharedPreferences;
  
  /// Maximum number of concurrent validations
  int _maxConcurrentValidations = 10;
  
  /// Whether to use validated proxies by default
  bool _useValidatedProxies = true;
  
  /// Whether to rotate proxies by default
  bool _rotateProxies = true;
  
  /// Maximum number of retries for Dio requests
  int _maxRetries = 3;
  
  /// Sets the HTTP client to use
  /// 
  /// If not provided, a new client will be created
  PivoxBuilder withHttpClient(http.Client httpClient) {
    _httpClient = httpClient;
    return this;
  }
  
  /// Sets the SharedPreferences instance to use
  /// 
  /// If not provided, a new instance will be created
  PivoxBuilder withSharedPreferences(SharedPreferences sharedPreferences) {
    _sharedPreferences = sharedPreferences;
    return this;
  }
  
  /// Sets the maximum number of concurrent validations
  /// 
  /// Default is 10
  PivoxBuilder withMaxConcurrentValidations(int maxConcurrentValidations) {
    _maxConcurrentValidations = maxConcurrentValidations;
    return this;
  }
  
  /// Sets whether to use validated proxies by default
  /// 
  /// Default is true
  PivoxBuilder withUseValidatedProxies(bool useValidatedProxies) {
    _useValidatedProxies = useValidatedProxies;
    return this;
  }
  
  /// Sets whether to rotate proxies by default
  /// 
  /// Default is true
  PivoxBuilder withRotateProxies(bool rotateProxies) {
    _rotateProxies = rotateProxies;
    return this;
  }
  
  /// Sets the maximum number of retries for Dio requests
  /// 
  /// Default is 3
  PivoxBuilder withMaxRetries(int maxRetries) {
    _maxRetries = maxRetries;
    return this;
  }
  
  /// Builds a ProxyManager instance
  /// 
  /// This is the core component needed for proxy management
  Future<ProxyManager> buildProxyManager() async {
    // Initialize HTTP client if not provided
    final httpClient = _httpClient ?? http.Client();
    
    // Initialize SharedPreferences if not provided
    final sharedPreferences = _sharedPreferences ?? await SharedPreferences.getInstance();
    
    // Initialize data sources
    final localDataSource = ProxyLocalDataSourceImpl(
      sharedPreferences: sharedPreferences,
    );
    final remoteDataSource = ProxyRemoteDataSourceImpl(
      client: httpClient,
    );
    
    // Initialize repository
    final repository = ProxyRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      client: httpClient,
      maxConcurrentValidations: _maxConcurrentValidations,
    );
    
    // Initialize use cases
    final getProxies = GetProxies(repository);
    final validateProxy = ValidateProxy(repository);
    final getValidatedProxies = GetValidatedProxies(repository);
    
    // Initialize proxy manager
    return ProxyManager(
      getProxies: getProxies,
      validateProxy: validateProxy,
      getValidatedProxies: getValidatedProxies,
    );
  }
  
  /// Builds an HTTP client with proxy support
  /// 
  /// This is a convenience method for creating an HTTP client
  Future<ProxyHttpClient> buildHttpClient() async {
    final proxyManager = await buildProxyManager();
    
    return ProxyHttpClient(
      proxyManager: proxyManager,
      useValidatedProxies: _useValidatedProxies,
      rotateProxies: _rotateProxies,
    );
  }
  
  /// Creates a Dio interceptor for proxy support
  /// 
  /// This can be added to an existing Dio instance
  Future<ProxyInterceptor> buildDioInterceptor() async {
    final proxyManager = await buildProxyManager();
    
    return ProxyInterceptor(
      proxyManager: proxyManager,
      useValidatedProxies: _useValidatedProxies,
      rotateProxies: _rotateProxies,
      maxRetries: _maxRetries,
    );
  }
}

/// Factory methods for quick initialization
class Pivox {
  /// Creates a new PivoxBuilder instance
  static PivoxBuilder builder() {
    return PivoxBuilder();
  }
  
  /// Creates a ProxyManager with default settings
  static Future<ProxyManager> createProxyManager() async {
    return PivoxBuilder().buildProxyManager();
  }
  
  /// Creates an HTTP client with proxy support using default settings
  static Future<ProxyHttpClient> createHttpClient() async {
    return PivoxBuilder().buildHttpClient();
  }
  
  /// Creates a Dio interceptor for proxy support using default settings
  static Future<ProxyInterceptor> createDioInterceptor() async {
    return PivoxBuilder().buildDioInterceptor();
  }
}
