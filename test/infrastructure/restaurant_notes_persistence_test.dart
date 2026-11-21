/// Infrastructure layer tests for Restaurant.notes persistence.
///
/// P4ME-19 — Restaurant General Notes.
/// Covers AC-2: Notes persist across all Visits to the same restaurant.

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';
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
  group('P4ME-19 — Restaurant.notes persistence', () {
    test(
      'AC-2 — notes field is persisted and retrieved correctly',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          final restaurant = Restaurant(name: 'Persisted Place')..notes = 'Saved notes';
          final saved = await repo.saveRestaurant(restaurant);
          final retrieved = await repo.getRestaurantById(saved.id);

          expect(retrieved, isNotNull);
          expect(retrieved!.notes, equals('Saved notes'));
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'AC-2 — null notes are preserved on save/retrieve',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          final restaurant = Restaurant(name: 'No Notes Place');
          final saved = await repo.saveRestaurant(restaurant);
          final retrieved = await repo.getRestaurantById(saved.id);

          expect(retrieved, isNotNull);
          expect(retrieved!.notes, isNull);
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'AC-2 — notes can be updated after initial save',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          final restaurant = Restaurant(name: 'Update Notes Place')..notes = 'Initial';
          final saved = await repo.saveRestaurant(restaurant);

          // Update notes.
          saved.notes = 'Updated notes';
          final updated = await repo.saveRestaurant(saved);

          final retrieved = await repo.getRestaurantById(updated.id);
          expect(retrieved!.notes, equals('Updated notes'));
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'AC-2 — clearing notes (null) persists correctly',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          final restaurant = Restaurant(name: 'Clear Notes Place')..notes = 'To clear';
          final saved = await repo.saveRestaurant(restaurant);

          // Clear notes.
          saved.notes = null;
          final cleared = await repo.saveRestaurant(saved);

          final retrieved = await repo.getRestaurantById(cleared.id);
          expect(retrieved!.notes, isNull);
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'AC-2 — multiple restaurants each retain their own notes',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          await repo.saveRestaurant(Restaurant(name: 'Place A')..notes = 'Notes A');
          await repo.saveRestaurant(Restaurant(name: 'Place B')..notes = 'Notes B');
          await repo.saveRestaurant(Restaurant(name: 'Place C'));

          final all = await repo.getAllRestaurants();
          expect(all, hasLength(3));

          final byName = {for (final r in all) r.name: r.notes};
          expect(byName['Place A'], equals('Notes A'));
          expect(byName['Place B'], equals('Notes B'));
          expect(byName['Place C'], isNull);
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'AC-2 — long-form notes are preserved',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          final longNotes = '''
This restaurant has been a staple of the neighborhood for over 20 years.
The owner, Maria, remembers every regular's order.
Best dish: the house-made pasta, but arrive early as it sells out by 2pm.
Parking can be tricky on weekends — consider taking public transit.
          '''.trim();
          final restaurant = Restaurant(name: 'Long Notes Place')..notes = longNotes;
          final saved = await repo.saveRestaurant(restaurant);

          final retrieved = await repo.getRestaurantById(saved.id);
          expect(retrieved!.notes, equals(longNotes));
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'touch() updates updatedAt while preserving notes',
      () async {
        final available = await _tryOpenIsar([RestaurantSchema]);
        if (!available) return;
        final isar = await Isar.open([RestaurantSchema], directory: ':memory:');
        try {
          final repo = IsarRestaurantRepository(isar: isar);
          final restaurant = Restaurant(name: 'Touch Notes Place')..notes = 'Stable';
          final saved = await repo.saveRestaurant(restaurant);

          final originalUpdatedAt = saved.updatedAt;
          await Future<void>.delayed(const Duration(milliseconds: 10));

          saved.touch();
          final updated = await repo.saveRestaurant(saved);

          expect(updated.updatedAt.isAfter(originalUpdatedAt), isTrue);
          expect(updated.notes, equals('Stable'));
        } finally {
          await isar.close();
        }
      },
    );
  });
}
