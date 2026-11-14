/// Riverpod providers for repository data access.
///
/// Each provider wraps a [RestaurantRepository], [VisitRepository], or
/// [UserPreferencesRepository] in an [AsyncNotifierProvider] so that UI
/// components can watch reactive data streams (AC-4, P4ME-24, AD-3).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';
import 'package:plated4me/infrastructure/storage/isar_storage.dart';

// -- Repository singleton providers --------------------------------------------

/// Singleton provider for the [RestaurantRepository] implementation.
final Provider<RestaurantRepository> restaurantRepositoryProvider = Provider<RestaurantRepository>(
    (_) => IsarRestaurantRepository(),
    name: 'restaurantRepository',
  );

/// Singleton provider for the [VisitRepository] implementation.
final Provider<VisitRepository> visitRepositoryProvider = Provider<VisitRepository>(
    (_) => IsarVisitRepository(),
    name: 'visitRepository',
  );

/// Singleton provider for the [UserPreferencesRepository] implementation.
final Provider<UserPreferencesRepository> userPreferencesRepositoryProvider = Provider<UserPreferencesRepository>(
    (_) => IsarUserPreferencesRepository(),
    name: 'userPreferencesRepository',
  );

// -- Data AsyncNotifierProviders -----------------------------------------------

/// Notifier that loads and manages the list of [Restaurant] records.
class RestaurantDataProvider extends AsyncNotifier<List<Restaurant>> {
  @override
  Future<List<Restaurant>> build() {
    _repository = ref.read(restaurantRepositoryProvider);
    return fetchAll();
  }

  late final RestaurantRepository _repository;

  /// Reloads all restaurants from the backing repository.
  Future<void> refresh() async {
    state = AsyncData(await fetchAll());
  }

  Future<List<Restaurant>> fetchAll() async {
    return _repository.getAllRestaurants();
  }

  /// Saves a restaurant and refreshes the list on success.
  Future<void> saveRestaurant(Restaurant restaurant) async {
    try {
      await _repository.saveRestaurant(restaurant);
      state = AsyncData(await fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a restaurant by ID and refreshes the list on success.
  Future<void> deleteRestaurant(Id id) async {
    try {
      await _repository.deleteRestaurant(id);
      state = AsyncData(await fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider for [Restaurant] data.
final AsyncNotifierProvider<RestaurantDataProvider, List<Restaurant>> restaurantDataProvider =
        AsyncNotifierProvider<RestaurantDataProvider, List<Restaurant>>(
            () => RestaurantDataProvider(),
            name: 'restaurantData',
          );

/// Notifier that loads and manages the list of [Visit] records.
class VisitDataProvider extends AsyncNotifier<List<Visit>> {
  @override
  Future<List<Visit>> build() {
    _repository = ref.read(visitRepositoryProvider);
    return fetchAll();
  }

  late final VisitRepository _repository;

  /// Reloads all visits from the backing repository.
  Future<void> refresh() async {
    state = AsyncData(await fetchAll());
  }

  Future<List<Visit>> fetchAll() async {
    return _repository.getAllVisits();
  }

  /// Saves a visit and refreshes the list on success.
  Future<void> saveVisit(Visit visit) async {
    try {
      await _repository.saveVisit(visit);
      state = AsyncData(await fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a visit by ID and refreshes the list on success.
  Future<void> deleteVisit(Id id) async {
    try {
      await _repository.deleteVisit(id);
      state = AsyncData(await fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider for [Visit] data.
final AsyncNotifierProvider<VisitDataProvider, List<Visit>> visitsDataProvider =
        AsyncNotifierProvider<VisitDataProvider, List<Visit>>(
            () => VisitDataProvider(),
            name: 'visitsData',
          );

/// Notifier that manages user preferences.
class UserPreferencesDataProvider
    extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() {
    _repository = ref.read(userPreferencesRepositoryProvider);
    return fetchPreferences();
  }

  late final UserPreferencesRepository _repository;

  /// Fetches preferences from the repository.
  Future<UserPreferences> fetchPreferences() async {
    return _repository.getUserPreferences();
  }

  /// Reloads preferences from the backing repository.
  Future<void> refresh() async {
    state = AsyncData(await fetchPreferences());
  }

  /// Saves updated preferences and refreshes the provider state.
  Future<void> savePreferences(UserPreferences preferences) async {
    try {
      final saved = await _repository.saveUserPreferences(preferences);
      state = AsyncData(saved);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Completes onboarding by updating the flag and refreshing.
  Future<void> completeOnboarding() async {
    try {
      final current = await fetchPreferences();
      final updated = current.copyWith(onboardingComplete: true);
      await savePreferences(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider for user preferences data.
final AsyncNotifierProvider<UserPreferencesDataProvider, UserPreferences> userPreferencesDataProvider =
        AsyncNotifierProvider<UserPreferencesDataProvider, UserPreferences>(
            () => UserPreferencesDataProvider(),
            name: 'userPreferencesData',
          );
