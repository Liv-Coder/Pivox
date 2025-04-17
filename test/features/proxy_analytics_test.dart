import 'package:flutter_test/flutter_test.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_analytics.dart';

void main() {
  group('ProxyAnalytics', () {
    test('default constructor creates instance with default values', () {
      final analytics = ProxyAnalytics();

      expect(analytics.totalProxiesFetched, 0);
      expect(analytics.totalProxiesValidated, 0);
      expect(analytics.totalSuccessfulValidations, 0);
      expect(analytics.totalFailedValidations, 0);
      expect(analytics.totalRequests, 0);
      expect(analytics.totalSuccessfulRequests, 0);
      expect(analytics.totalFailedRequests, 0);
      expect(analytics.averageResponseTime, 0);
      expect(analytics.averageSuccessRate, 0.0);
      expect(analytics.proxiesByCountry, {});
      expect(analytics.proxiesByAnonymityLevel, {});
      expect(analytics.requestsByProxySource, {});
    });

    test('recordProxyFetch updates values correctly', () {
      final initialAnalytics = ProxyAnalytics();
      final proxies = [
        Proxy(
          ip: '1.1.1.1',
          port: 8080,
          countryCode: 'US',
          anonymityLevel: 'elite',
        ),
        Proxy(
          ip: '2.2.2.2',
          port: 8080,
          countryCode: 'CA',
          anonymityLevel: 'anonymous',
        ),
      ];

      final updatedAnalytics = initialAnalytics.recordProxyFetch(proxies);

      expect(updatedAnalytics.totalProxiesFetched, 2);
      expect(updatedAnalytics.proxiesByCountry, {'US': 1, 'CA': 1});
      expect(updatedAnalytics.proxiesByAnonymityLevel, {
        'elite': 1,
        'anonymous': 1,
      });
    });

    test('recordProxyValidation updates values correctly', () {
      final initialAnalytics = ProxyAnalytics();
      final proxies = [
        Proxy(ip: '1.1.1.1', port: 8080),
        Proxy(ip: '2.2.2.2', port: 8080),
        Proxy(ip: '3.3.3.3', port: 8080),
      ];
      final results = [true, false, true];

      final updatedAnalytics = initialAnalytics.recordProxyValidation(
        proxies,
        results,
      );

      expect(updatedAnalytics.totalProxiesValidated, 3);
      expect(updatedAnalytics.totalSuccessfulValidations, 2);
      expect(updatedAnalytics.totalFailedValidations, 1);
    });

    test('recordRequest updates values correctly', () {
      final initialAnalytics = ProxyAnalytics();
      final proxy = Proxy(ip: '1.1.1.1', port: 8080);

      final updatedAnalytics = initialAnalytics.recordRequest(
        proxy,
        true,
        500,
        'test',
      );

      expect(updatedAnalytics.totalRequests, 1);
      expect(updatedAnalytics.totalSuccessfulRequests, 1);
      expect(updatedAnalytics.totalFailedRequests, 0);
      expect(updatedAnalytics.averageResponseTime, 500);
      expect(updatedAnalytics.averageSuccessRate, 1.0);
      expect(updatedAnalytics.requestsByProxySource, {'test': 1});

      // Record a failed request
      final finalAnalytics = updatedAnalytics.recordRequest(
        proxy,
        false,
        null,
        'test',
      );

      expect(finalAnalytics.totalRequests, 2);
      expect(finalAnalytics.totalSuccessfulRequests, 1);
      expect(finalAnalytics.totalFailedRequests, 1);
      expect(finalAnalytics.averageResponseTime, 500);
      expect(finalAnalytics.averageSuccessRate, 0.5);
      expect(finalAnalytics.requestsByProxySource, {'test': 2});
    });

    test('toJson and fromJson work correctly', () {
      final analytics = ProxyAnalytics(
        totalProxiesFetched: 10,
        totalProxiesValidated: 8,
        totalSuccessfulValidations: 5,
        totalFailedValidations: 3,
        totalRequests: 20,
        totalSuccessfulRequests: 15,
        totalFailedRequests: 5,
        averageResponseTime: 300,
        averageSuccessRate: 0.75,
        proxiesByCountry: {'US': 5, 'CA': 3, 'UK': 2},
        proxiesByAnonymityLevel: {'elite': 4, 'anonymous': 6},
        requestsByProxySource: {'test': 20},
      );

      final json = analytics.toJson();
      final fromJson = ProxyAnalytics.fromJson(json);

      expect(fromJson.totalProxiesFetched, analytics.totalProxiesFetched);
      expect(fromJson.totalProxiesValidated, analytics.totalProxiesValidated);
      expect(
        fromJson.totalSuccessfulValidations,
        analytics.totalSuccessfulValidations,
      );
      expect(fromJson.totalFailedValidations, analytics.totalFailedValidations);
      expect(fromJson.totalRequests, analytics.totalRequests);
      expect(
        fromJson.totalSuccessfulRequests,
        analytics.totalSuccessfulRequests,
      );
      expect(fromJson.totalFailedRequests, analytics.totalFailedRequests);
      expect(fromJson.averageResponseTime, analytics.averageResponseTime);
      expect(fromJson.averageSuccessRate, analytics.averageSuccessRate);
      expect(fromJson.proxiesByCountry, analytics.proxiesByCountry);
      expect(
        fromJson.proxiesByAnonymityLevel,
        analytics.proxiesByAnonymityLevel,
      );
      expect(fromJson.requestsByProxySource, analytics.requestsByProxySource);
    });
  });
}
