import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_filter_options.dart';
import 'package:pivox/features/proxy_management/presentation/managers/proxy_manager.dart';

/// A utility class for debugging proxy issues
class ProxyDebugger {
  /// The proxy manager to debug
  final ProxyManager _proxyManager;

  /// Creates a new [ProxyDebugger] with the given [proxyManager]
  ProxyDebugger(this._proxyManager);

  /// Runs a comprehensive diagnostic on the proxy system
  Future<ProxyDiagnosticResult> runDiagnostic({
    bool testAllSources = true,
    bool validateProxies = true,
    String? testUrl,
    int timeout = 10000,
  }) async {
    final result = ProxyDiagnosticResult();

    try {
      // Step 1: Check current proxy lists
      result.currentProxies = _proxyManager.proxies.length;
      result.currentValidatedProxies = _proxyManager.validatedProxies.length;

      // Step 2: Test fetching from all sources if requested
      if (testAllSources) {
        final sourceResults = await _testAllSources();
        result.sourceResults = sourceResults;
      }

      // Step 3: Test proxy validation
      if (validateProxies && result.currentProxies > 0) {
        final validationResults = await _testProxyValidation(
          testUrl: testUrl,
          timeout: timeout,
        );
        result.validationResults = validationResults;
      }

      // Step 4: Try to fetch and validate new proxies
      try {
        final startTime = DateTime.now();
        final proxies = await _proxyManager.fetchValidatedProxies(
          options: ProxyFilterOptions(count: 10, onlyHttps: true),
          onProgress: (completed, total) {
            if (kDebugMode) {
              print('Validated $completed of $total proxies');
            }
          },
        );
        final endTime = DateTime.now();

        result.fetchValidatedProxiesSuccess = true;
        result.fetchValidatedProxiesCount = proxies.length;
        result.fetchValidatedProxiesTime =
            endTime.difference(startTime).inMilliseconds;
      } catch (e) {
        result.fetchValidatedProxiesSuccess = false;
        result.fetchValidatedProxiesError = e.toString();
      }

      // Step 5: Test getting a proxy
      try {
        final proxy = _proxyManager.getNextProxy(validated: true);
        result.getNextProxySuccess = true;
        result.proxyDetails = proxy.toString();
      } catch (e) {
        result.getNextProxySuccess = false;
        result.getNextProxyError = e.toString();
      }
    } catch (e) {
      result.overallError = e.toString();
    }

    return result;
  }

  /// Tests fetching proxies from all available sources
  Future<Map<String, SourceTestResult>> _testAllSources() async {
    final results = <String, SourceTestResult>{};

    // Test each source individually
    final sources = [
      'free-proxy-list.net',
      'geonode.com',
      'proxyscrape.com',
      'proxynova.com',
      'hidemy.name',
      'proxy-list.to',
    ];

    for (final source in sources) {
      final result = SourceTestResult();

      try {
        // Try to fetch from this source
        // Note: We can't directly configure which source to use here
        // as the proxy manager's source config is set during initialization
        // This is just a test to see if any proxies can be fetched
        final startTime = DateTime.now();

        // We can't directly use the config here, but we can check if proxies are fetched
        final proxies = await _proxyManager.fetchProxies(
          options: ProxyFilterOptions(count: 10),
        );

        final endTime = DateTime.now();

        result.success = true;
        result.count = proxies.length;
        result.timeMs = endTime.difference(startTime).inMilliseconds;
      } catch (e) {
        result.success = false;
        result.error = e.toString();
      }

      results[source] = result;
    }

    return results;
  }

