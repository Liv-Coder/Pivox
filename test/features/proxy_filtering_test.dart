import 'package:flutter_test/flutter_test.dart';
import 'package:pivox/features/proxy_management/domain/repositories/proxy_repository.dart';

void main() {
  group('ProxyFilterOptions', () {
    test('default constructor creates instance with default values', () {
      final options = ProxyFilterOptions();
      
      expect(options.count, 20);
      expect(options.onlyHttps, false);
      expect(options.countries, null);
      expect(options.regions, null);
      expect(options.isps, null);
      expect(options.minSpeed, null);
      expect(options.requireWebsockets, null);
      expect(options.requireSocks, null);
      expect(options.socksVersion, null);
      expect(options.requireAuthentication, null);
      expect(options.requireAnonymous, null);
    });
    
    test('constructor with parameters sets values correctly', () {
      final options = ProxyFilterOptions(
        count: 10,
        onlyHttps: true,
        countries: ['US', 'CA'],
        regions: ['California'],
        isps: ['Comcast'],
        minSpeed: 10.0,
        requireWebsockets: true,
        requireSocks: true,
        socksVersion: 5,
        requireAuthentication: true,
        requireAnonymous: true,
      );
      
      expect(options.count, 10);
      expect(options.onlyHttps, true);
      expect(options.countries, ['US', 'CA']);
      expect(options.regions, ['California']);
      expect(options.isps, ['Comcast']);
      expect(options.minSpeed, 10.0);
      expect(options.requireWebsockets, true);
      expect(options.requireSocks, true);
      expect(options.socksVersion, 5);
      expect(options.requireAuthentication, true);
      expect(options.requireAnonymous, true);
    });
  });
}
