import 'package:flutter_test/flutter_test.dart';
import 'package:ben/core/utils/retention_policy.dart';

void main() {
  group('RetentionPolicy Tests', () {
    test('retentionDuration is exactly 36 hours', () {
      expect(RetentionPolicy.retentionDuration.inHours, 36);
    });

    test('calculateExpiration adds exactly 36 hours in milliseconds', () {
      const now = 1700000000000;
      final expectedExpiry = now + (36 * 60 * 60 * 1000);
      expect(RetentionPolicy.calculateExpiration(now), expectedExpiry);
    });

    test('isExpired detects timestamps correctly', () {
      final now = RetentionPolicy.currentTimestamp();
      final past = now - 1000;
      final future = now + 10000;

      expect(RetentionPolicy.isExpired(past), isTrue);
      expect(RetentionPolicy.isExpired(future), isFalse);
    });
  });
}
