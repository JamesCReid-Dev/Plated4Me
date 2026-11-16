/// Riverpod provider for visit rating state management.
///
/// Manages the four individual ratings (Food, Value, Service, Overall),
/// computes a weighted composite score when all four are set, and tracks
/// return intent (AC-1, AC-3, AC-5, P4ME-15).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/domain/math.dart';

/// Immutable state for the visit rating screen.
class VisitRatingState {
  /// Food Quality rating (0–scale).
  final double foodRating;

  /// Value rating (0–scale).
  final double valueRating;

  /// Service rating (0–scale).
  final double serviceRating;

  /// Overall experience rating (0–scale).
  final double overallRating;

  /// Pre-computed weighted composite score. Null until all four ratings are set.
  final double? compositeScore;

  /// User's return intent: true = would come back, false = would not.
  /// Null when not yet set.
  final bool? returnIntent;

  /// Whether the save button should be enabled (all four ratings > 0).
  bool get isSaveEnabled =>
      foodRating > 0 && valueRating > 0 && serviceRating > 0 && overallRating > 0;

  const VisitRatingState({
    this.foodRating = 0.0,
    this.valueRating = 0.0,
    this.serviceRating = 0.0,
    this.overallRating = 0.0,
    this.compositeScore,
    this.returnIntent,
  });

  VisitRatingState copyWith({
    double? foodRating,
    double? valueRating,
    double? serviceRating,
    double? overallRating,
    double? compositeScore,
    bool? returnIntent,
  }) {
    return VisitRatingState(
      foodRating: foodRating ?? this.foodRating,
      valueRating: valueRating ?? this.valueRating,
      serviceRating: serviceRating ?? this.serviceRating,
      overallRating: overallRating ?? this.overallRating,
      compositeScore: compositeScore ?? this.compositeScore,
      returnIntent: returnIntent ?? this.returnIntent,
    );
  }
}

/// Notifier that manages visit rating state and composite score calculation.
class VisitRatingNotifier extends StateNotifier<VisitRatingState> {
  VisitRatingNotifier() : super(const VisitRatingState());

  /// Sets the Food Quality rating and recalculates composite score.
  void setFoodRating(double value) {
    final newComposite = _computeComposite(
      food: value,
      value: state.valueRating,
      service: state.serviceRating,
      overall: state.overallRating,
    );
    state = state.copyWith(foodRating: value, compositeScore: newComposite);
  }

  /// Sets the Value rating and recalculates composite score.
  void setValueRating(double value) {
    final newComposite = _computeComposite(
      food: state.foodRating,
      value: value,
      service: state.serviceRating,
      overall: state.overallRating,
    );
    state = state.copyWith(valueRating: value, compositeScore: newComposite);
  }

  /// Sets the Service rating and recalculates composite score.
  void setServiceRating(double value) {
    final newComposite = _computeComposite(
      food: state.foodRating,
      value: state.valueRating,
      service: value,
      overall: state.overallRating,
    );
    state = state.copyWith(serviceRating: value, compositeScore: newComposite);
  }

  /// Sets the Overall rating and recalculates composite score.
  void setOverallRating(double value) {
    final newComposite = _computeComposite(
      food: state.foodRating,
      value: state.valueRating,
      service: state.serviceRating,
      overall: value,
    );
    state = state.copyWith(overallRating: value, compositeScore: newComposite);
  }

  /// Sets the return intent flag.
  void toggleReturnIntent(bool value) {
    state = state.copyWith(returnIntent: value);
  }

  /// Resets all ratings and return intent to defaults.
  void reset() {
    state = const VisitRatingState();
  }

  /// Computes composite score from the four ratings.
  double _computeComposite({
    required double food,
    required double value,
    required double service,
    required double overall,
  }) {
    return computeCompositeScore(
      food: food,
      value: value,
      service: service,
      overall: overall,
    );
  }

  /// Returns the current rating values as a map for saving.
  Map<String, double> getRatings() {
    return {
      'food': state.foodRating,
      'value': state.valueRating,
      'service': state.serviceRating,
      'overall': state.overallRating,
    };
  }
}

/// Provider for visit rating state.
final StateNotifierProvider<VisitRatingNotifier, VisitRatingState>
visitRatingProvider = StateNotifierProvider<VisitRatingNotifier, VisitRatingState>(
  (_) => VisitRatingNotifier(),
);
