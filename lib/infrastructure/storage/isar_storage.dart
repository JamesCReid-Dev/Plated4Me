/// Isar-backed repository implementations for all domain entities.
///
/// This file provides concrete implementations of [RestaurantRepository],
/// [VisitRepository], [UserPreferencesRepository], and [AllergenRepository]
/// using the global Isar instance from [package:plated4me/main.dart].
library;

import 'dart:async';

import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';
import 'package:plated4me/infrastructure/storage/repository_exception.dart';
import 'package:plated4me/main.dart' show isar;

// -- Retry helper ------------------------------------------------------------

/// Maximum number of retry attempts for transient failures.
const int _kMaxRetries = 2;

/// Delay between retries in milliseconds (~500ms per AC-5).
const int _kRetryDelayMs = 500;

/// Executes [fn] with retry logic for recoverable errors.
///
/// Retries up to [_kMaxRetries] times with [_kRetryDelayMs]ms delay between attempts.
/// Throws [RepositoryException.recoverable] after exhausting retries on transient failures.
/// Re-throws [RepositoryException.unrecoverable] immediately without retry.
Future<T> _retryWithBackoff<T>(Future<T> Function() fn) async {
  Object? lastError;

  for (var attempt = 0; attempt <= _kMaxRetries; attempt++) {
    try {
      return await fn();
    } on RepositoryException catch (e) {
      if (!e.isRecoverable) rethrow; // Unrecoverable — no retry
      lastError = e;
      if (attempt < _kMaxRetries) {
        await Future<void>.delayed(const Duration(milliseconds: _kRetryDelayMs));
      }
    } catch (e) {
      // Treat unexpected errors as recoverable transient failures
      lastError = e;
      if (attempt < _kMaxRetries) {
        await Future<void>.delayed(const Duration(milliseconds: _kRetryDelayMs));
      }
    }
  }

  // All retries exhausted — wrap in recoverable exception
  throw RepositoryException.recoverable(
    'Operation failed after $_kMaxRetries retry attempts',
    error: lastError,
  );
}

// -- Restaurant Repository ---------------------------------------------------

/// Isar implementation of [RestaurantRepository].
class IsarRestaurantRepository implements RestaurantRepository {
  final Isar? _isar;

  /// Creates a repository using the global [isar] instance from main.dart.
  IsarRestaurantRepository({this._isar});

  Isar get _db => _isar ?? isar;

  @override
  Future<List<Restaurant>> getAllRestaurants() async {
    return _db.restaurants.where().findAll();
  }

  @override
  Future<Restaurant?> getRestaurantById(Id id) async {
    return _db.restaurants.get(id);
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    if (query.trim().isEmpty) return [];
    return _db.restaurants.where().nameStartsWith(query.trim()).findAll();
  }

  @override
  Future<Restaurant> saveRestaurant(Restaurant restaurant) async {
    return _retryWithBackoff(() async {
      return _db.writeTxn(() async {
        restaurant.touch();
        await _db.restaurants.put(restaurant);
        return restaurant;
      });
    });
  }

  @override
  Future<bool> deleteRestaurant(Id id) async {
    return _retryWithBackoff(() async {
      final existing = await _db.restaurants.get(id);
      if (existing == null) return false;
      await _db.writeTxn(() => _db.restaurants.delete(id));
      return true;
    });
  }

  @override
  Future<bool> existsByName(String name) async {
    final results = await searchRestaurants(name);
    return results.isNotEmpty;
  }

  @override
  Future<Restaurant?> getByNamedAddress(String name, String? address) async {
    final results = await _db.restaurants
        .where()
        .nameEqualTo(name)
        .findAll();

    for (final r in results) {
      if (r.address == address) {
        return r;
      }
    }
    return null;
  }
}

// -- Visit Repository --------------------------------------------------------

/// Isar implementation of [VisitRepository].
class IsarVisitRepository implements VisitRepository {
  final Isar? _isar;

  /// Creates a repository using the global [isar] instance from main.dart.
  IsarVisitRepository({this._isar});

  Isar get _db => _isar ?? isar;

  @override
  Future<List<Visit>> getAllVisits() async {
    return _db.visits.where().sortByCreatedAtDesc().findAll();
  }

  @override
  Future<Visit?> getVisitById(Id id) async {
    return _db.visits.get(id);
  }

