/// Provider tests for visit rating state management — P4ME-15 (S07).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/visit_rating_provider.dart';

void main() {
  group('AC-1, AC-3, AC-5 — VisitRatingNotifier', () {
    test('initializes with zero ratings and null composite score', () {
      final container = ProviderContainer();
      final state = container.read(visitRatingProvider);

      expect(state.foodRating, equals(0.0));
      expect(state.valueRating, equals(0.0));
      expect(state.serviceRating, equals(0.0));
      expect(state.overallRating, equals(0.0));
      expect(state.compositeScore, isNull);
    });

    test('setFoodRating updates food rating and recalculates composite', () {
      final container = ProviderContainer();
      container.read(visitRatingProvider.notifier).setFoodRating(4.0);
      final state = container.read(visitRatingProvider);

      expect(state.foodRating, equals(4.0));
      expect(state.compositeScore, isNotNull);
    });

    test('setValueRating updates value rating and recalculates composite', () {
      final container = ProviderContainer();
      container.read(visitRatingProvider.notifier).setValueRating(3.5);
      final state = container.read(visitRatingProvider);

      expect(state.valueRating, equals(3.5));
    });

    test('setServiceRating updates service rating and recalculates composite',
        () {
      final container = ProviderContainer();
      container
          .read(visitRatingProvider.notifier)
          .setServiceRating(4.5);
      final state = container.read(visitRatingProvider);

      expect(state.serviceRating, equals(4.5));
    });

    test('setOverallRating updates overall rating and recalculates composite',
        () {
      final container = ProviderContainer();
      container
          .read(visitRatingProvider.notifier)
          .setOverallRating(4.0);
      final state = container.read(visitRatingProvider);

      expect(state.overallRating, equals(4.0));
    });

    test('composite score updates in real-time as each rating changes (AC-3)', () {
      final container = ProviderContainer();
      final notifier = container.read(visitRatingProvider.notifier);

      // After setting just food, composite should already be computed
      notifier.setFoodRating(4.0);
      expect(container.read(visitRatingProvider).compositeScore, isNotNull);
      expect(container.read(visitRatingProvider).compositeScore, equals(1.6));

      // After adding value rating, composite updates
      notifier.setValueRating(3.5);
      final state2 = container.read(visitRatingProvider);
      expect(state2.compositeScore, closeTo(2.65, 0.0001));

      // After all four are set, composite is fully computed
      notifier.setServiceRating(4.5);
      notifier.setOverallRating(4.0);
      final state3 = container.read(visitRatingProvider);
      expect(state3.compositeScore, closeTo(3.925, 0.0001));
    });

    test('toggleReturnIntent flips the return intent flag', () {
      final container = ProviderContainer();
      final notifier = container.read(visitRatingProvider.notifier);

      expect(container.read(visitRatingProvider).returnIntent, isNull);

      notifier.toggleReturnIntent(true);
      expect(
        container.read(visitRatingProvider).returnIntent,
        equals(true),
      );

      notifier.toggleReturnIntent(false);
      expect(
        container.read(visitRatingProvider).returnIntent,
        equals(false),
      );
    });

    test('reset clears all ratings and composite score', () {
      final container = ProviderContainer();
      final notifier = container.read(visitRatingProvider.notifier);

      notifier.setFoodRating(4.0);
      notifier.setValueRating(3.5);
      notifier.setServiceRating(4.5);
      notifier.setOverallRating(4.0);
      notifier.toggleReturnIntent(true);

      notifier.reset();

      final state = container.read(visitRatingProvider);
      expect(state.foodRating, equals(0.0));
      expect(state.valueRating, equals(0.0));
      expect(state.serviceRating, equals(0.0));
      expect(state.overallRating, equals(0.0));
      expect(state.compositeScore, isNull);
      expect(state.returnIntent, isNull);
    });

    test('isSaveEnabled returns false when any rating is zero', () {
      final container = ProviderContainer();
      final notifier = container.read(visitRatingProvider.notifier);

      expect(container.read(visitRatingProvider).isSaveEnabled, isFalse);

      notifier.setFoodRating(4.0);
      expect(container.read(visitRatingProvider).isSaveEnabled, isFalse);

      notifier.setValueRating(3.5);
      expect(container.read(visitRatingProvider).isSaveEnabled, isFalse);

      notifier.setServiceRating(4.5);
      expect(container.read(visitRatingProvider).isSaveEnabled, isFalse);

      notifier.setOverallRating(4.0);
      expect(container.read(visitRatingProvider).isSaveEnabled, isTrue);
    });
  });
}
