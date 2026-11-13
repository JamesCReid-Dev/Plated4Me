/// Repository interface for [Allergen] entities.
///
/// Defines the contract for managing allergen records used in conjunction
/// with [UserPreferences.allergies].
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';

abstract class AllergenRepository {
  /// Returns all allergens in the database.
  Future<List<Allergen>> getAllAllergens();

  /// Returns a single allergen by its auto-increment ID.
  ///
  /// Returns `null` if no allergen with the given [id] exists.
  Future<Allergen?> getAllergenById(Id id);

  /// Searches allergens by name (case-insensitive partial match).
  Future<List<Allergen>> searchAllergens(String query);

  /// Inserts or updates an allergen.
  ///
  /// Returns the saved allergen with its assigned ID.
  Future<Allergen> saveAllergen(Allergen allergen);

  /// Deletes an allergen by its ID.
  ///
  /// Returns `true` if a record was deleted, `false` if not found.
  Future<bool> deleteAllergen(Id id);
}
