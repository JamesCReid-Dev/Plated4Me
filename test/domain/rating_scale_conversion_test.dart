/// Domain unit tests for rating scale conversion (AC-2).
///
/// Red Phase: These tests verify that converting ratings between 5-star and
/// 10-star scales produces correct results. The production code will need a
/// pure function in the domain math library to handle the conversion math.
///
/// NOTE: These tests call functions that do NOT yet exist in production code.
/// They must FAIL until the Green Phase implements them.
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/math.dart';

void main() {
  group('AC-2 — Rating Scale Conversion', () {
    // -- 5 → 10 star conversions -------------------------------------------

    test('AC-2: converts 5-star rating 1.0 to 10-star 2.0', () {
      expect(scaleToTen(1.0), equals(2.0));
    });

    test('AC-2: converts 5-star rating 2.0 to 10-star 4.0', () {
      expect(scaleToTen(2.0), equals(4.0));
    });

    test('AC-2: converts 5-star rating 3.0 to 10-star 6.0', () {
      expect(scaleToTen(3.0), equals(6.0));
    });

    test('AC-2: converts 5-star rating 4.0 to 10-star 8.0', () {
      expect(scaleToTen(4.0), equals(8.0));
    });

    test('AC-2: converts 5-star rating 5.0 to 10-star 10.0', () {
      expect(scaleToTen(5.0), equals(10.0));
    });

    test('AC-2: converts 5-star rating 0.0 to 10-star 0.0', () {
      expect(scaleToTen(0.0), equals(0.0));
    });

    test('AC-2: converts 5-star rating 3.5 to 10-star 7.0', () {
      expect(scaleToTen(3.5), equals(7.0));
    });

    // -- 10 → 5 star conversions -------------------------------------------

    test('AC-2: converts 10-star rating 2.0 to 5-star 1.0', () {
      expect(scaleToFive(2.0), equals(1.0));
    });

    test('AC-2: converts 10-star rating 4.0 to 5-star 2.0', () {
      expect(scaleToFive(4.0), equals(2.0));
    });

    test('AC-2: converts 10-star rating 6.0 to 5-star 3.0', () {
      expect(scaleToFive(6.0), equals(3.0));
    });

    test('AC-2: converts 10-star rating 8.0 to 5-star 4.0', () {
      expect(scaleToFive(8.0), equals(4.0));
    });

    test('AC-2: converts 10-star rating 10.0 to 5-star 5.0', () {
      expect(scaleToFive(10.0), equals(5.0));
    });

    test('AC-2: converts 10-star rating 0.0 to 5-star 0.0', () {
      expect(scaleToFive(0.0), equals(0.0));
    });

    test('AC-2: converts 10-star rating 7.0 to 5-star 3.5', () {
      expect(scaleToFive(7.0), equals(3.5));
    });

    // -- Round-trip identity -----------------------------------------------

    test('AC-2: scaleToTen then scaleToFive returns original value', () {
      for (final rating in [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]) {
        final converted = scaleToTen(rating);
        expect(scaleToFive(converted), equals(rating));
      }
    });

    test('AC-2: scaleToFive then scaleToTen returns original value', () {
      for (final rating in [0.0, 2.0, 4.0, 6.0, 8.0, 10.0]) {
        final converted = scaleToFive(rating);
        expect(scaleToTen(converted), equals(rating));
      }
    });

    // -- Edge cases --------------------------------------------------------

    test('AC-2: converts fractional 5-star rating 4.5 to 10-star 9.0', () {
      expect(scaleToTen(4.5), equals(9.0));
    });

    test('AC-2: converts fractional 10-star rating 9.0 to 5-star 4.5', () {
      expect(scaleToFive(9.0), equals(4.5));
    });

    // -- No-op conversions -------------------------------------------------

    test('AC-2: scaleRating with same scales returns input unchanged', () {
      expect(scaleRating(rating: 3.0, fromScale: 5, toScale: 5), equals(3.0));
    });

    test('AC-2: scaleRating with same scales returns input unchanged (10)', () {
      expect(scaleRating(rating: 7.0, fromScale: 10, toScale: 10), equals(7.0));
    });

    // -- Composite score re-scaling ----------------------------------------

    test('AC-2: composite score 3.95 (5-star) converts to ~7.9 (10-star)', () {
      expect(scaleToTen(3.95), closeTo(7.9, 0.01));
    });

    test('AC-2: composite score 4.75 (5-star) converts to ~9.5 (10-star)', () {
      expect(scaleToTen(4.75), closeTo(9.5, 0.01));
    });
  });
}
