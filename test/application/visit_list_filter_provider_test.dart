/// Application layer tests for filtered visit list provider.
///
/// TDD Red Phase for P4ME-17 — S10 Filterable Visit Card List.
/// All tests MUST fail because [VisitListFilterProvider] does not yet exist.
///
/// Coverage: AC-2 (default sort), AC-3 (filter sheet), AC-4 (filter options),
/// AC-5 (apply filters), AC-6 (clear all filters), AC-7 (active filter badge).

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';

// -- Mock repositories (mirrors test/application/data_provider_test.dart) ----

class _MockVisitRepository implements VisitRepository {
  final List<Visit> _visits = [];

  @override
  Future<List<Visit>> getAllVisits() async => List.unmodifiable(_visits);

  @override
  Future<Visit?> getVisitById(int id) async {
    try {
      return _visits.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async {
    return _visits.where((v) => v.restaurantId == restaurantId).toList();
  }

  @override
  Future<Visit> saveVisit(Visit visit) async {
    final idx = _visits.indexWhere((v) => v.id == visit.id);
    if (idx >= 0) {
      _visits[idx] = visit;
    } else {
      _visits.add(visit);
    }
    return visit;
  }

  @override
  Future<bool> deleteVisit(int id) async {
    final idx = _visits.indexWhere((v) => v.id == id);
    if (idx >= 0) {
      _visits.removeAt(idx);
      return true;
    }
    return false;
  }

  @override
  Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to) async {
    return _visits.where((v) =>
        v.createdAt.isAfter(from) && v.createdAt.isBefore(to)).toList();
  }

  @override
  Stream<List<Visit>> visitStream() {
    throw UnimplementedError('Not used by VisitListFilterProvider');
  }

  @override
  Future<List<Visit>> searchVisits(String query) async => [];

  @override
  Future<int> bulkDeleteBlacklistedVisits() async => 0;
}

class _MockRestaurantRepository implements RestaurantRepository {
  final List<Restaurant> _restaurants = [];

  @override
  Future<List<Restaurant>> getAllRestaurants() async =>
      List.unmodifiable(_restaurants);

  @override
  Future<Restaurant?> getRestaurantById(int id) async {
    try {
      return _restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async => [];

  @override
  Future<Restaurant> saveRestaurant(Restaurant restaurant) async {
    final idx = _restaurants.indexWhere((r) => r.id == restaurant.id);
    if (idx >= 0) {
      _restaurants[idx] = restaurant;
    } else {
      _restaurants.add(restaurant);
    }
    return restaurant;
  }

  @override
  Future<bool> deleteRestaurant(int id) async {
    final idx = _restaurants.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      _restaurants.removeAt(idx);
      return true;
    }
    return false;
  }

  @override
  Future<bool> existsByName(String name) async =>
      _restaurants.any((r) => r.name == name);

  @override
  Future<Restaurant?> getByNamedAddress(String name, String? address) async {
    try {
      return _restaurants.firstWhere(
        (r) => r.name == name && r.address == address,
        orElse: () => throw ArgumentError(),
      );
    } catch (_) {
      return null;
    }
  }
}

class _MockUserPreferencesRepository implements UserPreferencesRepository {
  final UserPreferences _prefs;
  _MockUserPreferencesRepository(this._prefs);

  @override
  Future<UserPreferences> getUserPreferences() async => _prefs;

  @override
  Future<UserPreferences> saveUserPreferences(
    UserPreferences preferences,
  ) async {
    return preferences;
  }

