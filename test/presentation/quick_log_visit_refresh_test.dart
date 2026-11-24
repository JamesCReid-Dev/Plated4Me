/// Regression tests for P4ME-55 — Visit history doesn't update immediately after saving from Quick Log.
///
/// Red Phase: These tests verify that a visit saved via QuickLogScreen appears in the
/// visitsListFilterProvider (BrowseScreen's data source) without requiring manual pull-to-refresh.
///
/// CURRENT STATE (BUG): After save, visitsListFilterProvider is NOT refreshed — it still shows
/// stale data from its initial build(). The new visit only appears after user pulls to refresh.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/application/providers/visit_rating_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/restaurant_repository.dart';
import 'package:plated4me/domain/repositories/visit_repository.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';

import 'helpers.dart';

// -- Fake repositories ----------------------------------------------------------

class FakeRestaurantRepositoryForP4ME55 implements RestaurantRepository {
  final List<Restaurant> _restaurants = [];

  @override Future<List<Restaurant>> getAllRestaurants() async => _restaurants;
  @override Future<Restaurant?> getRestaurantById(Id id) async => null;
  @override Future<List<Restaurant>> searchRestaurants(String query) async => [];
  @override Future<Restaurant> saveRestaurant(Restaurant r) async { _restaurants.add(r); return r; }
  @override Future<bool> deleteRestaurant(Id id) async => false;
  @override Future<bool> existsByName(String name) async => false;
  @override Future<Restaurant?> getByNamedAddress(String name, String? address) async => null;

  List<Restaurant> get savedRestaurants => List.unmodifiable(_restaurants);
}

class FakeVisitRepositoryForP4ME55 implements VisitRepository {
  final List<Visit> _visits = [];

  @override Future<List<Visit>> getAllVisits() async => _visits;
  @override Future<Visit?> getVisitById(Id id) async => null;
  @override Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async => [];
  @override Future<Visit> saveVisit(Visit v) async { _visits.add(v); return v; }
  @override Future<bool> deleteVisit(Id id) async => false;
  @override Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to) async => [];
  @override Stream<List<Visit>> visitStream() => Stream.value([]);
  @override Future<List<Visit>> searchVisits(String query) async => [];
  @override Future<int> bulkDeleteBlacklistedVisits() async => 0;

  List<Visit> get savedVisits => List.unmodifiable(_visits);
}

// -- Helpers --------------------------------------------------------------------

ProviderContainer makeP4ME55Container() {
  final fakeRestaurantRepo = FakeRestaurantRepositoryForP4ME55();
  final fakeVisitRepo = FakeVisitRepositoryForP4ME55();

  // Seed one restaurant so QuickLog auto-selects it.
  final seedRestaurant = Restaurant(name: 'Test Bistro', address: '123 Main St');
  fakeRestaurantRepo.saveRestaurant(seedRestaurant);

  return ProviderContainer(overrides: [
    userPreferencesDataProvider.overrideWith(() {
      return FakeUserPrefsNotifier(UserPreferences()..onboardingComplete = true);
    }),
    restaurantRepositoryProvider.overrideWith((ref) => fakeRestaurantRepo),
    visitRepositoryProvider.overrideWith((ref) => fakeVisitRepo),
  ]);
}

Finder findSaveButtonP4ME55() => find.byType(ElevatedButton).last;

// -- P4ME-55 Tests --------------------------------------------------------------

void main() {
  group('P4ME-55 — Visit history refreshes after QuickLog save', () {
    testWidgets(
      'new visit appears in visitsListFilterProvider immediately after save (no manual refresh)',
      (tester) async {
        final container = makeP4ME55Container();

        // Verify initial state: no visits in filter provider.
        final initialVisits = await container.read(visitsListFilterProvider.future);
        expect(initialVisits, isEmpty, reason: 'Should start with zero visits');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set ratings to enable save button.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);

        // Tap save (no restaurant notes needed for this test).
        // Pump first to ensure ratings are reflected in the UI.
        await tester.pump();
        await tester.tap(findSaveButtonP4ME55());
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Verify the visit was actually saved to the repo.
        final fakeVisitRepo = container.read(visitRepositoryProvider) as FakeVisitRepositoryForP4ME55;
        expect(fakeVisitRepo.savedVisits.length, equals(1), reason: 'Visit should be in repo');

        // P4ME-55: visitsListFilterProvider should now contain the new visit
        // WITHOUT calling refresh() manually.
        final updatedVisits = await container.read(visitsListFilterProvider.future);
        expect(
          updatedVisits,
          isNotEmpty,
          reason: 'P4ME-55: visitsListFilterProvider should reflect saved visit without manual refresh',
        );
      },
    );

    testWidgets(
      'saved visit appears with correct restaurant name in visitsListFilterProvider',
      (tester) async {
        final container = makeP4ME55Container();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set ratings.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);

        // Pump first to ensure ratings are reflected in the UI, then save.
        await tester.pump();
        await tester.tap(findSaveButtonP4ME55());
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Verify the filtered visit has the correct restaurant name.
        final updatedVisits = await container.read(visitsListFilterProvider.future);
        expect(updatedVisits.length, equals(1), reason: 'Should have exactly one visit');
        expect(
          updatedVisits.first.restaurant.name,
          equals('Test Bistro'),
          reason: 'P4ME-55: restaurant name should be resolved correctly',
        );
      },
    );
  });
}
