import 'package:flutter_test/flutter_test.dart';
import 'package:pivox/features/proxy_management/data/models/proxy_model.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_score.dart';
import 'package:pivox/features/proxy_management/domain/strategies/proxy_rotation_strategy.dart';

void main() {
  group('ProxyRotationStrategy', () {
    final proxies = [
      Proxy(ip: '1.1.1.1', port: 8080),
      Proxy(ip: '2.2.2.2', port: 8080),
      Proxy(ip: '3.3.3.3', port: 8080),
    ];

    final proxyModels = [
      ProxyModel(
        ip: '1.1.1.1',
        port: 8080,
        score: ProxyScore(
          successRate: 0.8,
          averageResponseTime: 100,
          successfulRequests: 8,
          failedRequests: 2,
          lastUsed: DateTime.now().millisecondsSinceEpoch - 60000,
        ),
      ),
      ProxyModel(
        ip: '2.2.2.2',
        port: 8080,
        score: ProxyScore(
          successRate: 0.5,
          averageResponseTime: 200,
          successfulRequests: 5,
          failedRequests: 5,
          lastUsed: DateTime.now().millisecondsSinceEpoch - 30000,
        ),
      ),
      ProxyModel(
        ip: '3.3.3.3',
        port: 8080,
        score: ProxyScore(
          successRate: 0.2,
          averageResponseTime: 300,
          successfulRequests: 2,
          failedRequests: 8,
          lastUsed: DateTime.now().millisecondsSinceEpoch - 10000,
        ),
      ),
    ];

    test('RoundRobinStrategy selects proxies in sequence', () {
      final strategy = RoundRobinStrategy();

      final proxy1 = strategy.selectProxy(proxies);
      final proxy2 = strategy.selectProxy(proxies);
      final proxy3 = strategy.selectProxy(proxies);
      final proxy4 = strategy.selectProxy(proxies);

      expect(proxy1.ip, '1.1.1.1');
      expect(proxy2.ip, '2.2.2.2');
      expect(proxy3.ip, '3.3.3.3');
      expect(proxy4.ip, '1.1.1.1'); // Wraps around
    });

    test('RandomStrategy selects a proxy from the list', () {
      final strategy = RandomStrategy();

      final proxy = strategy.selectProxy(proxies);

      expect(proxies.map((p) => p.ip).contains(proxy.ip), true);
    });

    test('WeightedStrategy selects proxies from the list', () {
      final strategy = WeightedStrategy();

      final proxy = strategy.selectProxy(proxyModels);

      // Just check that it returns a proxy from the list
      expect(proxyModels.map((p) => p.ip).contains(proxy.ip), true);
    });

    test('LeastRecentlyUsedStrategy selects the least recently used proxy', () {
      final strategy = LeastRecentlyUsedStrategy();

      final proxy = strategy.selectProxy(proxyModels);

      // The proxy with the oldest lastUsed timestamp should be selected
      expect(proxy.ip, '1.1.1.1');
    });

    test('ProxyRotationStrategyFactory creates the correct strategy', () {
      final roundRobin = ProxyRotationStrategyFactory.create(
        RotationStrategyType.roundRobin,
      );
      final random = ProxyRotationStrategyFactory.create(
        RotationStrategyType.random,
      );
      final weighted = ProxyRotationStrategyFactory.create(
        RotationStrategyType.weighted,
      );
      final lru = ProxyRotationStrategyFactory.create(
        RotationStrategyType.leastRecentlyUsed,
      );

      expect(roundRobin, isA<RoundRobinStrategy>());
      expect(random, isA<RandomStrategy>());
      expect(weighted, isA<WeightedStrategy>());
      expect(lru, isA<LeastRecentlyUsedStrategy>());
    });
  });
}
