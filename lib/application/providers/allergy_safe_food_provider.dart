/// Riverpod providers for per-restaurant allergy-safe food management.
///
/// Provides a repository singleton (overridable in tests) and an async notifier
/// that manages all [AllergySafeFood] records. The UI filters by restaurantId.
///
/// P4ME-14 / S06 — Allergy-Safe Database.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/allergy_safe_food_repository.dart';
import 'package:plated4me/infrastructure/storage/isar_storage.dart';

// -- Repository provider (overridable for testing) ---------------------------

/// Provider for the [AllergySafeFoodRepository] implementation.
final Provider<AllergySafeFoodRepository> allergySafeFoodRepositoryProvider =
    Provider<AllergySafeFoodRepository>(
      (_) => IsarAllergySafeFoodRepository(),
      name: 'allergySafeFoodRepository',
    );

// -- Data provider -----------------------------------------------------------

/// Notifier that manages all [AllergySafeFood] records.
class AllergySafeFoodsNotifier extends AsyncNotifier<List<AllergySafeFood>> {
  late final AllergySafeFoodRepository _repository;

  @override
  Future<List<AllergySafeFood>> build() {
    _repository = ref.read(allergySafeFoodRepositoryProvider);
    return fetchAll();
  }

  /// Loads all safe foods.
  Future<List<AllergySafeFood>> fetchAll() async {
    return _repository.getAllSafeFoods();
  }

  /// Saves a new safe food for the given [restaurantId] and refreshes.
  Future<void> addSafeFood(String itemName, int restaurantId) async {
    try {
      final food = AllergySafeFood(
        itemName: itemName,
        restaurantId: restaurantId,
      );
      await _repository.saveSafeFood(food);
      state = AsyncData(await fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a safe food by ID and refreshes.
  Future<void> removeSafeFood(Id id) async {
    try {
      await _repository.deleteSafeFood(id);
      state = AsyncData(await fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider for allergy-safe foods.
final AsyncNotifierProvider<AllergySafeFoodsNotifier, List<AllergySafeFood>>
allergySafeFoodsProvider =
    AsyncNotifierProvider<AllergySafeFoodsNotifier, List<AllergySafeFood>>(
      () => AllergySafeFoodsNotifier(),
      name: 'allergySafeFoods',
    );
