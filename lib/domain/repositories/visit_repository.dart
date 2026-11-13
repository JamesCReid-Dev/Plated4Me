/// Repository interface for [Visit] entities.
///
/// Defines the contract for persisting and querying visit records,
/// including their associated sub-collections (journal entries, line items,
/// photos, and allergy-safe food logs).
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';

abstract class VisitRepository {
  /// Returns all visits in the database, ordered by [createdAt] descending.
  Future<List<Visit>> getAllVisits();

  /// Returns a single visit by its auto-increment ID.
  ///
  /// Returns `null` if no visit with the given [id] exists.
  Future<Visit?> getVisitById(Id id);

  /// Returns all visits for a specific restaurant.
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId);

  /// Inserts or updates a visit and its sub-collections.
  ///
  /// The [visit] must have all required rating fields set. Sub-collections
  /// ([journalEntries], [lineItems], [photos], [allergySafeFoods]) are saved
  /// atomically alongside the parent visit.
  Future<Visit> saveVisit(Visit visit);

  /// Deletes a visit and all its associated sub-collection records by ID.
  ///
  /// Returns `true` if a record was deleted, `false` if not found.
  Future<bool> deleteVisit(Id id);

  /// Returns visits within a date range (inclusive).
  Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to);
}
