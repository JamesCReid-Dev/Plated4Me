/// Provider tests for FavoritesNotifier — P4ME-59 (Defect fix).
///
/// Regression tests for LateInitializationError on dispose/rebuild cycles.
/// The _restaurants late field was re-initialized after provider disposal,
/// causing crashes on Browse screen after saving preferences or app restart.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/favorites_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';

// -- Mock repositories (shared with data_provider_test.dart) ------------------

class _MockRestaurantRepository implements RestaurantRepository {
  List<Restaurant> data = [];

  @override
  Future<List<Restaurant>> getAllRestaurants() async => data;

  @override
  Future<Restaurant?> getRestaurantById(int id) async {
    try {
      return data.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async => [];

  @override
  Future<Restaurant> saveRestaurant(Restaurant restaurant) async {
    final idx = data.indexWhere((r) => r.id == restaurant.id);
    if (idx >= 0) {
      data[idx] = restaurant;
    } else {
      data.add(restaurant);
    }
    return restaurant;
  }

  @override
  Future<bool> deleteRestaurant(int id) async => false;

  @override
  Future<bool> existsByName(String name) async => false;

  @override
  Future<Restaurant?> getByNamedAddress(
    String name,
    String? address,
  ) async => null;
}

class _MockVisitRepository implements VisitRepository {
  List<Visit> data = [];

  @override
  Future<List<Visit>> getAllVisits() async => data;

  @override
  Future<Visit?> getVisitById(int id) async => null;

  @override
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async => [];

  @override
  Future<Visit> saveVisit(Visit visit) async {
    data.add(visit);
    return visit;
  }

  @override
  Future<bool> deleteVisit(int id) async => false;

  @override
  Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to) async => [];

  @override
  Future<List<Visit>> searchVisits(String query) async => [];

  @override
  Future<int> bulkDeleteBlacklistedVisits() async => 0;

  @override
  Stream<List<Visit>> visitStream() => const Stream.empty();
}

class _MockUserPreferencesRepository implements UserPreferencesRepository {
  @override
  Future<UserPreferences> getUserPreferences() async => UserPreferences();

  @override
  Future<UserPreferences> saveUserPreferences(
    UserPreferences preferences,
  ) async =>
      preferences;

