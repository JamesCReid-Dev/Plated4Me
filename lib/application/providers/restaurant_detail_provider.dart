/// Riverpod providers for restaurant detail data.
///
/// Provides repository singletons (overridable in tests) and an async notifier
/// that manages a single [Restaurant] by ID with its visits and allergy-safe foods.
///
/// P4ME-22 — S15 Restaurant Detail View.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/allergy_safe_food_repository.dart';
import 'package:plated4me/domain/repositories/restaurant_repository.dart';
import 'package:plated4me/domain/repositories/visit_repository.dart';
import 'package:plated4me/infrastructure/storage/isar_storage.dart';

// -- Repository providers (overridable for testing) ----------------------------

/// Provider for the [RestaurantRepository] implementation.
final Provider<RestaurantRepository> restaurantDetailRepositoryProvider =
    Provider<RestaurantRepository>(
      (_) => IsarRestaurantRepository(),
      name: 'restaurantDetailRepository',
    );

/// Provider for the [VisitRepository] implementation.
final Provider<VisitRepository> visitDetailRepositoryProvider =
    Provider<VisitRepository>(
      (_) => IsarVisitRepository(),
      name: 'visitDetailRepository',
    );

/// Provider for the [AllergySafeFoodRepository] implementation.
final Provider<AllergySafeFoodRepository> allergySafeFoodDetailRepositoryProvider =
    Provider<AllergySafeFoodRepository>(
      (_) => IsarAllergySafeFoodRepository(),
      name: 'allergySafeFoodDetailRepository',
    );

// -- Data model ----------------------------------------------------------------

/// Joined restaurant detail data for display in [RestaurantDetailScreen].
class RestaurantDetailData {
  final Restaurant restaurant;
  final List<Visit> visits;
  final List<AllergySafeFood> allergySafeFoods;

  const RestaurantDetailData({
    required this.restaurant,
    required this.visits,
    required this.allergySafeFoods,
  });
}

// -- Detail provider -----------------------------------------------------------

/// Notifier that loads a single restaurant's detail data by ID.
class RestaurantDetailNotifier
    extends AsyncNotifier<RestaurantDetailData?> {
  RestaurantRepository? _restaurantRepo;
  VisitRepository? _visitRepo;
  AllergySafeFoodRepository? _allergyRepo;

  @override
  Future<RestaurantDetailData?> build() async {
    _restaurantRepo = ref.read(restaurantDetailRepositoryProvider);
    _visitRepo = ref.read(visitDetailRepositoryProvider);
    _allergyRepo = ref.read(allergySafeFoodDetailRepositoryProvider);
    return null; // restaurantId set via refresh
  }

  /// Loads detail data for the given [restaurantId].
  Future<void> loadDetail(int restaurantId) async {
    final rRepo = _restaurantRepo!;
    final vRepo = _visitRepo!;
    final aRepo = _allergyRepo!;

    final restaurant = await rRepo.getRestaurantById(restaurantId);
    if (restaurant == null) {
      state = const AsyncData(null);
      return;
    }

    final visits = await vRepo.getVisitsByRestaurantId(restaurantId);
    final safeFoods = await aRepo.getAllSafeFoodsForRestaurant(restaurantId);

    // Sort visits by createdAt descending (most recent first).
    visits.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    state = AsyncData(
      RestaurantDetailData(
        restaurant: restaurant,
        visits: visits,
        allergySafeFoods: safeFoods,
      ),
    );
  }

  /// Updates the restaurant notes and refreshes.
  Future<void> updateNotes(String notes) async {
    if (state.value == null) return;
    final updated = state.value!.restaurant.copyWith(notes: notes);
    await _restaurantRepo!.saveRestaurant(updated);
    await loadDetail(updated.id);
  }

  /// Adds an allergy-safe food for the restaurant and refreshes.
  Future<void> addSafeFood(String itemName) async {
    if (state.value == null) return;
    final food = AllergySafeFood(
      itemName: itemName,
      restaurantId: state.value!.restaurant.id,
    );
    await _allergyRepo!.saveSafeFood(food);
    await loadDetail(state.value!.restaurant.id);
  }

  /// Removes an allergy-safe food by ID and refreshes.
  Future<void> removeSafeFood(int id) async {
    await _allergyRepo!.deleteSafeFood(id);
    if (state.value != null) {
      await loadDetail(state.value!.restaurant.id);
    }
  }
}

/// Provider for restaurant detail data.
final AsyncNotifierProvider<RestaurantDetailNotifier, RestaurantDetailData?>
    restaurantDetailProvider = AsyncNotifierProvider<
        RestaurantDetailNotifier, RestaurantDetailData?>(
  () => RestaurantDetailNotifier(),
  name: 'restaurantDetail',
);
