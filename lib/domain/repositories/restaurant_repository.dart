/// Repository interface for [Restaurant] entities.
///
/// Defines the contract for persisting and querying restaurant records.
/// Implementations use Isar as the backing store.
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';

abstract class RestaurantRepository {
  /// Returns all restaurants in the database.
  Future<List<Restaurant>> getAllRestaurants();

  /// Returns a single restaurant by its auto-increment ID.
  ///
  /// Returns `null` if no restaurant with the given [id] exists.
  Future<Restaurant?> getRestaurantById(Id id);

  /// Searches restaurants by name (case-insensitive partial match).
  Future<List<Restaurant>> searchRestaurants(String query);

  /// Inserts or updates a restaurant.
  ///
  /// Returns the saved restaurant with its assigned ID.
  Future<Restaurant> saveRestaurant(Restaurant restaurant);

  /// Deletes a restaurant by its ID.
  ///
  /// Returns `true` if a record was deleted, `false` if not found.
  Future<bool> deleteRestaurant(Id id);

  /// Checks whether a restaurant with the given [name] already exists.
  Future<bool> existsByName(String name);
}