  @override
  Future<bool> hasPreferences() async => true;
}

// -- Test fixtures ------------------------------------------------------------

Restaurant _restaurant({required int id, required String name}) {
  return Restaurant(name: name)..id = id;
}

Visit _visit({
  required int restaurantId,
  double compositeScore = 5.0,
  bool returnIntent = true,
}) {
  return Visit(
    restaurantId: restaurantId,
    foodRating: compositeScore,
    valueRating: compositeScore,
    serviceRating: compositeScore,
    overallRating: compositeScore,
    compositeScore: compositeScore,
    returnIntent: returnIntent,
  );
}

/// Helper that waits for the AsyncNotifierProviders underlying a container to
/// reach [AsyncData] state.  Required because [restaurantDataProvider] and
/// [visitsDataProvider] load asynchronously — reading favorites before they
/// finish would return an empty list instead of the computed result.
Future<void> _awaitDataReady(ProviderContainer container) async {
  var loaded = false;
  while (!loaded) {
    final rState = container.read(restaurantDataProvider);
    final vState = container.read(visitsDataProvider);
    if (rState is AsyncData && vState is AsyncData) {
      loaded = true;
    } else {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
}

// -- Overrides helper ---------------------------------------------------------

List<Override> _overrides(
  _MockRestaurantRepository repo,
  _MockVisitRepository visitRepo,
) => [
  restaurantRepositoryProvider.overrideWith((_) => repo),
  visitRepositoryProvider.overrideWith((_) => visitRepo),
  userPreferencesRepositoryProvider.overrideWith((_) => _MockUserPreferencesRepository()),
];

void main() {
  group('P4ME-59 — FavoritesNotifier dispose/rebuild', () {
    test(
      'refresh within same container does NOT throw LateInitializationError',
      () async {
        // Simulates: Browse screen stays alive but data changes trigger a rebuild.
        // The Notifier instance is reused; build() runs again on the same object.
        final repo = _MockRestaurantRepository();
        repo.data = [_restaurant(id: 1, name: 'Pizza')];

        final visitRepo = _MockVisitRepository();
        visitRepo.data = [
          _visit(restaurantId: 1),
          _visit(restaurantId: 1),
        ];

        final container = ProviderContainer(
          overrides: _overrides(repo, visitRepo),
        );

        await _awaitDataReady(container);

        // First read — initializes the notifier.
        final favs1 = container.read(favoritesProvider);
        expect(favs1, hasLength(1));

        // Refresh triggers a second call to build() on the SAME notifier instance.
        // With the late final field bug, this throws:
        //   LateInitializationError: Field "_restaurants@..." has already been initialized
        container.refresh(favoritesProvider);

        final favs2 = container.read(favoritesProvider);
        expect(favs2, hasLength(1));

        container.dispose();
      },
    );

    test(
      'multiple refreshes within same container do NOT throw',
      () async {
        final repo = _MockRestaurantRepository();
        repo.data = [_restaurant(id: 1, name: 'Sushi')];

        final visitRepo = _MockVisitRepository();
        visitRepo.data = [
          _visit(restaurantId: 1),
          _visit(restaurantId: 1),
        ];

        final container = ProviderContainer(
          overrides: _overrides(repo, visitRepo),
        );

        await _awaitDataReady(container);

        for (var i = 0; i < 3; i++) {
          // Each refresh re-calls build() on the same notifier.
          expect(
            () => container.refresh(favoritesProvider),
            returnsNormally,
            reason: 'refresh $i',
          );

          final favs = container.read(favoritesProvider);
          expect(favs, hasLength(1), reason: 'refresh $i');
        }

        container.dispose();
      },
    );

    test(
      'togglePin works after refresh in same container',
      () async {
        final repo = _MockRestaurantRepository();
        repo.data = [_restaurant(id: 1, name: 'Tacos')..isPinned = false];

        final visitRepo = _MockVisitRepository();
        visitRepo.data = [
          _visit(restaurantId: 1),
          _visit(restaurantId: 1),
        ];

        final container = ProviderContainer(
          overrides: _overrides(repo, visitRepo),
        );

        await _awaitDataReady(container);

        // Initial read.
        expect(
          container.read(favoritesProvider),
          hasLength(1),
        );

        // Refresh — triggers rebuild of notifier.
        container.refresh(favoritesProvider);

        // togglePin uses the late _restaurants field — should work after refresh.
        await container.read(favoritesProvider.notifier).togglePin(1);

        container.dispose();
      },
    );

    test(
      'refresh + refresh works after dispose/recreate',
      () async {
        final repo = _MockRestaurantRepository();
        repo.data = [_restaurant(id: 1, name: 'Burger')];

        final visitRepo = _MockVisitRepository();
        visitRepo.data = [
          _visit(restaurantId: 1),
          _visit(restaurantId: 1),
        ];

        // First lifecycle.
        final container1 = ProviderContainer(
          overrides: _overrides(repo, visitRepo),
        );

        await _awaitDataReady(container1);
        container1.read(favoritesProvider);
        container1.dispose();

        // Recreate — multiple refreshes in new lifecycle.
        final container2 = ProviderContainer(
          overrides: _overrides(repo, visitRepo),
        );

        await _awaitDataReady(container2);

        // First refresh should work.
        expect(
          () => container2.refresh(favoritesProvider),
          returnsNormally,
        );

        // Second refresh should also work (no late re-init crash).
        expect(
          () => container2.refresh(favoritesProvider),
          returnsNormally,
        );

        final notifier = container2.read(favoritesProvider.notifier);
        expect(() => notifier.refresh(), returnsNormally);

        container2.dispose();
      },
    );
  });
}