  @override
  Future<bool> hasPreferences() async => true;
}

// -- Test data helpers --------------------------------------------------------

Visit _makeVisit({
  required int restaurantId,
  required double compositeScore,
  required DateTime createdAt,
  bool returnIntent = false,
  List<String>? occasions,
  bool blacklisted = false,
  int? id,
}) {
  final v = Visit(
    restaurantId: restaurantId,
    foodRating: 4.0,
    valueRating: 3.5,
    serviceRating: 4.0,
    overallRating: 4.5,
    compositeScore: compositeScore,
    returnIntent: returnIntent,
  );
  v.id = id ?? restaurantId;
  v.createdAt = createdAt;
  v.updatedAt = createdAt;
  v.blacklisted = blacklisted;
  if (occasions != null) v.occasions.addAll(occasions);
  return v;
}

Restaurant _makeRestaurant({required String name, int? id}) {
  return Restaurant(name: name)..id = id ?? 0;
}

// -- Tests --------------------------------------------------------------------

void main() {
  group('P4ME-17 — VisitListFilterProvider', () {
    // AC-2: Default sort is most recent first.
    test(
      'AC-2 — default state returns visits sorted by createdAt descending',
      () async {
        final mockVisitRepo = _MockVisitRepository();
        final mockRestaurantRepo = _MockRestaurantRepository();

        await mockVisitRepo.saveVisit(_makeVisit(
          restaurantId: 1,
          compositeScore: 70.0,
          createdAt: DateTime(2025, 1, 1),
        ));
        await mockVisitRepo.saveVisit(_makeVisit(
          restaurantId: 2,
          compositeScore: 90.0,
          createdAt: DateTime(2025, 6, 1),
        ));
        await mockVisitRepo.saveVisit(_makeVisit(
          restaurantId: 3,
          compositeScore: 50.0,
          createdAt: DateTime(2025, 3, 1),
        ));

        // Also save matching restaurants so visits can be joined.
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place A')..id = 1);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place B')..id = 2);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place C')..id = 3);

        final container = ProviderContainer(overrides: [
          visitsListFilterProvider.overrideWith(() => VisitListFilterNotifier.withRepos(mockVisitRepo, mockRestaurantRepo)),
        ]);

        // Wait for async initialization.
        await container.read(visitsListFilterProvider.future);
        final state = container.read(visitsListFilterProvider);

        if (state is AsyncError) {
          fail('Provider returned error: ${state.error}');
        }

        expect(state, isA<AsyncData<List<FilteredVisit>>>());
        final visits = (state as AsyncData).value;
        expect(visits.length, equals(3));
        // Most recent first.
        expect(visits[0].visit.restaurantId, equals(2));
        expect(visits[1].visit.restaurantId, equals(3));
        expect(visits[2].visit.restaurantId, equals(1));

        container.dispose();
      },
    );

    // AC-4: Filter by cuisine type.
    test(
      'AC-4 — filterByCuisine returns only visits whose restaurant matches',
      () async {
        final mockVisitRepo = _MockVisitRepository();
        final mockRestaurantRepo = _MockRestaurantRepository();

        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Sushi Place')..id = 1);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Pizza Place')..id = 2);

        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1)));
        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 2, compositeScore: 70.0, createdAt: DateTime(2025, 5, 1)));

        final container = ProviderContainer(overrides: [
          visitsListFilterProvider.overrideWith(() => VisitListFilterNotifier.withRepos(mockVisitRepo, mockRestaurantRepo)),
        ]);

        await container.read(visitsListFilterProvider.future);
        final provider = container.read(visitsListFilterProvider.notifier);

        await provider.setFilterCriteria(cuisineType: 'Sushi');

        final state = container.read(visitsListFilterProvider);
        expect(state, isA<AsyncData<List<FilteredVisit>>>());
        final filtered = (state as AsyncData).value;
        expect(filtered.length, equals(1));
        expect(filtered[0].restaurant.name, equals('Sushi Place'));

        container.dispose();
      },
    );

    // AC-4: Filter by rating range.
    test(
      'AC-4 — filterByRatingRange returns visits within score bounds',
      () async {
        final mockVisitRepo = _MockVisitRepository();
        final mockRestaurantRepo = _MockRestaurantRepository();

        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 1, compositeScore: 85.0, createdAt: DateTime(2025, 6, 1), id: 1));
        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 2, compositeScore: 55.0, createdAt: DateTime(2025, 5, 1), id: 2));
        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 3, compositeScore: 70.0, createdAt: DateTime(2025, 4, 1), id: 3));

        // Also save matching restaurants so visits can be joined.
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place A')..id = 1);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place B')..id = 2);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place C')..id = 3);

        final container = ProviderContainer(overrides: [
          visitsListFilterProvider.overrideWith(() => VisitListFilterNotifier.withRepos(mockVisitRepo, mockRestaurantRepo)),
        ]);

        await container.read(visitsListFilterProvider.future);
        final provider = container.read(visitsListFilterProvider.notifier);

        await provider.setFilterCriteria(minRating: 60.0, maxRating: 80.0);

        final state = container.read(visitsListFilterProvider);
        final filtered = (state as AsyncData).value;
        expect(filtered.length, equals(1));
        expect(filtered[0].visit.compositeScore, equals(70.0));

        container.dispose();
      },
    );

    // AC-4: Filter by occasion tag.
    test(
      'AC-4 — filterByOccasion returns only visits with matching occasion',
      () async {
        final mockVisitRepo = _MockVisitRepository();
        final mockRestaurantRepo = _MockRestaurantRepository();

        final visit1 = _makeVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1), id: 1);
        visit1.occasions.add('Date Night');
        await mockVisitRepo.saveVisit(visit1);

        final visit2 = _makeVisit(restaurantId: 2, compositeScore: 70.0, createdAt: DateTime(2025, 5, 1), id: 2);
        visit2.occasions.add('Business Lunch');
        await mockVisitRepo.saveVisit(visit2);

        // Also save matching restaurants so visits can be joined.
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place A')..id = 1);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place B')..id = 2);

        final container = ProviderContainer(overrides: [
          visitsListFilterProvider.overrideWith(() => VisitListFilterNotifier.withRepos(mockVisitRepo, mockRestaurantRepo)),
        ]);

        await container.read(visitsListFilterProvider.future);
        final provider = container.read(visitsListFilterProvider.notifier);

        await provider.setFilterCriteria(occasionTag: 'Date Night');

        final state = container.read(visitsListFilterProvider);
        final filtered = (state as AsyncData).value;
        expect(filtered.length, equals(1));
        expect(filtered[0].visit.occasions, contains('Date Night'));

        container.dispose();
      },
    );

    // AC-4: Filter by allergy-safe status.
    test(
      'AC-4 — filterByAllergySafe returns only visits to allergy-safe restaurants',
      () async {
        final mockVisitRepo = _MockVisitRepository();
        final mockRestaurantRepo = _MockRestaurantRepository();
        final mockPrefsRepo = _MockUserPreferencesRepository(
          UserPreferences(allergies: [Allergen(name: 'Shellfish')]),
        );

        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Safe Place')..id = 1);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Unsafe Place')..id = 2);

        // Note: The provider should use the allergy_safe_food_repository to check this.
        // For now, we test that the filter returns only visits whose restaurants have safe foods recorded.

        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1)));
        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 2, compositeScore: 70.0, createdAt: DateTime(2025, 5, 1)));

        final container = ProviderContainer(
          overrides: [
            visitRepositoryProvider.overrideWith((_) => mockVisitRepo),
            restaurantRepositoryProvider.overrideWith((_) => mockRestaurantRepo),
            userPreferencesRepositoryProvider.overrideWith((_) => mockPrefsRepo),
          ],
        );

        await container.read(visitsListFilterProvider.future);
        final provider = container.read(visitsListFilterProvider.notifier);

        await provider.setFilterCriteria(allergySafeOnly: true);

        final state = container.read(visitsListFilterProvider);
        final filtered = (state as AsyncData).value;
        // Should only include visits to restaurants with allergy-safe foods.
        expect(filtered.length, lessThanOrEqualTo(1));

        container.dispose();
      },
    );

    // AC-5: Multiple filters combine correctly.
    test(
      'AC-5 — multiple filters combine (AND logic)',
      () async {
        final mockVisitRepo = _MockVisitRepository();
        final mockRestaurantRepo = _MockRestaurantRepository();

        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Sushi Place')..id = 1);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Pizza Place')..id = 2);

        final visit1 = _makeVisit(restaurantId: 1, compositeScore: 85.0, createdAt: DateTime(2025, 6, 1), id: 1);
        visit1.occasions.add('Date Night');
        await mockVisitRepo.saveVisit(visit1);

        final visit2 = _makeVisit(restaurantId: 1, compositeScore: 55.0, createdAt: DateTime(2025, 5, 1), id: 2);
        visit2.occasions.add('Quick Bite');
        await mockVisitRepo.saveVisit(visit2);

        final visit3 = _makeVisit(restaurantId: 2, compositeScore: 80.0, createdAt: DateTime(2025, 4, 1), id: 3);
        visit3.occasions.add('Date Night');
        await mockVisitRepo.saveVisit(visit3);

        final container = ProviderContainer(overrides: [
          visitsListFilterProvider.overrideWith(() => VisitListFilterNotifier.withRepos(mockVisitRepo, mockRestaurantRepo)),
        ]);

        await container.read(visitsListFilterProvider.future);
        final provider = container.read(visitsListFilterProvider.notifier);

        // Filter: cuisine=Sushi, rating 60-100, occasion=Date Night.
        await provider.setFilterCriteria(
          cuisineType: 'Sushi',
          minRating: 60.0,
          maxRating: 100.0,
          occasionTag: 'Date Night',
        );

        final state = container.read(visitsListFilterProvider);
        final filtered = (state as AsyncData).value;
        expect(filtered.length, equals(1));
        expect(filtered[0].restaurant.name, equals('Sushi Place'));
        expect(filtered[0].visit.compositeScore, equals(85.0));

        container.dispose();
      },
    );

    // AC-6: Clear all filters resets to unfiltered view.
    test(
      'AC-6 — clearAllFilters resets to full unfiltered list',
      () async {
        final mockVisitRepo = _MockVisitRepository();
        final mockRestaurantRepo = _MockRestaurantRepository();

        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1), id: 1));
        await mockVisitRepo.saveVisit(_makeVisit(restaurantId: 2, compositeScore: 70.0, createdAt: DateTime(2025, 5, 1), id: 2));

        // Also save matching restaurants so visits can be joined.
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place A')..id = 1);
        await mockRestaurantRepo.saveRestaurant(_makeRestaurant(name: 'Place B')..id = 2);

        final container = ProviderContainer(overrides: [
          visitsListFilterProvider.overrideWith(() => VisitListFilterNotifier.withRepos(mockVisitRepo, mockRestaurantRepo)),
        ]);

        await container.read(visitsListFilterProvider.future);
        final provider = container.read(visitsListFilterProvider.notifier);

        // Apply a filter.
        await provider.setFilterCriteria(cuisineType: 'Sushi');

        // Clear all filters.
        await provider.clearAllFilters();

        final state = container.read(visitsListFilterProvider);
        final visits = (state as AsyncData).value;
        expect(visits.length, equals(2));

        container.dispose();
      },
    );

    // AC-7: Active filter badge — hasActiveFilters returns true when filters set.
    test(
      'AC-7 — hasActiveFilters returns true when any filter is applied',
      () async {
        final mockVisitRepo = _MockVisitRepository();
        final mockRestaurantRepo = _MockRestaurantRepository();

        final container = ProviderContainer(overrides: [
          visitsListFilterProvider.overrideWith(() => VisitListFilterNotifier.withRepos(mockVisitRepo, mockRestaurantRepo)),
        ]);

        await container.read(visitsListFilterProvider.future);
        final provider = container.read(visitsListFilterProvider.notifier);

        // Initially no active filters.
        expect(provider.hasActiveFilters, isFalse);

        // Apply a filter.
        await provider.setFilterCriteria(cuisineType: 'Sushi');
        expect(provider.hasActiveFilters, isTrue);

        // Clear all filters.
        await provider.clearAllFilters();
        expect(provider.hasActiveFilters, isFalse);

        container.dispose();
      },
    );
  });
}
