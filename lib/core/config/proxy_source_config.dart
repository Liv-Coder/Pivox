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

  /// Whether to use hidemy.name
  final bool useHideMyName;

  /// Whether to use proxylist.to
  final bool useProxyListTo;

  /// Additional custom proxy sources
  final List<String> customSources;

  /// Creates a new [ProxySourceConfig] instance
  const ProxySourceConfig({
    this.useFreeProxyList = true,
    this.useGeoNode = true,
    this.useProxyScrape = true,
    this.useProxyNova = true,
    this.useHideMyName = true,
    this.useProxyListTo = true,
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
      useHideMyName: false,
      useProxyListTo: false,
    );
  }

  /// Creates a configuration with only the specified sources enabled
  factory ProxySourceConfig.only({
    bool freeProxyList = false,
    bool geoNode = false,
    bool proxyScrape = false,
    bool proxyNova = false,
    bool hideMyName = false,
    bool proxyListTo = false,
    List<String> custom = const [],
  }) {
    return ProxySourceConfig(
      useFreeProxyList: freeProxyList,
      useGeoNode: geoNode,
      useProxyScrape: proxyScrape,
      useProxyNova: proxyNova,
      useHideMyName: hideMyName,
      useProxyListTo: proxyListTo,
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

    if (useHideMyName) {
      urls.add(AppConstants.proxySourceUrls[4]);
    }

    if (useProxyListTo) {
      urls.add(AppConstants.proxySourceUrls[5]);
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
    bool? useHideMyName,
    bool? useProxyListTo,
    List<String>? customSources,
  }) {
    return ProxySourceConfig(
      useFreeProxyList: useFreeProxyList ?? this.useFreeProxyList,
      useGeoNode: useGeoNode ?? this.useGeoNode,
      useProxyScrape: useProxyScrape ?? this.useProxyScrape,
      useProxyNova: useProxyNova ?? this.useProxyNova,
      useHideMyName: useHideMyName ?? this.useHideMyName,
      useProxyListTo: useProxyListTo ?? this.useProxyListTo,
      customSources: customSources ?? this.customSources,
    );
  }
}
