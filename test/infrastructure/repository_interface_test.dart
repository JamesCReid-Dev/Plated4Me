/// Repository interface contract tests.
///
/// Covers AC-1, AC-2, AC-3 of P4ME-24:
///   AC-1: RestaurantRepository interface with CRUD + lookup by (name, address) tuple
///   AC-2: VisitRepository interface with CRUD + query streams + FTS search wrapper
///   AC-3: UserPreferencesRepository with get/set and existence check for onboarding gate
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/repositories.dart';
import 'package:plated4me/infrastructure/storage/isar_storage.dart';

/// Tries to open a test Isar database. Returns false if native libraries
/// aren't available (i.e., running in pure VM without a Flutter device).
Future<bool> _tryOpenIsar(List<CollectionSchema<dynamic>> schemas) async {
  try {
    final isar = await Isar.open(schemas, directory: ':memory:');
    await isar.close();
    return true;
  } catch (e) {
    if (e.toString().contains('libisar') ||
        e.toString().contains('Failed to load dynamic library')) {
      return false;
    }
    rethrow;
  }
}

void main() {
  // -- AC-1: RestaurantRepository interface contract ---------------------------

  group('AC-1 — RestaurantRepository interface', () {
    test('IsarRestaurantRepository implements RestaurantRepository', () {
      final RestaurantRepository repo = IsarRestaurantRepository();
      expect(repo, isA<RestaurantRepository>());
    });

    test(
      'getByNamedAddress finds restaurant by exact name and address',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) {
          // SKIPPED: Isar native library not available — run on a device/simulator
          return;
        }
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          await repo.saveRestaurant(
            Restaurant(name: 'Joe\'s Pizza', address: '123 Main St'),
          );
          await repo.saveRestaurant(
            Restaurant(name: 'Joe\'s Pizza', address: '456 Oak Ave'),
          );

          final result = await repo.getByNamedAddress(
            'Joe\'s Pizza',
            '123 Main St',
          );

          expect(result, isNotNull);
          expect(result!.name, equals('Joe\'s Pizza'));
          expect(result.address, equals('123 Main St'));
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'getByNamedAddress returns null when name+address tuple not found',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          await repo.saveRestaurant(
            Restaurant(name: 'Joe\'s Pizza', address: '123 Main St'),
          );

          final result = await repo.getByNamedAddress(
            'Joe\'s Pizza',
            '999 Unknown',
          );

          expect(result, isNull);
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'getByNamedAddress distinguishes same name different address',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          await repo.saveRestaurant(
            Restaurant(name: 'Thai Garden', address: '100 First St'),
          );
          await repo.saveRestaurant(
            Restaurant(name: 'Thai Garden', address: '200 Second St'),
          );

          final result1 = await repo.getByNamedAddress(
            'Thai Garden',
            '100 First St',
          );
          final result2 = await repo.getByNamedAddress(
            'Thai Garden',
            '200 Second St',
          );

          expect(result1, isNotNull);
          expect(result2, isNotNull);
          expect(result1!.id, isNot(equals(result2!.id)));
        } finally {
          await isar.close();
        }
      },
    );

    test('getByNamedAddress handles null address correctly', () async {
      final available = await _tryOpenIsar([RestaurantSchema]);
      if (!available) return;
      final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
      try {
        final repo = IsarRestaurantRepository(isar: isar);
        await repo.saveRestaurant(Restaurant(name: 'Food Truck'));

        final result = await repo.getByNamedAddress('Food Truck', null);

        expect(result, isNotNull);
        expect(result!.address, isNull);
      } finally {
        await isar.close();
      }
    });

    test('getByNamedAddress returns null for non-existent name', () async {
      final available = await _tryOpenIsar([RestaurantSchema]);
      if (!available) return;
      final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
      try {
        final repo = IsarRestaurantRepository(isar: isar);
        await repo.saveRestaurant(Restaurant(name: 'Existing Place'));

        final result = await repo.getByNamedAddress('Nowhere', '123 St');

        expect(result, isNull);
      } finally {
        await isar.close();
      }
    });

    test('getAllRestaurants returns all saved restaurants', () async {
      final available = await _tryOpenIsar([RestaurantSchema]);
      if (!available) return;
      final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
      try {
        final repo = IsarRestaurantRepository(isar: isar);
        await repo.saveRestaurant(Restaurant(name: 'A'));
        await repo.saveRestaurant(Restaurant(name: 'B'));
        await repo.saveRestaurant(Restaurant(name: 'C'));

        final results = await repo.getAllRestaurants();

        expect(results, hasLength(3));
      } finally {
        await isar.close();
      }
    });

    test('deleteRestaurant returns true and removes the record', () async {
      final available = await _tryOpenIsar([RestaurantSchema]);
      if (!available) return;
      final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
      try {
        final repo = IsarRestaurantRepository(isar: isar);
        final saved = await repo.saveRestaurant(Restaurant(name: 'To Delete'));
        final deleted = await repo.deleteRestaurant(saved.id);

        expect(deleted, isTrue);
        expect(await repo.getRestaurantById(saved.id), isNull);
      } finally {
        await isar.close();
      }
    });

    test('deleteRestaurant returns false for non-existent ID', () async {
      final available = await _tryOpenIsar([RestaurantSchema]);
      if (!available) return;
      final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
      try {
        final repo = IsarRestaurantRepository(isar: isar);
        final deleted = await repo.deleteRestaurant(99999);
        expect(deleted, isFalse);
      } finally {
        await isar.close();
      }
    });
  });

  // -- AC-2: VisitRepository interface contract --------------------------------

  group('AC-2 — VisitRepository interface', () {
    test('IsarVisitRepository implements VisitRepository', () {
      final VisitRepository repo = IsarVisitRepository();
      expect(repo, isA<VisitRepository>());
    });

    test('visitStream emits current visits on subscription', () async {
      final available = await _tryOpenIsar([RestaurantSchema, VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([
        RestaurantSchema,
        VisitSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);
        var emittedCount = 0;
        late List<Visit> lastEmitted;

        final subscription = repo.visitStream().listen((visits) {
          emittedCount++;
          lastEmitted = visits;
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));

        await repo.saveVisit(
          Visit(
            restaurantId: 1,
            foodRating: 4.0,
            valueRating: 3.5,
            serviceRating: 4.5,
            overallRating: 4.0,
            compositeScore: 3.95,
            returnIntent: true,
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(emittedCount, greaterThanOrEqualTo(2));
        expect(lastEmitted, isNotEmpty);
      } finally {
        await isar.close();
      }
    });

    test('visitStream emits empty list when no visits exist', () async {
      final available = await _tryOpenIsar([VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([VisitSchema], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);
        late List<Visit> lastEmitted;

        final subscription = repo.visitStream().listen((visits) {
          lastEmitted = visits;
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        expect(lastEmitted, isEmpty);
      } finally {
        await isar.close();
      }
    });

    test(
      'searchVisits finds visits by journal entry dish name (FTS)',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema, VisitSchema]);
        if (!available) return;
        final isar = await Isar.open([
          RestaurantSchema,
          VisitSchema,
        ], directory: ':memory:');
        try {
          final repo = IsarVisitRepository(isar: isar);
          final visit =
              Visit(
                  restaurantId: 1,
                  foodRating: 5.0,
                  valueRating: 4.0,
                  serviceRating: 5.0,
                  overallRating: 5.0,
                  compositeScore: 4.75,
                  returnIntent: true,
                )
                ..journalEntries = [
                  JournalEntry(dishName: 'Pad Thai', impressions: 'Amazing'),
                ];
          await repo.saveVisit(visit);

          final results = await repo.searchVisits('Pad Thai');

          expect(results, isNotEmpty);
        } finally {
          await isar.close();
        }
      },
    );

    test('searchVisits finds visits by general notes text (FTS)', () async {
      final available = await _tryOpenIsar([RestaurantSchema, VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([
        RestaurantSchema,
        VisitSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);
        final visit = Visit(
          restaurantId: 1,
          foodRating: 3.0,
          valueRating: 3.0,
          serviceRating: 3.0,
          overallRating: 3.0,
          compositeScore: 3.15,
          returnIntent: false,
        )..generalNotes = 'Great atmosphere and friendly staff';
        await repo.saveVisit(visit);

        final results = await repo.searchVisits('atmosphere');

        expect(results, isNotEmpty);
      } finally {
        await isar.close();
      }
    });

    test('searchVisits returns empty list for non-matching query', () async {
      final available = await _tryOpenIsar([RestaurantSchema, VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([
        RestaurantSchema,
        VisitSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);
        final visit = Visit(
          restaurantId: 1,
          foodRating: 4.0,
          valueRating: 4.0,
          serviceRating: 4.0,
          overallRating: 4.0,
          compositeScore: 3.95,
          returnIntent: true,
        )..generalNotes = 'Italian restaurant';
        await repo.saveVisit(visit);

        final results = await repo.searchVisits('sushi');

        expect(results, isEmpty);
      } finally {
        await isar.close();
      }
    });

    test('searchVisits handles empty query gracefully', () async {
      final available = await _tryOpenIsar([RestaurantSchema, VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([
        RestaurantSchema,
        VisitSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);
        await repo.saveVisit(
          Visit(
            restaurantId: 1,
            foodRating: 4.0,
            valueRating: 4.0,
            serviceRating: 4.0,
            overallRating: 4.0,
            compositeScore: 3.95,
            returnIntent: true,
          ),
        );

        final results = await repo.searchVisits('');

        expect(results, isEmpty);
      } finally {
        await isar.close();
      }
    });

    test('getVisitsByRestaurantId filters correctly', () async {
      final available = await _tryOpenIsar([VisitSchema]);
      if (!available) return;
      final isar = await Isar.open([VisitSchema], directory: ':memory:');
      try {
        final repo = IsarVisitRepository(isar: isar);
        await repo.saveVisit(
          Visit(
            restaurantId: 1,
            foodRating: 4.0,
            valueRating: 3.5,
            serviceRating: 4.5,
            overallRating: 4.0,
            compositeScore: 3.95,
            returnIntent: true,
          ),
        );
        await repo.saveVisit(
          Visit(
            restaurantId: 2,
            foodRating: 3.0,
            valueRating: 3.0,
            serviceRating: 3.0,
            overallRating: 3.0,
            compositeScore: 3.15,
            returnIntent: false,
          ),
        );

        final results = await repo.getVisitsByRestaurantId(1);

        expect(results, hasLength(1));
        expect(results[0].restaurantId, equals(1));
      } finally {
        await isar.close();
      }
    });
  });

  // -- AC-3: UserPreferencesRepository interface contract ----------------------

  group('AC-3 — UserPreferencesRepository interface', () {
    test(
      'IsarUserPreferencesRepository implements UserPreferencesRepository',
      () {
        final UserPreferencesRepository repo = IsarUserPreferencesRepository();
        expect(repo, isA<UserPreferencesRepository>());
      },
    );

    test('hasPreferences returns false when no preferences exist', () async {
      final available = await _tryOpenIsar([UserPreferencesSchema]);
      if (!available) return;
      final isar = await Isar.open([
        UserPreferencesSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarUserPreferencesRepository(isar: isar);
        final hasPrefs = await repo.hasPreferences();
        expect(hasPrefs, isFalse);
      } finally {
        await isar.close();
      }
    });

    test('hasPreferences returns true after preferences are saved', () async {
      final available = await _tryOpenIsar([UserPreferencesSchema]);
      if (!available) return;
      final isar = await Isar.open([
        UserPreferencesSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarUserPreferencesRepository(isar: isar);
        await repo.saveUserPreferences(UserPreferences());

        final hasPrefs = await repo.hasPreferences();
        expect(hasPrefs, isTrue);
      } finally {
        await isar.close();
      }
    });

    test(
      'getUserPreferences creates default if none exist (lazy init)',
      () async {
        final available = await _tryOpenIsar([UserPreferencesSchema]);
        if (!available) return;
        final isar = await Isar.open([
          UserPreferencesSchema,
        ], directory: ':memory:');
        try {
          final repo = IsarUserPreferencesRepository(isar: isar);
          final prefs = await repo.getUserPreferences();

          expect(prefs, isA<UserPreferences>());
          expect(prefs.onboardingComplete, isFalse);
          expect(prefs.ratingScale, equals(5));
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'saveUserPreferences persists and returns updated preferences',
      () async {
        final available = await _tryOpenIsar([UserPreferencesSchema]);
        if (!available) return;
        final isar = await Isar.open([
          UserPreferencesSchema,
        ], directory: ':memory:');
        try {
          final repo = IsarUserPreferencesRepository(isar: isar);
          final prefs = UserPreferences()
            ..ratingScale = 10
            ..cuisinePreferences.addAll(['Italian', 'Japanese'])
            ..allergies.add(Allergen(name: 'Peanuts', severity: 1));

          final saved = await repo.saveUserPreferences(prefs);

          expect(saved.ratingScale, equals(10));
          expect(saved.cuisinePreferences, contains('Italian'));
          expect(saved.allergies, hasLength(1));
          expect(saved.allergies[0].name, equals('Peanuts'));
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'getUserPreferences returns existing preferences without creating new',
      () async {
        final available = await _tryOpenIsar([UserPreferencesSchema]);
        if (!available) return;
        final isar = await Isar.open([
          UserPreferencesSchema,
        ], directory: ':memory:');
        try {
          final repo = IsarUserPreferencesRepository(isar: isar);
          await repo.saveUserPreferences(
            UserPreferences()..onboardingComplete = true,
          );

          final fetched = await repo.getUserPreferences();

          expect(fetched.onboardingComplete, isTrue);
        } finally {
          await isar.close();
        }
      },
    );

    test('hasPreferences gates onboarding correctly', () async {
      final available = await _tryOpenIsar([UserPreferencesSchema]);
      if (!available) return;
      final isar = await Isar.open([
        UserPreferencesSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarUserPreferencesRepository(isar: isar);

        expect(await repo.hasPreferences(), isFalse);

        await repo.saveUserPreferences(UserPreferences());
        expect(await repo.hasPreferences(), isTrue);
      } finally {
        await isar.close();
      }
    });
  });
}
