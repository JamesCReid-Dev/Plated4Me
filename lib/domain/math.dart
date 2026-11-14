/// Pure mathematical functions for domain calculations.
///
/// This library contains pure functions used across the domain layer,
/// notably [computeCompositeScore] for Visit rating aggregation (AC-6, P4ME-24).
library plated4me_domain_math;

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
