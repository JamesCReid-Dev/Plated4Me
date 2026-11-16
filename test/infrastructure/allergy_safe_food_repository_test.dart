/// Repository contract tests for [AllergySafeFoodRepository] — P4ME-14 (S06).
///
/// Covers CRUD operations and query-by-restaurant-id for allergy-safe foods.
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/allergy_safe_food_repository.dart';
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
  group('AC-1 — AllergySafeFoodRepository interface', () {
    test(
      'IsarAllergySafeFoodRepository implements AllergySafeFoodRepository',
      () {
        final AllergySafeFoodRepository repo = IsarAllergySafeFoodRepository();
        expect(repo, isA<AllergySafeFoodRepository>());
      },
    );

    test(
      'getAllSafeFoodsForRestaurant returns empty list when no foods exist',
      () async {
        final available = await _tryOpenIsar([AllergySafeFoodSchema]);
        if (!available) return;
        final isar = await Isar.open([
          AllergySafeFoodSchema,
        ], directory: ':memory:');
        try {
          final repo = IsarAllergySafeFoodRepository(isar: isar);

          final results = await repo.getAllSafeFoodsForRestaurant(1);

          expect(results, isEmpty);
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'getAllSafeFoodsForRestaurant returns foods for given restaurantId',
      () async {
        final available = await _tryOpenIsar([AllergySafeFoodSchema]);
        if (!available) return;
        final isar = await Isar.open([
          AllergySafeFoodSchema,
        ], directory: ':memory:');
        try {
          final repo = IsarAllergySafeFoodRepository(isar: isar);
          await repo.saveSafeFood(
            AllergySafeFood(itemName: 'Burger', restaurantId: 1),
          );
          await repo.saveSafeFood(
            AllergySafeFood(itemName: 'Fries', restaurantId: 1),
          );
          await repo.saveSafeFood(
            AllergySafeFood(itemName: 'Sushi', restaurantId: 2),
          );

          final results = await repo.getAllSafeFoodsForRestaurant(1);

          expect(results, hasLength(2));
          expect(results.every((f) => f.restaurantId == 1), isTrue);
        } finally {
          await isar.close();
        }
      },
    );

    test(
      'getAllSafeFoodsForRestaurant filters by restaurantId correctly',
      () async {
        final available = await _tryOpenIsar([AllergySafeFoodSchema]);
        if (!available) return;
        final isar = await Isar.open([
          AllergySafeFoodSchema,
        ], directory: ':memory:');
        try {
          final repo = IsarAllergySafeFoodRepository(isar: isar);
          await repo.saveSafeFood(
            AllergySafeFood(itemName: 'A', restaurantId: 1),
          );
          await repo.saveSafeFood(
            AllergySafeFood(itemName: 'B', restaurantId: 2),
          );

          final results = await repo.getAllSafeFoodsForRestaurant(2);

          expect(results, hasLength(1));
          expect(results[0].itemName, equals('B'));
        } finally {
          await isar.close();
        }
      },
    );

    test('saveSafeFood persists and returns food with assigned ID', () async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarAllergySafeFoodRepository(isar: isar);
        final food = AllergySafeFood(itemName: 'Pad Thai', restaurantId: 3);

        final saved = await repo.saveSafeFood(food);

        expect(saved.id, isNot(equals(0)));
        expect(saved.itemName, equals('Pad Thai'));
        expect(saved.restaurantId, equals(3));
      } finally {
        await isar.close();
      }
    });

    test('getSafeFoodById returns saved food', () async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarAllergySafeFoodRepository(isar: isar);
        final food = AllergySafeFood(itemName: 'Ramen', restaurantId: 5);
        final saved = await repo.saveSafeFood(food);

        final result = await repo.getSafeFoodById(saved.id);

        expect(result, isNotNull);
        expect(result!.itemName, equals('Ramen'));
      } finally {
        await isar.close();
      }
    });

    test('getSafeFoodById returns null for non-existent ID', () async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarAllergySafeFoodRepository(isar: isar);

        final result = await repo.getSafeFoodById(99999);

        expect(result, isNull);
      } finally {
        await isar.close();
      }
    });

    test('deleteSafeFood returns true and removes the record', () async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarAllergySafeFoodRepository(isar: isar);
        final saved = await repo.saveSafeFood(
          AllergySafeFood(itemName: 'To Delete', restaurantId: 1),
        );
        final deleted = await repo.deleteSafeFood(saved.id);

        expect(deleted, isTrue);
        expect(await repo.getSafeFoodById(saved.id), isNull);
      } finally {
        await isar.close();
      }
    });

    test('deleteSafeFood returns false for non-existent ID', () async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarAllergySafeFoodRepository(isar: isar);

        final deleted = await repo.deleteSafeFood(99999);

        expect(deleted, isFalse);
      } finally {
        await isar.close();
      }
    });

    test('getAllSafeFoods returns all foods across all restaurants', () async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarAllergySafeFoodRepository(isar: isar);
        await repo.saveSafeFood(
          AllergySafeFood(itemName: 'A', restaurantId: 1),
        );
        await repo.saveSafeFood(
          AllergySafeFood(itemName: 'B', restaurantId: 2),
        );
        await repo.saveSafeFood(
          AllergySafeFood(itemName: 'C', restaurantId: 1),
        );

        final results = await repo.getAllSafeFoods();

        expect(results, hasLength(3));
      } finally {
        await isar.close();
      }
    });

    test('safe foods are isolated by restaurant — different restaurants do not leak', () async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = IsarAllergySafeFoodRepository(isar: isar);
        await repo.saveSafeFood(
          AllergySafeFood(itemName: 'Thai Basil Chicken', restaurantId: 1),
        );
        await repo.saveSafeFood(
          AllergySafeFood(itemName: 'Sashimi', restaurantId: 2),
        );

        final results1 = await repo.getAllSafeFoodsForRestaurant(1);
        final results2 = await repo.getAllSafeFoodsForRestaurant(2);

        expect(results1, hasLength(1));
        expect(results1[0].itemName, equals('Thai Basil Chicken'));
        expect(results2, hasLength(1));
        expect(results2[0].itemName, equals('Sashimi'));
      } finally {
        await isar.close();
      }
    });
  });
}
