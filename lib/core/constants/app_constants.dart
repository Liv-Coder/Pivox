/// Constants used throughout the application
class AppConstants {
  /// URLs of free proxy list providers
  static const List<String> proxySourceUrls = [
    'https://free-proxy-list.net/',
    'https://geonode.com/free-proxy-list',
    'https://proxyscrape.com/free-proxy-list',
    'https://www.proxynova.com/proxy-server-list/',
  ];
  
  /// Default timeout for proxy validation in milliseconds
  static const int defaultProxyValidationTimeout = 10000;
  
  /// Default number of proxies to fetch
  static const int defaultProxyCount = 20;
  
  /// Default user agent for HTTP requests
  static const String defaultUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
}
