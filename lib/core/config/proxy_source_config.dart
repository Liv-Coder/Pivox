import '../constants/app_constants.dart';

/// Configuration for proxy sources
class ProxySourceConfig {
  /// Whether to use free-proxy-list.net
  final bool useFreeProxyList;
  
  /// Whether to use geonode.com
  final bool useGeoNode;
  
  /// Whether to use proxyscrape.com
  final bool useProxyScrape;
  
  /// Whether to use proxynova.com
  final bool useProxyNova;
  
  /// Additional custom proxy sources
  final List<String> customSources;
  
  /// Creates a new [ProxySourceConfig] instance
  const ProxySourceConfig({
    this.useFreeProxyList = true,
    this.useGeoNode = true,
    this.useProxyScrape = true,
    this.useProxyNova = true,
    this.customSources = const [],
  });
  
  /// Creates a default configuration with all sources enabled
  factory ProxySourceConfig.all() {
    return const ProxySourceConfig();
  }
  
  /// Creates a configuration with no sources enabled
  factory ProxySourceConfig.none() {
    return const ProxySourceConfig(
      useFreeProxyList: false,
      useGeoNode: false,
      useProxyScrape: false,
      useProxyNova: false,
    );
  }
  
  /// Creates a configuration with only the specified sources enabled
  factory ProxySourceConfig.only({
    bool freeProxyList = false,
    bool geoNode = false,
    bool proxyScrape = false,
    bool proxyNova = false,
    List<String> custom = const [],
  }) {
    return ProxySourceConfig(
      useFreeProxyList: freeProxyList,
      useGeoNode: geoNode,
      useProxyScrape: proxyScrape,
      useProxyNova: proxyNova,
      customSources: custom,
    );
  }
  
  /// Gets the list of enabled proxy source URLs
  List<String> getEnabledSourceUrls() {
    final urls = <String>[];
    
    if (useFreeProxyList) {
      urls.add(AppConstants.proxySourceUrls[0]);
    }
    
    if (useGeoNode) {
      urls.add(AppConstants.proxySourceUrls[1]);
    }
    
    if (useProxyScrape) {
      urls.add(AppConstants.proxySourceUrls[2]);
    }
    
    if (useProxyNova) {
      urls.add(AppConstants.proxySourceUrls[3]);
    }
    
    urls.addAll(customSources);
    
    return urls;
  }
  
  /// Creates a copy of this configuration with the specified changes
  ProxySourceConfig copyWith({
    bool? useFreeProxyList,
    bool? useGeoNode,
    bool? useProxyScrape,
    bool? useProxyNova,
    List<String>? customSources,
  }) {
    return ProxySourceConfig(
      useFreeProxyList: useFreeProxyList ?? this.useFreeProxyList,
      useGeoNode: useGeoNode ?? this.useGeoNode,
      useProxyScrape: useProxyScrape ?? this.useProxyScrape,
      useProxyNova: useProxyNova ?? this.useProxyNova,
      customSources: customSources ?? this.customSources,
    );
  }
}
