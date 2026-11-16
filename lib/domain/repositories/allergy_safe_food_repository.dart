/// Repository interface for [AllergySafeFood] entities.
///
/// Defines the contract for persisting and querying per-restaurant
/// allergy-safe food records (P4ME-14 / S06).
/// Implementations use Isar as the backing store.
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';

abstract class AllergySafeFoodRepository {
  /// Returns all allergy-safe foods in the database.
  Future<List<AllergySafeFood>> getAllSafeFoods();

  /// Returns all allergy-safe foods for a specific restaurant.
  ///
  /// Results are ordered by [createdAt] ascending (oldest first).
  Future<List<AllergySafeFood>> getAllSafeFoodsForRestaurant(int restaurantId);

  /// Returns a single allergy-safe food by its auto-increment ID.
  ///
  /// Returns `null` if no food with the given [id] exists.
  Future<AllergySafeFood?> getSafeFoodById(Id id);

  /// Inserts or updates an allergy-safe food.
  ///
  /// Returns the saved food with its assigned ID.
  Future<AllergySafeFood> saveSafeFood(AllergySafeFood food);

  /// Deletes an allergy-safe food by its ID.
  ///
  /// Returns `true` if a record was deleted, `false` if not found.
  Future<bool> deleteSafeFood(Id id);
}
