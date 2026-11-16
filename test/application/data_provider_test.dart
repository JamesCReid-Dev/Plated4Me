/// Application layer tests for Riverpod provider wrappers around repositories.
///
/// Covers AC-4 of P4ME-24:
///   All repositories wrapped in `AsyncNotifierProvider`s using Riverpod (AD-3).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';
import 'package:plated4me/application/providers/data_providers.dart';

// -- Mock repositories for provider testing ------------------------------------

class MockRestaurantRepository implements RestaurantRepository {
  List<Restaurant> data = [];
  bool throwOnSave = false;
  int saveCallCount = 0;

  @override
  Future<List<Restaurant>> getAllRestaurants() async => data;

  @override
  Future<Restaurant?> getRestaurantById(int id) async {
    try {
      return data.firstWhere((r) => r.id == id, orElse: () => throw ArgumentError());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    if (query.trim().isEmpty) return [];
    return data.where((r) => r.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<Restaurant> saveRestaurant(Restaurant restaurant) async {
    saveCallCount++;
    if (throwOnSave) throw Exception('Save failed');
    final idx = data.indexWhere((r) => r.id == restaurant.id);
    if (idx >= 0) {
      data[idx] = restaurant;
    } else {
      data.add(restaurant);
    }
    return restaurant;
  }

  @override
  Future<bool> deleteRestaurant(int id) async {
    final idx = data.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      data.removeAt(idx);
      return true;
    }
    return false;
  }

  @override
  Future<bool> existsByName(String name) async => data.any((r) => r.name == name);

  @override
  Future<Restaurant?> getByNamedAddress(String name, String? address) async {
    try {
      return data.firstWhere(
        (r) => r.name == name && r.address == address,
        orElse: () => throw ArgumentError(),
      );
    } catch (_) {
      return null;
    }
  }
}

class MockVisitRepository implements VisitRepository {
  List<Visit> data = [];
  bool throwOnSave = false;
  final controllers = <StreamController<List<Visit>>>[];

  @override
  Future<List<Visit>> getAllVisits() async => data;

  @override
  Future<Visit?> getVisitById(int id) async {
    try {
      return data.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async {
    return data.where((v) => v.restaurantId == restaurantId).toList();
  }

  @override
  Future<Visit> saveVisit(Visit visit) async {
    if (throwOnSave) throw Exception('Save failed');
    final idx = data.indexWhere((v) => v.id == visit.id);
    if (idx >= 0) {
      data[idx] = visit;
    } else {
      data.add(visit);
    }
    return visit;
  }

  @override
  Future<bool> deleteVisit(int id) async {
    final idx = data.indexWhere((v) => v.id == id);
    if (idx >= 0) {
      data.removeAt(idx);
      return true;
    }
    return false;
  }

  @override
  Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to) async {
    return data.where((v) => v.createdAt.isAfter(from) && v.createdAt.isBefore(to)).toList();
  }

  @override
  Stream<List<Visit>> visitStream() {
    final controller = StreamController<List<Visit>>.broadcast();
    controllers.add(controller);
    controller.add(data);
    return controller.stream;
  }

  @override
  Future<List<Visit>> searchVisits(String query) async {
    if (query.trim().isEmpty) return [];
    final trimmed = query.toLowerCase();
    return data.where((v) {
      for (final entry in v.journalEntries) {
        if (entry.dishName.toLowerCase().contains(trimmed)) return true;
      }
      if (v.generalNotes != null && v.generalNotes!.toLowerCase().contains(trimmed)) return true;
      return false;
    }).toList();
  }

  @override
  Future<int> bulkDeleteBlacklistedVisits() async {
    final blacklistedIds = data.where((v) => v.blacklisted).map((v) => v.id).toList();
    if (blacklistedIds.isEmpty) return 0;
    data.removeWhere((v) => blacklistedIds.contains(v.id));
    return blacklistedIds.length;
  }
}

class MockUserPreferencesRepository implements UserPreferencesRepository {
  UserPreferences? stored;
  bool throwOnGet = false;

  @override
  Future<UserPreferences> getUserPreferences() async {
    if (throwOnGet) throw Exception('Get failed');
    stored ??= UserPreferences();
    return stored!;
  }

  @override
  Future<UserPreferences> saveUserPreferences(UserPreferences preferences) async {
    stored = preferences;
    return preferences;
  }

  @override
  Future<bool> hasPreferences() async => stored != null;
}

// -- AC-4: Provider wrapper tests ----------------------------------------------

void main() {
  group('AC-4 — RestaurantDataProvider provider', () {
    test('provides loaded data when repository returns restaurants', () async {
      final mockRepo = MockRestaurantRepository();
      mockRepo.data = [
        Restaurant(name: 'Pizza Place'),
        Restaurant(name: 'Sushi Bar'),
      ];

      final container = ProviderContainer(
        overrides: [
          restaurantRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      // Wait for the initial load to complete.
      await container.read(restaurantDataProvider.future);
      final state = container.read(restaurantDataProvider);

      expect(state, isA<AsyncData<List<Restaurant>>>());
      expect((state as AsyncData).value, hasLength(2));
      expect((state as AsyncData).value[0].name, equals('Pizza Place'));
      container.dispose();
    });

    test('provides empty list when no restaurants exist', () async {
      final mockRepo = MockRestaurantRepository();

      final container = ProviderContainer(
        overrides: [
          restaurantRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(restaurantDataProvider.future);
      final state = container.read(restaurantDataProvider);

      expect(state, isA<AsyncData<List<Restaurant>>>());
      expect((state as AsyncData).value, isEmpty);
      container.dispose();
    });

    test('refresh() reloads data from repository', () async {
      final mockRepo = MockRestaurantRepository();
      mockRepo.data = [Restaurant(name: 'Initial')];

      final container = ProviderContainer(
        overrides: [
          restaurantRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(restaurantDataProvider.future);
      expect((container.read(restaurantDataProvider) as AsyncData).value, hasLength(1));

      // Add a new restaurant and refresh.
      mockRepo.data.add(Restaurant(name: 'New Place'));
      final provider = container.read(restaurantDataProvider.notifier);
      await provider.refresh();

      expect((container.read(restaurantDataProvider) as AsyncData).value, hasLength(2));
      container.dispose();
    });

    test('saveRestaurant() saves and refreshes the list', () async {
      final mockRepo = MockRestaurantRepository();
      mockRepo.data.add(Restaurant(name: 'Existing')..id = 1);

      final container = ProviderContainer(
        overrides: [
          restaurantRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(restaurantDataProvider.future);
      expect((container.read(restaurantDataProvider) as AsyncData).value, hasLength(1));

      final provider = container.read(restaurantDataProvider.notifier);
      await provider.saveRestaurant(Restaurant(name: 'New Place')..id = 2);

      expect(mockRepo.saveCallCount, equals(1));
      expect((container.read(restaurantDataProvider) as AsyncData).value, hasLength(2));
      container.dispose();
    });

    test('deleteRestaurant() removes and refreshes the list', () async {
      final mockRepo = MockRestaurantRepository();
      await mockRepo.saveRestaurant(Restaurant(name: 'To Delete'));

      final container = ProviderContainer(
        overrides: [
          restaurantRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(restaurantDataProvider.future);
      expect((container.read(restaurantDataProvider) as AsyncData).value, hasLength(1));

      final provider = container.read(restaurantDataProvider.notifier);
      // Find the ID of the saved restaurant.
      final id = mockRepo.data.first.id;
      await provider.deleteRestaurant(id);

      expect((container.read(restaurantDataProvider) as AsyncData).value, isEmpty);
      container.dispose();
    });

    test('provides error state when repository throws', () async {
      final mockRepo = MockRestaurantRepository()..throwOnSave = true;

      final container = ProviderContainer(
        overrides: [
          restaurantRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      // Initial load succeeds (empty list).
      await container.read(restaurantDataProvider.future);
      expect(container.read(restaurantDataProvider), isA<AsyncData<List<Restaurant>>>());

      final provider = container.read(restaurantDataProvider.notifier);
      await provider.saveRestaurant(Restaurant(name: 'Should Fail'));

      // After failed save, state should be error.
      final state = container.read(restaurantDataProvider);
      expect(state, isA<AsyncError<Object?>>());
      container.dispose();
    });
  });

  group('AC-4 — VisitDataProvider provider', () {
    test('provides loaded data when repository returns visits', () async {
      final mockRepo = MockVisitRepository();
      mockRepo.data = [
        Visit(restaurantId: 1, foodRating: 5.0, valueRating: 4.0, serviceRating: 5.0, overallRating: 5.0, compositeScore: 4.75, returnIntent: true),
      ];

      final container = ProviderContainer(
        overrides: [
          visitRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(visitsDataProvider.future);
      final state = container.read(visitsDataProvider);

      expect(state, isA<AsyncData<List<Visit>>>());
      expect((state as AsyncData).value, hasLength(1));
      container.dispose();
    });

    test('saveVisit() saves and refreshes the list', () async {
      final mockRepo = MockVisitRepository();

      final container = ProviderContainer(
        overrides: [
          visitRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(visitsDataProvider.future);
      expect((container.read(visitsDataProvider) as AsyncData).value, isEmpty);

      final provider = container.read(visitsDataProvider.notifier);
      await provider.saveVisit(Visit(
        restaurantId: 1, foodRating: 4.0, valueRating: 3.5, serviceRating: 4.5, overallRating: 4.0, compositeScore: 3.95, returnIntent: true,
      ));

      expect((container.read(visitsDataProvider) as AsyncData).value, hasLength(1));
      container.dispose();
    });

    test('deleteVisit() removes and refreshes the list', () async {
      final mockRepo = MockVisitRepository();
      final visit = Visit(restaurantId: 1, foodRating: 4.0, valueRating: 3.5, serviceRating: 4.5, overallRating: 4.0, compositeScore: 3.95, returnIntent: true);
      await mockRepo.saveVisit(visit);

      final container = ProviderContainer(
        overrides: [
          visitRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(visitsDataProvider.future);
      expect((container.read(visitsDataProvider) as AsyncData).value, hasLength(1));

      final provider = container.read(visitsDataProvider.notifier);
      await provider.deleteVisit(visit.id);

      expect((container.read(visitsDataProvider) as AsyncData).value, isEmpty);
      container.dispose();
    });

    test('provides error state when repository throws', () async {
      final mockRepo = MockVisitRepository()..throwOnSave = true;

      final container = ProviderContainer(
        overrides: [
          visitRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(visitsDataProvider.future);
      expect(container.read(visitsDataProvider), isA<AsyncData<List<Visit>>>());

      final provider = container.read(visitsDataProvider.notifier);
      await provider.saveVisit(Visit(restaurantId: 1, foodRating: 5.0, valueRating: 4.0, serviceRating: 5.0, overallRating: 5.0, compositeScore: 4.75, returnIntent: true));

      final state = container.read(visitsDataProvider);
      expect(state, isA<AsyncError<Object?>>());
      container.dispose();
    });
  });

  group('AC-4 — UserPreferencesDataProvider provider', () {
    test('provides loaded preferences on init', () async {
      final mockRepo = MockUserPreferencesRepository();

      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(userPreferencesDataProvider.future);
      final state = container.read(userPreferencesDataProvider);

      expect(state, isA<AsyncData<UserPreferences>>());
      expect((state as AsyncData).value.onboardingComplete, isFalse);
      container.dispose();
    });

    test('savePreferences() updates provider state', () async {
      final mockRepo = MockUserPreferencesRepository();

      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(userPreferencesDataProvider.future);
      expect((container.read(userPreferencesDataProvider) as AsyncData).value.ratingScale, equals(5));

      final provider = container.read(userPreferencesDataProvider.notifier);
      final prefs = UserPreferences()..ratingScale = 10;
      await provider.savePreferences(prefs);

      expect((container.read(userPreferencesDataProvider) as AsyncData).value.ratingScale, equals(10));
      container.dispose();
    });

    test('completeOnboarding() sets onboardingComplete to true', () async {
      final mockRepo = MockUserPreferencesRepository();

      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      await container.read(userPreferencesDataProvider.future);
      expect((container.read(userPreferencesDataProvider) as AsyncData).value.onboardingComplete, isFalse);

      final provider = container.read(userPreferencesDataProvider.notifier);
      await provider.completeOnboarding();

      expect((container.read(userPreferencesDataProvider) as AsyncData).value.onboardingComplete, isTrue);
      container.dispose();
    });

    test('provides error state when repository throws', () async {
      final mockRepo = MockUserPreferencesRepository()..throwOnGet = true;

      final container = ProviderContainer(
        overrides: [
          userPreferencesRepositoryProvider.overrideWith((_) => mockRepo),
        ],
      );

      // Initial load should fail.
      await expectLater(container.read(userPreferencesDataProvider.future), throwsA(isA<Exception>()));
      final state = container.read(userPreferencesDataProvider);
      expect(state, isA<AsyncError<Object?>>());
      container.dispose();
    });
  });
}
