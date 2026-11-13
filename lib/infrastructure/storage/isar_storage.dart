/// Isar-backed repository implementations for all domain entities.
///
/// This file provides concrete implementations of [RestaurantRepository],
/// [VisitRepository], [UserPreferencesRepository], and [AllergenRepository]
/// using the global Isar instance from [package:plated4me/main.dart].
library;

import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';
import 'package:plated4me/main.dart' show isar;

// -- Restaurant Repository ---------------------------------------------------

/// Isar implementation of [RestaurantRepository].
class IsarRestaurantRepository implements RestaurantRepository {
  @override
  Future<List<Restaurant>> getAllRestaurants() async {
    return isar.restaurants.where().findAll();
  }

  @override
  Future<Restaurant?> getRestaurantById(Id id) async {
    return isar.restaurants.get(id);
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    if (query.trim().isEmpty) return [];
    return isar.restaurants.where().nameStartsWith(query.trim()).findAll();
  }

  @override
  Future<Restaurant> saveRestaurant(Restaurant restaurant) async {
    return isar.writeTxn(() async {
      restaurant.touch();
      await isar.restaurants.put(restaurant);
      return restaurant;
    });
  }

  @override
  Future<bool> deleteRestaurant(Id id) async {
    final existing = await isar.restaurants.get(id);
    if (existing == null) return false;
    await isar.writeTxn(() => isar.restaurants.delete(id));
    return true;
  }

  @override
  Future<bool> existsByName(String name) async {
    final results = await searchRestaurants(name);
    return results.isNotEmpty;
  }
}

// -- Visit Repository --------------------------------------------------------

/// Isar implementation of [VisitRepository].
class IsarVisitRepository implements VisitRepository {
  @override
  Future<List<Visit>> getAllVisits() async {
    return isar.visits.where().sortByCreatedAtDesc().findAll();
  }

  @override
  Future<Visit?> getVisitById(Id id) async {
    return isar.visits.get(id);
  }

  @override
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async {
    return isar.visits
        .where()
        .filter()
        .restaurantIdEqualTo(restaurantId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<Visit> saveVisit(Visit visit) async {
    await isar.writeTxn(() async {
      visit.touch();
      await isar.visits.put(visit);

      // Save sub-collection records, linking each to the parent visit.
      for (final entry in visit.journalEntries) {
        entry.id = Isar.autoIncrement;
        await isar.journalEntrys.put(entry);
      }
      for (final item in visit.lineItems) {
        item.id = Isar.autoIncrement;
        await isar.visitLineItems.put(item);
      }
      for (final photo in visit.photos) {
        photo.id = Isar.autoIncrement;
        await isar.photoAttachments.put(photo);
      }
      for (final food in visit.allergySafeFoods) {
        food.id = Isar.autoIncrement;
        await isar.allergySafeFoods.put(food);
      }
    });
    return visit;
  }

  @override
  Future<bool> deleteVisit(Id id) async {
    final existing = await isar.visits.get(id);
    if (existing == null) return false;
    await isar.writeTxn(() => isar.visits.delete(id));
    return true;
  }

  @override
  Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to) async {
    return isar.visits
        .where()
        .createdAtBetween(from, to)
        .sortByCreatedAtDesc()
        .findAll();
  }
}

// -- UserPreferences Repository ----------------------------------------------

/// Isar implementation of [UserPreferencesRepository].
class IsarUserPreferencesRepository implements UserPreferencesRepository {
  @override
  Future<UserPreferences> getUserPreferences() async {
    var prefs = await isar.userPreferences.get(1);
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
    preferences.id = 1;
    preferences.touch();
    await isar.writeTxn(() => isar.userPreferences.put(preferences));
    return preferences;
  }
}

// -- Allergen Repository -----------------------------------------------------

/// Isar implementation of [AllergenRepository].
class IsarAllergenRepository implements AllergenRepository {
  @override
  Future<List<Allergen>> getAllAllergens() async {
    return isar.allergens.where().findAll();
  }

  @override
  Future<Allergen?> getAllergenById(Id id) async {
    return isar.allergens.get(id);
  }

  @override
  Future<List<Allergen>> searchAllergens(String query) async {
    if (query.trim().isEmpty) return [];
    return isar.allergens.where().nameStartsWith(query.trim()).findAll();
  }

  @override
  Future<Allergen> saveAllergen(Allergen allergen) async {
    await isar.writeTxn(() {
      allergen.id = Isar.autoIncrement;
      return isar.allergens.put(allergen);
    });
    return allergen;
  }

  @override
  Future<bool> deleteAllergen(Id id) async {
    final existing = await isar.allergens.get(id);
    if (existing == null) return false;
    await isar.writeTxn(() => isar.allergens.delete(id));
    return true;
  }
}
