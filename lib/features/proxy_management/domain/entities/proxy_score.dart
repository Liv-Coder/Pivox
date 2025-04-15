/// Represents a score for a proxy server
class ProxyScore {
  /// The success rate of the proxy (0.0 to 1.0)
  final double successRate;

  /// The average response time in milliseconds
  final int averageResponseTime;

  /// The number of successful requests
  final int successfulRequests;

  /// The number of failed requests
  final int failedRequests;

  /// The last time the proxy was used (in milliseconds since epoch)
  final int lastUsed;

  /// The uptime percentage of the proxy (0.0 to 1.0)
  final double uptime;

  /// The stability score of the proxy (0.0 to 1.0)
  /// Measures how consistent the response times are
  final double stability;

  /// The age of the proxy in hours
  final int ageHours;

  /// The geographical distance score (0.0 to 1.0)
  /// Lower distance is better
  final double geoDistanceScore;

  /// The number of consecutive successful requests
  final int consecutiveSuccesses;

  /// The number of consecutive failed requests
  final int consecutiveFailures;

  /// Creates a new [ProxyScore] instance
  const ProxyScore({
    required this.successRate,
    required this.averageResponseTime,
    required this.successfulRequests,
    required this.failedRequests,
    required this.lastUsed,
    this.uptime = 1.0,
    this.stability = 1.0,
    this.ageHours = 0,
    this.geoDistanceScore = 0.5,
    this.consecutiveSuccesses = 0,
    this.consecutiveFailures = 0,
  });

  /// Gets the composite score based on multiple factors
  double get compositeScore => calculateScore();

  /// Creates a new [ProxyScore] with default values
  factory ProxyScore.initial() {
    return ProxyScore(
      successRate: 0.0,
      averageResponseTime: 0,
      successfulRequests: 0,
      failedRequests: 0,
      lastUsed: DateTime.now().millisecondsSinceEpoch,
      uptime: 1.0,
      stability: 1.0,
      ageHours: 0,
      geoDistanceScore: 0.5,
      consecutiveSuccesses: 0,
      consecutiveFailures: 0,
    );
  }

  /// Creates a new [ProxyScore] with updated values after a successful request
  ProxyScore recordSuccess(double responseTime) {
    final newSuccessfulRequests = successfulRequests + 1;
    final totalRequests = newSuccessfulRequests + failedRequests;

    // Calculate the new average response time
    final newAverageResponseTime =
        successfulRequests > 0
            ? ((averageResponseTime * successfulRequests) + responseTime) /
                newSuccessfulRequests
            : responseTime;

    // Calculate stability based on response time variance
    final expectedResponseTime =
        averageResponseTime > 0 ? averageResponseTime : responseTime;
    final variance =
        (responseTime - expectedResponseTime).abs() / expectedResponseTime;
    final newStability =
        stability * 0.8 + (1.0 - variance.clamp(0.0, 1.0)) * 0.2;

    // Update uptime (weighted average with more weight on recent performance)
    final newUptime = uptime * 0.9 + 0.1;

    // Update age in hours
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final newAgeHours =
        ((currentTime - lastUsed) / (1000 * 60 * 60)).round() + ageHours;

    // Update consecutive counters
    final newConsecutiveSuccesses = consecutiveSuccesses + 1;

    return ProxyScore(
      successRate:
          totalRequests > 0 ? newSuccessfulRequests / totalRequests : 0.0,
      averageResponseTime: newAverageResponseTime.round(),
      successfulRequests: newSuccessfulRequests,
      failedRequests: failedRequests,
      lastUsed: currentTime,
      uptime: newUptime,
      stability: newStability,
      ageHours: newAgeHours,
      geoDistanceScore: geoDistanceScore,
      consecutiveSuccesses: newConsecutiveSuccesses,
      consecutiveFailures: 0, // Reset consecutive failures
    );
  }

