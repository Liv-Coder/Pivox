import 'package:pivox/features/proxy_management/domain/entities/proxy.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_filter_options.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_protocol.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_validation_options.dart';
import 'package:pivox/features/proxy_management/domain/repositories/proxy_repository.dart';

/// A mock implementation of [ProxyRepository] for testing
class MockProxyRepository implements ProxyRepository {
  final List<Proxy> _proxies = [
    Proxy(
      ip: '192.168.1.1',
      port: 8080,
      protocol: ProxyProtocol.http,
      country: 'US',
      anonymityLevel: 'elite',
      speed: 100,
    ),
    Proxy(
      ip: '192.168.1.2',
      port: 8080,
      protocol: ProxyProtocol.http,
      country: 'UK',
      anonymityLevel: 'anonymous',
      speed: 90,
    ),
    Proxy(
      ip: '192.168.1.3',
      port: 8080,
      protocol: ProxyProtocol.https,
      country: 'CA',
      anonymityLevel: 'transparent',
      speed: 80,
    ),
  ];

  @override
  Future<List<Proxy>> fetchProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(),
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _proxies
        .where((proxy) {
          if (options.onlyHttps && proxy.protocol != ProxyProtocol.https) {
            return false;
          }
          if (options.countryCode != null &&
              proxy.countryCode != options.countryCode) {
            return false;
          }
          if (options.countries != null &&
              options.countries!.isNotEmpty &&
              !options.countries!.contains(proxy.country)) {
            return false;
          }
          if (options.anonymityLevel != null &&
              proxy.anonymityLevel != options.anonymityLevel) {
            return false;
          }
          if (options.minSpeed != null &&
              proxy.speed != null &&
              proxy.speed! < options.minSpeed!) {
            return false;
          }
          return true;
        })
        .take(options.count)
        .toList();
  }

  @override
  Future<List<Proxy>> fetchProxiesLegacy({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  }) {
    return fetchProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
    );
  }

  @override
  Future<bool> validateProxy(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate validation success for most proxies
    return proxy.speed != null && proxy.speed! > 50;
  }

  @override
  Future<bool> validateProxyWithOptions(
    Proxy proxy, {
    ProxyValidationOptions options = const ProxyValidationOptions(),
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate validation success for most proxies
    return proxy.speed != null && proxy.speed! > 50;
  }

  @override
  Future<List<bool>> validateProxies(
    List<Proxy> proxies, {
    ProxyValidationOptions options = const ProxyValidationOptions(),
    void Function(int completed, int total)? onProgress,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final results = <bool>[];

    for (int i = 0; i < proxies.length; i++) {
      final result = await validateProxyWithOptions(
        proxies[i],
        options: options,
      );
      results.add(result);

      if (onProgress != null) {
        onProgress(i + 1, proxies.length);
      }
    }

    return results;
  }

  @override
  Future<List<Proxy>> getValidatedProxies({
    ProxyFilterOptions options = const ProxyFilterOptions(count: 10),
    void Function(int completed, int total)? onProgress,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final proxies = await fetchProxies(options: options);
    final validationResults = await validateProxies(
      proxies,
      onProgress: onProgress,
    );

    final validatedProxies = <Proxy>[];
    for (int i = 0; i < proxies.length; i++) {
      if (validationResults[i]) {
        validatedProxies.add(proxies[i]);
      }
    }

    return validatedProxies;
  }

  @override
  Future<List<Proxy>> getValidatedProxiesLegacy({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) {
    return getValidatedProxies(
      options: ProxyFilterOptions(
        count: count,
        onlyHttps: onlyHttps,
        countries: countries,
      ),
      onProgress: onProgress,
    );
  }
}
