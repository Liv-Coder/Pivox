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
  
  /// Creates a new [ProxyScore] instance
  const ProxyScore({
    required this.successRate,
    required this.averageResponseTime,
    required this.successfulRequests,
    required this.failedRequests,
    required this.lastUsed,
  });
  
  /// Creates a new [ProxyScore] with default values
  factory ProxyScore.initial() {
    return ProxyScore(
      successRate: 0.0,
      averageResponseTime: 0,
      successfulRequests: 0,
      failedRequests: 0,
      lastUsed: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Creates a new [ProxyScore] with updated values after a successful request
  ProxyScore recordSuccess(int responseTime) {
    final newSuccessfulRequests = successfulRequests + 1;
    final totalRequests = newSuccessfulRequests + failedRequests;
    
    // Calculate the new average response time
    final newAverageResponseTime = successfulRequests > 0
        ? ((averageResponseTime * successfulRequests) + responseTime) / newSuccessfulRequests
        : responseTime;
    
    return ProxyScore(
      successRate: totalRequests > 0 ? newSuccessfulRequests / totalRequests : 0.0,
      averageResponseTime: newAverageResponseTime.round(),
      successfulRequests: newSuccessfulRequests,
      failedRequests: failedRequests,
      lastUsed: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Creates a new [ProxyScore] with updated values after a failed request
  ProxyScore recordFailure() {
    final newFailedRequests = failedRequests + 1;
    final totalRequests = successfulRequests + newFailedRequests;
    
    return ProxyScore(
      successRate: totalRequests > 0 ? successfulRequests / totalRequests : 0.0,
      averageResponseTime: averageResponseTime,
      successfulRequests: successfulRequests,
      failedRequests: newFailedRequests,
      lastUsed: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Calculates a score for the proxy based on success rate and response time
  /// Returns a value between 0.0 and 1.0
  double calculateScore() {
    // No requests yet
    if (successfulRequests + failedRequests == 0) {
      return 0.0;
    }
    
    // Weight factors
    const successRateWeight = 0.7;
    const responseTimeWeight = 0.3;
    
    // Calculate response time score (lower is better)
    // Assume 2000ms is the worst acceptable response time
    final responseTimeScore = averageResponseTime <= 0
        ? 0.0
        : 1.0 - (averageResponseTime / 2000).clamp(0.0, 1.0);
    
    // Calculate the final score
    return (successRate * successRateWeight) + (responseTimeScore * responseTimeWeight);
  }
  
  /// Creates a [ProxyScore] from a JSON map
  factory ProxyScore.fromJson(Map<String, dynamic> json) {
    return ProxyScore(
      successRate: json['successRate'] as double,
      averageResponseTime: json['averageResponseTime'] as int,
      successfulRequests: json['successfulRequests'] as int,
      failedRequests: json['failedRequests'] as int,
      lastUsed: json['lastUsed'] as int,
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
    };
  }
}
