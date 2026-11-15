/// Repository interface for [Visit] entities.
///
/// Defines the contract for persisting and querying visit records,
/// including stream-based queries and full-text search (AC-2, P4ME-24).
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';

abstract class VisitRepository {
  /// Returns all visits in the database, ordered by creation date descending.
  Future<List<Visit>> getAllVisits();

  /// Returns a single visit by its auto-increment ID.
  ///
  /// Returns `null` if no visit with the given [id] exists.
  Future<Visit?> getVisitById(Id id);

  /// Returns visits for a specific restaurant, ordered by date descending.
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId);

  /// Inserts or updates a visit (including sub-collections).
  Future<Visit> saveVisit(Visit visit);

  /// Deletes a visit by its ID.
  ///
  /// Returns `true` if a record was deleted, `false` if not found.
  Future<bool> deleteVisit(Id id);

  /// Returns visits within a date range, ordered by date descending.
  Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to);

  /// Streams all visits, emitting the current list and updates on changes.
  ///
  /// This provides real-time reactive data flow for UI components (AC-2).
  Stream<List<Visit>> visitStream();

  /// Full-text search across visit content (journal entries, notes, dish names).
  ///
  /// Returns visits matching the query text, ordered by relevance.
  /// Empty queries return an empty list (AC-2).
  Future<List<Visit>> searchVisits(String query);

  /// Bulk deletes all blacklisted visits.
  ///
  /// Used by the Settings screen's "Clear all blacklisted visits" action (AC-6).
  /// Returns the number of visits deleted.
  Future<int> bulkDeleteBlacklistedVisits();
}
