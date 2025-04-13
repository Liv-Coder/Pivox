import 'package:flutter_test/flutter_test.dart';
import 'package:pivox/pivox.dart';

void main() {
  group('RoundRobinRotation', () {
    late RoundRobinRotation rotation;

    setUp(() {
      rotation = RoundRobinRotation();
    });

    test('should return null when no proxies are available', () async {
      final proxy = await rotation.getNextProxy();
      expect(proxy, isNull);
    });

    test('should add and retrieve proxies', () async {
      final proxy1 = Proxy(
        host: '192.168.1.1',
        port: 8080,
        type: ProxyType.http,
        lastChecked: DateTime.now(),
        responseTime: 100,
      );

      final proxy2 = Proxy(
        host: '192.168.1.2',
        port: 8080,
        type: ProxyType.http,
        lastChecked: DateTime.now(),
        responseTime: 200,
      );

      await rotation.addProxy(proxy1);
      await rotation.addProxy(proxy2);

      final activeProxies = await rotation.getActiveProxies();
      expect(activeProxies.length, 2);

      final nextProxy1 = await rotation.getNextProxy();
      expect(nextProxy1?.host, '192.168.1.1');

      final nextProxy2 = await rotation.getNextProxy();
      expect(nextProxy2?.host, '192.168.1.2');

      // Should cycle back to the first proxy
      final nextProxy3 = await rotation.getNextProxy();
      expect(nextProxy3?.host, '192.168.1.1');
    });

    test('should mark proxy as inactive', () async {
      final proxy = Proxy(
        host: '192.168.1.1',
        port: 8080,
        type: ProxyType.http,
        lastChecked: DateTime.now(),
        responseTime: 100,
      );

      await rotation.addProxy(proxy);
      await rotation.markProxyAsInactive(proxy);

      final activeProxies = await rotation.getActiveProxies();
      expect(activeProxies.length, 0);

      final nextProxy = await rotation.getNextProxy();
      expect(nextProxy, isNull);
    });

    test('should remove proxy', () async {
      final proxy = Proxy(
        host: '192.168.1.1',
        port: 8080,
        type: ProxyType.http,
        lastChecked: DateTime.now(),
        responseTime: 100,
      );

      await rotation.addProxy(proxy);
      await rotation.removeProxy(proxy);

      final activeProxies = await rotation.getActiveProxies();
      expect(activeProxies.length, 0);

      final nextProxy = await rotation.getNextProxy();
      expect(nextProxy, isNull);
    });
  });
}
