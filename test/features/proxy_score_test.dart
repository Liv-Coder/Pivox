import 'package:flutter_test/flutter_test.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_score.dart';

void main() {
  group('ProxyScore', () {
    test('initial creates instance with default values', () {
      final score = ProxyScore.initial();

      expect(score.successRate, 0.0);
      expect(score.averageResponseTime, 0);
      expect(score.successfulRequests, 0);
      expect(score.failedRequests, 0);
      expect(score.uptime, 1.0);
      expect(score.stability, 1.0);
      expect(score.ageHours, 0);
      expect(score.geoDistanceScore, 0.5);
      expect(score.consecutiveSuccesses, 0);
      expect(score.consecutiveFailures, 0);
    });

    test('recordSuccess updates values correctly', () {
      final initialScore = ProxyScore.initial();
      final updatedScore = initialScore.recordSuccess(500);

      expect(updatedScore.successRate, 1.0);
      expect(updatedScore.averageResponseTime, 500);
      expect(updatedScore.successfulRequests, 1);
      expect(updatedScore.failedRequests, 0);
      expect(updatedScore.consecutiveSuccesses, 1);
      expect(updatedScore.consecutiveFailures, 0);
    });

    test('recordFailure updates values correctly', () {
      final initialScore = ProxyScore.initial();
      final updatedScore = initialScore.recordFailure();

      expect(updatedScore.successRate, 0.0);
      expect(updatedScore.averageResponseTime, 0);
      expect(updatedScore.successfulRequests, 0);
      expect(updatedScore.failedRequests, 1);
      expect(updatedScore.consecutiveSuccesses, 0);
      expect(updatedScore.consecutiveFailures, 1);
    });

    test('calculateScore returns weighted score', () {
      final score = ProxyScore(
        successRate: 0.8,
        averageResponseTime: 500,
        successfulRequests: 8,
        failedRequests: 2,
        lastUsed: DateTime.now().millisecondsSinceEpoch,
        uptime: 0.9,
        stability: 0.85,
        ageHours: 48,
        geoDistanceScore: 0.7,
        consecutiveSuccesses: 5,
        consecutiveFailures: 0,
      );

      final calculatedScore = score.calculateScore();

      // Verify score is between 0 and 1
      expect(calculatedScore >= 0.0 && calculatedScore <= 1.0, true);

      // Verify score is higher than 0.5 given the good metrics
      expect(calculatedScore > 0.5, true);
    });
  });
}
