import 'dart:math';

import '../../domain/entities/proxy.dart';
import '../../domain/entities/proxy_score.dart';
import '../../domain/usecases/get_proxies.dart';
import '../../domain/usecases/get_validated_proxies.dart';
import '../../domain/usecases/validate_proxy.dart';
import '../../../../core/errors/exceptions.dart';
import '../../data/models/proxy_model.dart';

/// Manager for proxy operations
class ProxyManager {
  /// Use case for getting proxies
  final GetProxies getProxies;

  /// Use case for validating proxies
  final ValidateProxy validateProxy;

  /// Use case for getting validated proxies
  final GetValidatedProxies getValidatedProxies;

  /// List of currently available proxies
  List<Proxy> _proxies = [];

  /// List of currently validated proxies
  List<Proxy> _validatedProxies = [];

  /// Current proxy index for rotation
  int _currentProxyIndex = 0;

  /// Random number generator for random proxy selection
  final Random _random = Random();

  /// Creates a new [ProxyManager] with the given use cases
  ProxyManager({
    required this.getProxies,
    required this.validateProxy,
    required this.getValidatedProxies,
  });

  /// Fetches proxies from various sources
  ///
  /// [count] is the number of proxies to fetch
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  Future<List<Proxy>> fetchProxies({
    int count = 20,
    bool onlyHttps = false,
    List<String>? countries,
  }) async {
    _proxies = await getProxies(
      count: count,
      onlyHttps: onlyHttps,
      countries: countries,
    );

    return _proxies;
  }

  /// Gets a list of validated proxies
  ///
  /// [count] is the number of proxies to return
  /// [onlyHttps] filters to only return HTTPS proxies
  /// [countries] filters to only return proxies from specific countries
  /// [onProgress] is a callback for progress updates during validation
  Future<List<Proxy>> fetchValidatedProxies({
    int count = 10,
    bool onlyHttps = false,
    List<String>? countries,
    void Function(int completed, int total)? onProgress,
  }) async {
    _validatedProxies = await getValidatedProxies(
      count: count,
      onlyHttps: onlyHttps,
      countries: countries,
      onProgress: onProgress,
    );

    return _validatedProxies;
  }

  /// Gets the next proxy in the rotation
  ///
  /// [validated] determines whether to use validated proxies
  /// [useScoring] determines whether to use the scoring system for selection
  Proxy getNextProxy({bool validated = true, bool useScoring = false}) {
    final proxies = validated ? _validatedProxies : _proxies;

    if (proxies.isEmpty) {
      throw NoValidProxiesException();
    }

    if (useScoring) {
      return _getProxyByScore(proxies);
    } else {
      _currentProxyIndex = (_currentProxyIndex + 1) % proxies.length;
      return proxies[_currentProxyIndex];
    }
  }

  /// Gets a random proxy
  ///
  /// [validated] determines whether to use validated proxies
  /// [useScoring] determines whether to use the scoring system for weighted selection
  Proxy getRandomProxy({bool validated = true, bool useScoring = false}) {
    final proxies = validated ? _validatedProxies : _proxies;

    if (proxies.isEmpty) {
      throw NoValidProxiesException();
    }

    if (useScoring) {
      return _getProxyByScore(proxies, randomize: true);
    } else {
      return proxies[_random.nextInt(proxies.length)];
    }
  }

  /// Gets a proxy based on its score
  ///
  /// [proxies] is the list of proxies to choose from
  /// [randomize] determines whether to add randomness to the selection
  Proxy _getProxyByScore(List<Proxy> proxies, {bool randomize = false}) {
    // If there's only one proxy, return it
    if (proxies.length == 1) {
      return proxies.first;
    }

    // Calculate scores for all proxies
    final scores = <double>[];
    var totalScore = 0.0;

    for (final proxy in proxies) {
      double score;

      if (proxy is ProxyModel && proxy.score != null) {
        score = proxy.score!.calculateScore();

        // Add a small random factor if requested
        if (randomize) {
          score = (score * 0.8) + (_random.nextDouble() * 0.2);
        }
      } else {
        // Default score for proxies without a score
        score = randomize ? _random.nextDouble() * 0.5 : 0.5;
      }

      scores.add(score);
      totalScore += score;
    }

    // If all scores are 0, use random selection
    if (totalScore <= 0) {
      return proxies[_random.nextInt(proxies.length)];
    }

    // Normalize scores to create a probability distribution
    for (var i = 0; i < scores.length; i++) {
      scores[i] = scores[i] / totalScore;
    }

    // Select a proxy based on the probability distribution
    final randomValue = _random.nextDouble();
    var cumulativeProbability = 0.0;

    for (var i = 0; i < proxies.length; i++) {
      cumulativeProbability += scores[i];

      if (randomValue <= cumulativeProbability) {
        return proxies[i];
      }
    }

    // Fallback to the last proxy (should rarely happen)
    return proxies.last;
  }

  /// Validates a specific proxy
  ///
  /// [proxy] is the proxy to validate
  /// [testUrl] is the URL to use for testing
  /// [timeout] is the timeout in milliseconds
  /// [updateScore] determines whether to update the proxy's score
  Future<bool> validateSpecificProxy(
    Proxy proxy, {
    String? testUrl,
    int timeout = 10000,
    bool updateScore = true,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final isValid = await validateProxy(
      proxy,
      testUrl: testUrl,
      timeout: timeout,
    );
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final responseTime = endTime - startTime;

    // Update the proxy's score if requested and it's a ProxyModel
    if (updateScore && proxy is ProxyModel) {
      final updatedProxy =
          isValid
              ? proxy.withSuccessfulRequest(responseTime)
              : proxy.withFailedRequest();

      // Update the proxy in the lists
      _updateProxyInLists(proxy, updatedProxy);
    }

    return isValid;
  }

  /// Updates a proxy in the internal lists
  void _updateProxyInLists(Proxy oldProxy, Proxy newProxy) {
    // Update in the proxies list
    final proxyIndex = _proxies.indexWhere(
      (p) => p.ip == oldProxy.ip && p.port == oldProxy.port,
    );

    if (proxyIndex >= 0) {
      _proxies[proxyIndex] = newProxy;
    }

    // Update in the validated proxies list
    final validatedProxyIndex = _validatedProxies.indexWhere(
      (p) => p.ip == oldProxy.ip && p.port == oldProxy.port,
    );

    if (validatedProxyIndex >= 0) {
      _validatedProxies[validatedProxyIndex] = newProxy;
    }
  }

  /// Gets the current list of proxies
  List<Proxy> get proxies => List.unmodifiable(_proxies);

  /// Gets the current list of validated proxies
  List<Proxy> get validatedProxies => List.unmodifiable(_validatedProxies);
}
