/// Riverpod providers for the Favorites feature — P4ME-20 (S13).
///
/// Computes favorites on-demand from Visit history and Restaurant data,
/// with manual pin/unpin overrides persisted to the Restaurant entity.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/services/favorites_service.dart';
import 'package:plated4me/domain/entities/entities.dart';

/// Notifier that computes and manages the list of favorite restaurants.
///
/// Favorites are computed on-demand from Visit history (AC-2), not stored
/// as a separate entity. Manual pin/unpin overrides are persisted to the
/// Restaurant entity fields [Restaurant.isPinned] / [Restaurant.isUnpinned].
class FavoritesNotifier extends Notifier<List<Restaurant>> {
  late final RestaurantDataProvider _restaurants;

  @override
  List<Restaurant> build() {
    _restaurants = ref.read(restaurantDataProvider.notifier);

    // Watch restaurant data so favorites recompute when it changes.
    ref.watch(restaurantDataProvider);
    ref.watch(visitsDataProvider);

    return _computeFavorites();
  }

  List<Restaurant> _computeFavorites() {
    final restaurantsState = ref.read(restaurantDataProvider);
    final visitsState = ref.read(visitsDataProvider);

    // Handle async states — return empty if either is loading or errored.
    if (restaurantsState is! AsyncData || visitsState is! AsyncData) {
      return [];
    }

    final restaurants = (restaurantsState.value as List<Restaurant>).cast<Restaurant>();
    final visits = (visitsState.value as List<Visit>).cast<Visit>();

    return FavoritesService.computeFavorites(restaurants, visits);
  }

  /// Recomputes favorites from current data.
  void refresh() {
    state = _computeFavorites();
  }

  /// Toggles the pin state of a restaurant (AC-3).
  Future<void> togglePin(Id restaurantId) async {
    final restaurantsState = ref.read(restaurantDataProvider);
    if (restaurantsState is! AsyncData) return;

    final restaurants = (restaurantsState.value as List<Restaurant>).cast<Restaurant>();
    final index = restaurants.indexWhere((r) => r.id == restaurantId);
    if (index < 0) return;

    final restaurant = restaurants[index];
    // Toggle: pinned → not pinned, not pinned → pinned.
    final newRestaurant = Restaurant(
      name: restaurant.name,
      address: restaurant.address,
    )..id = restaurant.id;
    newRestaurant.isPinned = !restaurant.isPinned;
    newRestaurant.isUnpinned = false;

    await _restaurants.saveRestaurant(newRestaurant);
  }
}

/// Provider for the favorites list.
final NotifierProvider<FavoritesNotifier, List<Restaurant>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<Restaurant>>(
      () => FavoritesNotifier(),
      name: 'favorites',
    );
