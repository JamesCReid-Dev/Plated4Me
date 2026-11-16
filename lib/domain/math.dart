/// Pure mathematical functions for domain calculations.
///
/// This library contains pure functions used across the domain layer,
/// notably [computeCompositeScore] for Visit rating aggregation (AC-6, P4ME-24).

import 'package:plated4me/domain/entities/entities.dart';

/// Result of computing a composite score with return intent derivation.
class CompositeScoreResult {
  /// The weighted composite score.
  final double score;

  /// Whether the user intends to return (score >= 3.5).
  final bool returnIntent;

  const CompositeScoreResult({required this.score, required this.returnIntent});
}

// -- Constants -----------------------------------------------------------------

/// Weight for food rating in composite score calculation.
const double _kFoodWeight = 0.40;

/// Weight for value rating in composite score calculation.
const double _kValueWeight = 0.30;

/// Weight for service rating in composite score calculation.
const double _kServiceWeight = 0.15;

/// Weight for overall rating in composite score calculation.
const double _kOverallWeight = 0.15;

/// Threshold above which a visit indicates return intent.
const double _kReturnIntentThreshold = 3.5;

/// Default rating scale maximum (5-star).
const int kDefaultRatingScaleMax = 5;

/// Alternative rating scale maximum (10-star).
const int kAlternativeRatingScaleMax = 10;

// -- Public API ----------------------------------------------------------------

/// Computes a weighted composite score from individual ratings.
///
/// Weights: food=0.40, value=0.30, service=0.15, overall=0.15.
/// This is a pure function — no side effects, deterministic output.
///
/// Called before persisting any [Visit] (AC-6, P4ME-24, AD-4).
double computeCompositeScore({
  required double food,
  required double value,
  required double service,
  required double overall,
}) {
  return food * _kFoodWeight +
      value * _kValueWeight +
      service * _kServiceWeight +
      overall * _kOverallWeight;
}

/// Computes a composite score and derives return intent.
///
/// Returns [CompositeScoreResult] with both the weighted score and whether
/// the user intends to return (score >= [_kReturnIntentThreshold]).
CompositeScoreResult computeCompositeScoreWithReturnIntent({
  required double food,
  required double value,
  required double service,
  required double overall,
}) {
  final score = computeCompositeScore(
    food: food,
    value: value,
    service: service,
    overall: overall,
  );
  return CompositeScoreResult(
    score: score,
    returnIntent: score >= _kReturnIntentThreshold,
  );
}

// -- Rating Scale Conversion (AC-2) --------------------------------------------

/// Converts a rating from a 5-star scale to a 10-star scale.
///
/// Multiplies the rating by 2.0 (e.g., 3.0 → 6.0).
/// Used when user switches preference from 5-star to 10-star rating scale.
///
/// See also:
///  - [scaleToFive] — reverse conversion
///  - [scaleRating] — generic conversion between any two scales
double scaleToTen(double rating) => rating * 2.0;

/// Converts a rating from a 10-star scale to a 5-star scale.
///
/// Divides the rating by 2.0 (e.g., 6.0 → 3.0).
/// Used when user switches preference from 10-star back to 5-star rating scale.
/// Existing visit ratings are re-scaled using this function.
///
/// See also:
///  - [scaleToTen] — reverse conversion
///  - [scaleRating] — generic conversion between any two scales
double scaleToFive(double rating) => rating / 2.0;

/// Generic rating scale conversion.
///
/// Converts [rating] from [fromScale] to [toScale].
/// For example, converting a 7/10 rating to 5-star: `scaleRating(7.0, fromScale: 10, toScale: 5)` → 3.5.
///
/// Returns the original [rating] unchanged if both scales are equal.
/// Values are normalized to 0.0–1.0 range then scaled to the target maximum,
/// rounded to the nearest hundredth to avoid floating-point drift.
double scaleRating({
  required double rating,
  required int fromScale,
  required int toScale,
}) {
  if (fromScale == toScale) return rating;
  final normalized = rating / fromScale; // 0.0 — 1.0
  return (normalized * toScale).roundToDouble();
}

/// Converts all ratings on a [Visit] when the user changes their rating scale preference.
///
/// Takes existing ratings recorded on the [fromScale] and returns new ratings
/// suitable for the [toScale]. Also re-computes the composite score in the
/// new scale.
///
/// Returns a map with keys: `foodRating`, `valueRating`, `serviceRating`,
/// `overallRating`, and `compositeScore` — all in the target scale.
Map<String, double> rescaleVisitRatings({
  required double foodRating,
  required double valueRating,
  required double serviceRating,
  required double overallRating,
  required double compositeScore,
  required int fromScale,
  required int toScale,
}) {
  final scale = (fromScale < toScale) ? scaleToTen : scaleToFive;

  return {
    'foodRating': scale(foodRating),
    'valueRating': scale(valueRating),
    'serviceRating': scale(serviceRating),
    'overallRating': scale(overallRating),
    'compositeScore': scale(compositeScore),
  };
}