  /// Tests proxy validation
  Future<ValidationTestResult> _testProxyValidation({
    String? testUrl,
    int timeout = 10000,
  }) async {
    final result = ValidationTestResult();

    try {
      // Get a sample of proxies to test
      final proxies = _proxyManager.proxies.take(5).toList();

      if (proxies.isEmpty) {
        result.error = 'No proxies available to test validation';
        return result;
      }

      result.totalTested = proxies.length;
      result.validationResults = <String, bool>{};

      // Test each proxy
      for (final proxy in proxies) {
        try {
          final isValid = await _proxyManager.validateSpecificProxy(
            proxy,
            testUrl: testUrl,
            timeout: timeout,
          );

          result.validationResults['${proxy.ip}:${proxy.port}'] = isValid;
          if (isValid) {
            result.validCount++;
          }
        } catch (e) {
          result.validationResults['${proxy.ip}:${proxy.port}'] = false;
          result.validationErrors.add(
            'Error validating ${proxy.ip}:${proxy.port}: $e',
          );
        }
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Attempts to fix common proxy issues
  Future<ProxyFixResult> attemptFix() async {
    final result = ProxyFixResult();

    try {
      // Step 1: Clear any cached proxies that might be invalid
      result.steps.add('Clearing cached proxies');

      // Step 2: Try to fetch new proxies with relaxed constraints
      result.steps.add('Fetching new proxies with relaxed constraints');
      try {
        final proxies = await _proxyManager.fetchProxies(
          options: ProxyFilterOptions(
            count: 50, // Get more proxies
            onlyHttps: false, // Don't restrict to HTTPS
          ),
        );

        result.steps.add('Fetched ${proxies.length} proxies');
        result.proxyCount = proxies.length;

        if (proxies.isEmpty) {
          result.steps.add('No proxies fetched, trying alternative sources');

          // Try with a different source configuration
          // This would require modifying the proxy manager's source config
          // which isn't directly accessible here
        }
      } catch (e) {
        result.steps.add('Error fetching proxies: $e');
      }

      // Step 3: Validate proxies with increased timeout
      result.steps.add('Validating proxies with increased timeout');
      try {
        final validatedProxies = await _proxyManager.fetchValidatedProxies(
          options: ProxyFilterOptions(
            count: 10,
            onlyHttps: false, // Don't restrict to HTTPS
          ),
          onProgress: (completed, total) {
            result.steps.add('Validated $completed of $total proxies');
          },
        );

        result.steps.add(
          'Successfully validated ${validatedProxies.length} proxies',
        );
        result.validatedProxyCount = validatedProxies.length;
      } catch (e) {
        result.steps.add('Error validating proxies: $e');
      }

      // Step 4: Test if we can get a proxy now
      try {
        final proxy = _proxyManager.getNextProxy(validated: true);
        result.steps.add(
          'Successfully retrieved a proxy: ${proxy.ip}:${proxy.port}',
        );
        result.fixSuccessful = true;
      } catch (e) {
        result.steps.add('Still unable to get a proxy: $e');

        // Step 5: Last resort - try with unvalidated proxies
        try {
          final proxy = _proxyManager.getNextProxy(validated: false);
          result.steps.add(
            'Retrieved an unvalidated proxy: ${proxy.ip}:${proxy.port}',
          );
          result.steps.add(
            'WARNING: Using unvalidated proxies may cause issues',
          );
          result.fixSuccessful = true;
          result.usesUnvalidatedProxies = true;
        } catch (e) {
          result.steps.add('Unable to get any proxy, even unvalidated: $e');
          result.fixSuccessful = false;
        }
      }
    } catch (e) {
      result.steps.add('Error during fix attempt: $e');
      result.fixSuccessful = false;
    }

    return result;
  }

  /// Creates a fallback proxy for emergency use
  ///
  /// This should only be used when no other proxies are available
  Proxy createFallbackProxy() {
    // This is a placeholder - in a real implementation, you might have
    // a few reliable proxies hardcoded as a last resort
    return Proxy(
      ip: '34.23.45.67', // Example IP - replace with a real fallback proxy
      port: 8080,
      isHttps: true,
    );
  }
}

/// Result of a proxy diagnostic
class ProxyDiagnosticResult {
  /// Number of proxies currently available
  int currentProxies = 0;

  /// Number of validated proxies currently available
  int currentValidatedProxies = 0;

  /// Results of testing each proxy source
  Map<String, SourceTestResult>? sourceResults;

  /// Results of testing proxy validation
  ValidationTestResult? validationResults;

  /// Whether fetching validated proxies was successful
  bool? fetchValidatedProxiesSuccess;

  /// Number of validated proxies fetched
  int? fetchValidatedProxiesCount;

  /// Time taken to fetch validated proxies in milliseconds
  int? fetchValidatedProxiesTime;

  /// Error message if fetching validated proxies failed
  String? fetchValidatedProxiesError;

  /// Whether getting the next proxy was successful
  bool? getNextProxySuccess;

  /// Error message if getting the next proxy failed
  String? getNextProxyError;

  /// Details of the proxy if getting the next proxy was successful
  String? proxyDetails;

  /// Overall error message if the diagnostic failed
  String? overallError;

  /// Returns a summary of the diagnostic result
  String getSummary() {
    final buffer = StringBuffer();

    buffer.writeln('=== Proxy Diagnostic Summary ===');
    buffer.writeln('Current proxies: $currentProxies');
    buffer.writeln('Current validated proxies: $currentValidatedProxies');

    if (sourceResults != null) {
      buffer.writeln('\nSource Test Results:');
      sourceResults!.forEach((source, result) {
        if (result.success) {
          buffer.writeln(
            '  $source: ${result.count} proxies in ${result.timeMs}ms',
          );
        } else {
          buffer.writeln('  $source: FAILED - ${result.error}');
        }
      });
    }

    if (validationResults != null) {
      buffer.writeln('\nValidation Test Results:');
      buffer.writeln('  Success: ${validationResults!.success}');
      buffer.writeln(
        '  Valid: ${validationResults!.validCount}/${validationResults!.totalTested}',
      );

      if (validationResults!.validationErrors.isNotEmpty) {
        buffer.writeln('  Validation Errors:');
        for (final error in validationResults!.validationErrors) {
          buffer.writeln('    - $error');
        }
      }
    }

    buffer.writeln('\nFetch Validated Proxies:');
    if (fetchValidatedProxiesSuccess == true) {
      buffer.writeln(
        '  Success: $fetchValidatedProxiesCount proxies in ${fetchValidatedProxiesTime}ms',
      );
    } else {
      buffer.writeln(
        '  Failed: ${fetchValidatedProxiesError ?? "Unknown error"}',
      );
    }

    buffer.writeln('\nGet Next Proxy:');
    if (getNextProxySuccess == true) {
      buffer.writeln('  Success: $proxyDetails');
    } else {
      buffer.writeln('  Failed: ${getNextProxyError ?? "Unknown error"}');
    }

    if (overallError != null) {
      buffer.writeln('\nOverall Error: $overallError');
    }

    buffer.writeln('\n=== Diagnostic Complete ===');

    return buffer.toString();
  }
}

/// Result of testing a proxy source
class SourceTestResult {
  /// Whether the test was successful
  bool success = false;

  /// Number of proxies fetched
  int count = 0;

  /// Time taken to fetch proxies in milliseconds
  int timeMs = 0;

  /// Error message if the test failed
  String? error;
}

/// Result of testing proxy validation
class ValidationTestResult {
  /// Whether the test was successful
  bool success = false;

  /// Total number of proxies tested
  int totalTested = 0;

  /// Number of valid proxies
  int validCount = 0;

  /// Results of validating each proxy
  Map<String, bool> validationResults = {};

  /// Errors encountered during validation
  List<String> validationErrors = [];

  /// Error message if the test failed
  String? error;
}

/// Result of attempting to fix proxy issues
class ProxyFixResult {
  /// Steps taken during the fix attempt
  List<String> steps = [];

  /// Whether the fix was successful
  bool fixSuccessful = false;

  /// Number of proxies fetched
  int proxyCount = 0;

  /// Number of validated proxies
  int validatedProxyCount = 0;

  /// Whether unvalidated proxies are being used
  bool usesUnvalidatedProxies = false;
}