  /// Creates a new [ProxyScore] with updated values after a failed request
  ProxyScore recordFailure() {
    final newFailedRequests = failedRequests + 1;
    final totalRequests = successfulRequests + newFailedRequests;

    // Update uptime (weighted average with more weight on recent performance)
    final newUptime = uptime * 0.9; // Decrease uptime by 10%

    // Update age in hours
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final newAgeHours =
        ((currentTime - lastUsed) / (1000 * 60 * 60)).round() + ageHours;

    // Update consecutive counters
    final newConsecutiveFailures = consecutiveFailures + 1;

    return ProxyScore(
      successRate: totalRequests > 0 ? successfulRequests / totalRequests : 0.0,
      averageResponseTime: averageResponseTime,
      successfulRequests: successfulRequests,
      failedRequests: newFailedRequests,
      lastUsed: currentTime,
      uptime: newUptime,
      stability: stability * 0.9, // Decrease stability by 10%
      ageHours: newAgeHours,
      geoDistanceScore: geoDistanceScore,
      consecutiveSuccesses: 0, // Reset consecutive successes
      consecutiveFailures: newConsecutiveFailures,
    );
  }

  /// Calculates a score for the proxy based on multiple factors
  /// Returns a value between 0.0 and 1.0
  double calculateScore() {
    // No requests yet
    if (successfulRequests + failedRequests == 0) {
      return 0.0;
    }

    // Weight factors
    const successRateWeight = 0.30;
    const responseTimeWeight = 0.20;
    const uptimeWeight = 0.15;
    const stabilityWeight = 0.15;
    const ageWeight = 0.05;
    const geoDistanceWeight = 0.05;
    const consecutiveSuccessWeight = 0.10;

    // Calculate response time score (lower is better)
    // Assume 2000ms is the worst acceptable response time
    final responseTimeScore =
        averageResponseTime <= 0
            ? 0.0
            : 1.0 - (averageResponseTime / 2000).clamp(0.0, 1.0);

    // Calculate age score (newer is better, but not too new)
    // Ideal age is between 24 and 72 hours
    final ageScore =
        ageHours < 24
            ? ageHours /
                24 // Ramp up from 0 to 1 in the first 24 hours
            : ageHours > 72
            ? 1.0 -
                ((ageHours - 72) / 168).clamp(
                  0.0,
                  1.0,
                ) // Decay after 72 hours (1 week max)
            : 1.0; // Perfect score between 24-72 hours

    // Calculate consecutive success score
    final consecutiveSuccessScore = (consecutiveSuccesses / 10).clamp(0.0, 1.0);

    // Calculate the final score
    return (successRate * successRateWeight) +
        (responseTimeScore * responseTimeWeight) +
        (uptime * uptimeWeight) +
        (stability * stabilityWeight) +
        (ageScore * ageWeight) +
        (geoDistanceScore * geoDistanceWeight) +
        (consecutiveSuccessScore * consecutiveSuccessWeight);
  }

  /// Creates a [ProxyScore] from a JSON map
  factory ProxyScore.fromJson(Map<String, dynamic> json) {
    return ProxyScore(
      successRate: json['successRate'] as double,
      averageResponseTime: json['averageResponseTime'] as int,
      successfulRequests: json['successfulRequests'] as int,
      failedRequests: json['failedRequests'] as int,
      lastUsed: json['lastUsed'] as int,
      uptime: json['uptime'] as double? ?? 1.0,
      stability: json['stability'] as double? ?? 1.0,
      ageHours: json['ageHours'] as int? ?? 0,
      geoDistanceScore: json['geoDistanceScore'] as double? ?? 0.5,
      consecutiveSuccesses: json['consecutiveSuccesses'] as int? ?? 0,
      consecutiveFailures: json['consecutiveFailures'] as int? ?? 0,
    );
  }

  /// Converts this [ProxyScore] to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'successRate': successRate,
      'averageResponseTime': averageResponseTime,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'lastUsed': lastUsed,
      'uptime': uptime,
      'stability': stability,
      'ageHours': ageHours,
      'geoDistanceScore': geoDistanceScore,
      'consecutiveSuccesses': consecutiveSuccesses,
      'consecutiveFailures': consecutiveFailures,
    };
  }
}
