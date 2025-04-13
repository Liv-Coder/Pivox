import 'package:flutter_test/flutter_test.dart';
import 'package:pivox/core/config/proxy_source_config.dart';
import 'package:pivox/core/constants/app_constants.dart';

void main() {
  group('ProxySourceConfig', () {
    test('default constructor enables all sources', () {
      final config = ProxySourceConfig();
      
      expect(config.useFreeProxyList, true);
      expect(config.useGeoNode, true);
      expect(config.useProxyScrape, true);
      expect(config.useProxyNova, true);
      expect(config.customSources, []);
    });
    
    test('all() factory enables all sources', () {
      final config = ProxySourceConfig.all();
      
      expect(config.useFreeProxyList, true);
      expect(config.useGeoNode, true);
      expect(config.useProxyScrape, true);
      expect(config.useProxyNova, true);
      expect(config.customSources, []);
    });
    
    test('none() factory disables all sources', () {
      final config = ProxySourceConfig.none();
      
      expect(config.useFreeProxyList, false);
      expect(config.useGeoNode, false);
      expect(config.useProxyScrape, false);
      expect(config.useProxyNova, false);
      expect(config.customSources, []);
    });
    
    test('only() factory enables specified sources', () {
      final config = ProxySourceConfig.only(
        freeProxyList: true,
        geoNode: false,
        proxyScrape: true,
        proxyNova: false,
        custom: ['https://custom-proxy-source.com'],
      );
      
      expect(config.useFreeProxyList, true);
      expect(config.useGeoNode, false);
      expect(config.useProxyScrape, true);
      expect(config.useProxyNova, false);
      expect(config.customSources, ['https://custom-proxy-source.com']);
    });
    
    test('getEnabledSourceUrls returns correct URLs', () {
      final config = ProxySourceConfig.only(
        freeProxyList: true,
        geoNode: false,
        proxyScrape: true,
        proxyNova: false,
        custom: ['https://custom-proxy-source.com'],
      );
      
      final urls = config.getEnabledSourceUrls();
      
      expect(urls.length, 3);
      expect(urls.contains(AppConstants.proxySourceUrls[0]), true);
      expect(urls.contains(AppConstants.proxySourceUrls[1]), false);
      expect(urls.contains(AppConstants.proxySourceUrls[2]), true);
      expect(urls.contains(AppConstants.proxySourceUrls[3]), false);
      expect(urls.contains('https://custom-proxy-source.com'), true);
    });
    
    test('copyWith creates new instance with updated values', () {
      final config = ProxySourceConfig();
      final updatedConfig = config.copyWith(
        useFreeProxyList: false,
        useGeoNode: false,
        customSources: ['https://custom-proxy-source.com'],
      );
      
      expect(updatedConfig.useFreeProxyList, false);
      expect(updatedConfig.useGeoNode, false);
      expect(updatedConfig.useProxyScrape, true);
      expect(updatedConfig.useProxyNova, true);
      expect(updatedConfig.customSources, ['https://custom-proxy-source.com']);
    });
  });
}
