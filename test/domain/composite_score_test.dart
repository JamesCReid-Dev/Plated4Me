/// Domain tests for the pure function `computeCompositeScore`.
///
/// Covers AC-6 of P4ME-24:
///   Domain pure function computeCompositeScore(food, value, service, overall)
///   with fixed weights 0.40/0.30/0.15/0.15 called before persisting any Visit.
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/math.dart';

void main() {
  // -- AC-6: Correct weighted calculation ------------------------------------

  group('AC-6 — computeCompositeScore', () {
    test('computes correct weighted score for standard ratings (4.0, 3.5, 4.5, 4.0)', () {
      // Weights: food 0.40, value 0.30, service 0.15, overall 0.15
      // Expected: 4.0*0.40 + 3.5*0.30 + 4.5*0.15 + 4.0*0.15 = 1.60 + 1.05 + 0.675 + 0.60 = 3.925
      final score = computeCompositeScore(
        food: 4.0,
        value: 3.5,
        service: 4.5,
        overall: 4.0,
      );

      expect(score, closeTo(3.925, 0.0001));
    });

    test('computes correct weighted score for all maximum ratings (5.0)', () {
      // 5.0*0.40 + 5.0*0.30 + 5.0*0.15 + 5.0*0.15 = 5.0
      final score = computeCompositeScore(
        food: 5.0,
        value: 5.0,
        service: 5.0,
        overall: 5.0,
      );

      expect(score, closeTo(5.0, 0.0001));
    });

    test('computes correct weighted score for all minimum ratings (0.0)', () {
      // 0.0*0.40 + 0.0*0.30 + 0.0*0.15 + 0.0*0.15 = 0.0
      final score = computeCompositeScore(
        food: 0.0,
        value: 0.0,
        service: 0.0,
        overall: 0.0,
      );

      expect(score, closeTo(0.0, 0.0001));
    });

    test('computes correct weighted score for all ones (1.0)', () {
      // 1.0*0.40 + 1.0*0.30 + 1.0*0.15 + 1.0*0.15 = 1.0
      final score = computeCompositeScore(
        food: 1.0,
        value: 1.0,
        service: 1.0,
        overall: 1.0,
      );

      expect(score, closeTo(1.0, 0.0001));
    });

    // -- Edge cases ------------------------------------------------------------

    test('returns 0.0 when all ratings are zero', () {
      final score = computeCompositeScore(
        food: 0.0,
        value: 0.0,
        service: 0.0,
        overall: 0.0,
      );

      expect(score, equals(0.0));
    });

    test('returns max score when all ratings are at maximum (5.0)', () {
      final score = computeCompositeScore(
        food: 5.0,
        value: 5.0,
        service: 5.0,
        overall: 5.0,
      );

      expect(score, equals(5.0));
    });

    test('handles asymmetric ratings correctly', () {
      // food=1.0, value=5.0, service=1.0, overall=5.0
      // = 0.40 + 1.50 + 0.15 + 0.75 = 2.80
      final score = computeCompositeScore(
        food: 1.0,
        value: 5.0,
        service: 1.0,
        overall: 5.0,
      );

      expect(score, closeTo(2.80, 0.0001));
    });

    test('handles half-point ratings correctly', () {
      // food=3.5, value=4.0, service=3.0, overall=4.5
      // = 1.40 + 1.20 + 0.45 + 0.675 = 3.725
      final score = computeCompositeScore(
        food: 3.5,
        value: 4.0,
        service: 3.0,
        overall: 4.5,
      );

      expect(score, closeTo(3.725, 0.0001));
    });

    // -- Purity tests ----------------------------------------------------------

    test('is a pure function — same inputs always produce same output', () {
      final score1 = computeCompositeScore(
        food: 4.2,
        value: 3.8,
        service: 4.0,
        overall: 3.5,
      );
      final score2 = computeCompositeScore(
        food: 4.2,
        value: 3.8,
        service: 4.0,
        overall: 3.5,
      );

      expect(score1, equals(score2));
    });

    test('does not modify input values (pure function)', () {
      var food = 4.0;
      final originalFood = food;
      computeCompositeScore(food: food, value: 3.5, service: 4.5, overall: 4.0);

      expect(food, equals(originalFood)); // inputs unchanged
    });

    // -- Weight verification ---------------------------------------------------

    test('food rating has the highest weight (0.40)', () {
      // Increasing food by 1.0 should increase score by exactly 0.40
      final base = computeCompositeScore(
        food: 3.0,
        value: 4.0,
        service: 4.0,
        overall: 4.0,
      );
      final elevated = computeCompositeScore(
        food: 4.0,
        value: 4.0,
        service: 4.0,
        overall: 4.0,
      );

      expect(elevated - base, closeTo(0.40, 0.0001));
    });

    test('value rating has weight 0.30', () {
      final base = computeCompositeScore(
        food: 4.0,
        value: 3.0,
        service: 4.0,
        overall: 4.0,
      );
      final elevated = computeCompositeScore(
        food: 4.0,
        value: 4.0,
        service: 4.0,
        overall: 4.0,
      );

      expect(elevated - base, closeTo(0.30, 0.0001));
    });

    test('service rating has weight 0.15', () {
      final base = computeCompositeScore(
        food: 4.0,
        value: 4.0,
        service: 3.0,
        overall: 4.0,
      );
      final elevated = computeCompositeScore(
        food: 4.0,
        value: 4.0,
        service: 4.0,
        overall: 4.0,
      );

      expect(elevated - base, closeTo(0.15, 0.0001));
    });

    test('overall rating has weight 0.15', () {
      final base = computeCompositeScore(
        food: 4.0,
        value: 4.0,
        service: 4.0,
        overall: 3.0,
      );
      final elevated = computeCompositeScore(
        food: 4.0,
        value: 4.0,
        service: 4.0,
        overall: 4.0,
      );

      expect(elevated - base, closeTo(0.15, 0.0001));
    });

    // -- Return intent derivation ----------------------------------------------

    test(
      'returns true when composite score >= 3.5 (return intent threshold)',
      () {
        final result = computeCompositeScoreWithReturnIntent(
          food: 4.0,
          value: 4.0,
          service: 3.0,
          overall: 4.0,
        );
        // Score: 1.6 + 1.2 + 0.45 + 0.6 = 3.85 >= 3.5 → returnIntent = true
        expect(result.score, closeTo(3.85, 0.0001));
        expect(result.returnIntent, isTrue);
      },
    );

    test('returns false when composite score < 3.5 (no return intent)', () {
      final result = computeCompositeScoreWithReturnIntent(
        food: 2.0,
        value: 2.0,
        service: 2.0,
        overall: 2.0,
      );
      // Score: 0.8 + 0.6 + 0.3 + 0.3 = 2.0 < 3.5 → returnIntent = false
      expect(result.score, closeTo(2.0, 0.0001));
      expect(result.returnIntent, isFalse);
    });

    test('returns true at exact threshold of 3.5', () {
      // Need score exactly 3.5: food=4.0, value=4.0, service=3.333..., overall=4.0
      // Simpler: food=3.5, value=3.5, service=3.5, overall=3.5 = 3.5 exactly
      final result = computeCompositeScoreWithReturnIntent(
        food: 3.5,
        value: 3.5,
        service: 3.5,
        overall: 3.5,
      );
      expect(result.score, closeTo(3.5, 0.0001));
      expect(result.returnIntent, isTrue);
    });

    // -- Negative / boundary tests ---------------------------------------------

    test('handles rating of exactly 0 for food only', () {
      final score = computeCompositeScore(
        food: 0.0,
        value: 5.0,
        service: 5.0,
        overall: 5.0,
      );
      // = 0 + 1.5 + 0.75 + 0.75 = 3.0
      expect(score, closeTo(3.0, 0.0001));
    });

    test('handles rating of exactly 0 for service only', () {
      final score = computeCompositeScore(
        food: 5.0,
        value: 5.0,
        service: 0.0,
        overall: 5.0,
      );
      // = 2.0 + 1.5 + 0 + 0.75 = 4.25
      expect(score, closeTo(4.25, 0.0001));
    });

    test('score is clamped within [0, 5] for any valid input range', () {
      final score = computeCompositeScore(
        food: 0.0,
        value: 0.0,
        service: 0.0,
        overall: 0.0,
      );

      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(5.0));
    });
  });
}