  @override
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async {
    return _db.visits
        .where()
        .filter()
        .restaurantIdEqualTo(restaurantId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<Visit> saveVisit(Visit visit) async {
    return _retryWithBackoff(() async {
      await _db.writeTxn(() async {
        visit.touch();
        await _db.visits.put(visit);

        // Save sub-collection records, linking each to the parent visit.
        for (final entry in visit.journalEntries) {
          entry.id = Isar.autoIncrement;
          await _db.journalEntrys.put(entry);
        }
        for (final item in visit.lineItems) {
          item.id = Isar.autoIncrement;
          await _db.visitLineItems.put(item);
        }
        for (final photo in visit.photos) {
          photo.id = Isar.autoIncrement;
          await _db.photoAttachments.put(photo);
        }
        for (final food in visit.allergySafeFoods) {
          food.id = Isar.autoIncrement;
          await _db.allergySafeFoods.put(food);
        }
      });
      return visit;
    });
  }

  @override
  Future<bool> deleteVisit(Id id) async {
    return _retryWithBackoff(() async {
      final existing = await _db.visits.get(id);
      if (existing == null) return false;
      await _db.writeTxn(() => _db.visits.delete(id));
      return true;
    });
  }

  @override
  Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to) async {
    return _db.visits
        .where()
        .createdAtBetween(from, to)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Stream<List<Visit>> visitStream() {
    // Watch the visits collection for real-time updates.
    return _db.visits
        .where()
        .sortByCreatedAtDesc()
        .watch();
  }

  @override
  Future<List<Visit>> searchVisits(String query) async {
    if (query.trim().isEmpty) return [];

    final trimmed = query.trim();

    // Isar doesn't have built-in FTS, so we do a multi-pass search:
    // 1. Search journal entries by dish name
    // 2. Search general notes by text content
    final allVisits = await getAllVisits();
    final results = <Visit>[];

    for (final visit in allVisits) {
      // Check journal entry dish names
      for (final entry in visit.journalEntries) {
        if (entry.dishName.toLowerCase().contains(trimmed.toLowerCase())) {
          results.add(visit);
          break;
        }
      }
      // Check general notes
      if (results.contains(visit)) continue;
      if (visit.generalNotes != null &&
          visit.generalNotes!.toLowerCase().contains(trimmed.toLowerCase())) {
        results.add(visit);
      }
    }

    return results;
  }

  @override
  Future<int> bulkDeleteBlacklistedVisits() async {
    return _retryWithBackoff(() async {
      final allVisits = await getAllVisits();
      final blacklistedIds = <Id>[];
      for (final visit in allVisits) {
        if (visit.blacklisted) {
          blacklistedIds.add(visit.id);
        }
      }

      if (blacklistedIds.isEmpty) return 0;

      await _db.writeTxn(() async {
        for (final id in blacklistedIds) {
          await _db.visits.delete(id);
        }
      });

      return blacklistedIds.length;
    });
  }
}

// -- UserPreferences Repository ----------------------------------------------

/// Isar implementation of [UserPreferencesRepository].
class IsarUserPreferencesRepository implements UserPreferencesRepository {
  final Isar? _isar;

  /// Creates a repository using the global [isar] instance from main.dart.
  IsarUserPreferencesRepository({this._isar});

  Isar get _db => _isar ?? isar;

  @override
  Future<bool> hasPreferences() async {
    return await _db.userPreferences.get(1) != null;
  }

  @override
  Future<UserPreferences> getUserPreferences() async {
    var prefs = await _db.userPreferences.get(1);
    if (prefs == null) {
      prefs = UserPreferences();
      prefs.id = 1;
      await saveUserPreferences(prefs);
    }
    return prefs;
  }

  @override
  Future<UserPreferences> saveUserPreferences(
    UserPreferences preferences,
  ) async {
    return _retryWithBackoff(() async {
      preferences.id = 1;
      preferences.touch();
      await _db.writeTxn(() => _db.userPreferences.put(preferences));
      return preferences;
    });
  }
}

// -- Allergen Repository -----------------------------------------------------

/// Isar implementation of [AllergenRepository].
class IsarAllergenRepository implements AllergenRepository {
  final Isar? _isar;

  /// Creates a repository using the global [isar] instance from main.dart.
  IsarAllergenRepository({this._isar});

  Isar get _db => _isar ?? isar;

  @override
  Future<List<Allergen>> getAllAllergens() async {
    return _db.allergens.where().findAll();
  }

  @override
  Future<Allergen?> getAllergenById(Id id) async {
    return _db.allergens.get(id);
  }

  @override
  Future<List<Allergen>> searchAllergens(String query) async {
    if (query.trim().isEmpty) return [];
    return _db.allergens.where().nameStartsWith(query.trim()).findAll();
  }

  @override
  Future<Allergen> saveAllergen(Allergen allergen) async {
    await _db.writeTxn(() {
      allergen.id = Isar.autoIncrement;
      return _db.allergens.put(allergen);
    });
    return allergen;
  }

  @override
  Future<bool> deleteAllergen(Id id) async {
    final existing = await _db.allergens.get(id);
    if (existing == null) return false;
    await _db.writeTxn(() => _db.allergens.delete(id));
    return true;
  }
}
