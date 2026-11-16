/// Widget tests for the allergy-safe foods management screen — P4ME-14 (S06).
///
/// Verifies the UI renders the restaurant name, lists safe foods, and provides
/// an add input field.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/application/providers/allergy_safe_food_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/allergy_safe_food_repository.dart';
import 'package:plated4me/infrastructure/storage/isar_storage.dart';
import 'package:plated4me/presentation/allergy_safe_foods_screen.dart';

/// Creates a mock repository that delegates to an Isar-backed implementation.
AllergySafeFoodRepository _makeRepo(Isar isar) =>
    IsarAllergySafeFoodRepository(isar: isar);

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
  group('AC-3 — Allergy-safe foods screen', () {
    testWidgets('displays restaurant name in app bar', (tester) async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              overrides: [
                allergySafeFoodRepositoryProvider.overrideWithValue(
                  _makeRepo(isar),
                ),
              ],
              child: const AllergySafeFoodsScreen(restaurantId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Allergy-Safe Foods'), findsOneWidget);
      } finally {
        await isar.close();
      }
    });

    testWidgets('shows empty state when no foods exist', (tester) async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              overrides: [
                allergySafeFoodRepositoryProvider.overrideWithValue(
                  _makeRepo(isar),
                ),
              ],
              child: const AllergySafeFoodsScreen(restaurantId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show the add input field even when empty
        expect(find.byType(TextFormField), findsOneWidget);
      } finally {
        await isar.close();
      }
    });

    testWidgets('displays saved foods in a list', (tester) async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = _makeRepo(isar);
        await repo.saveSafeFood(
          AllergySafeFood(itemName: 'Grilled Chicken', restaurantId: 1),
        );
        await repo.saveSafeFood(
          AllergySafeFood(itemName: 'Rice', restaurantId: 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              overrides: [
                allergySafeFoodRepositoryProvider.overrideWithValue(
                  _makeRepo(isar),
                ),
              ],
              child: const AllergySafeFoodsScreen(restaurantId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Grilled Chicken'), findsOneWidget);
        expect(find.text('Rice'), findsOneWidget);
      } finally {
        await isar.close();
      }
    });

    testWidgets('adding a food name creates a new entry', (tester) async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              overrides: [
                allergySafeFoodRepositoryProvider.overrideWithValue(
                  _makeRepo(isar),
                ),
              ],
              child: const AllergySafeFoodsScreen(restaurantId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Type a new food name and submit
        await tester.enterText(find.byType(TextFormField), 'Pad Thai');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text('Pad Thai'), findsOneWidget);
      } finally {
        await isar.close();
      }
    });

    testWidgets('removing a food deletes it from the list', (tester) async {
      final available = await _tryOpenIsar([AllergySafeFoodSchema]);
      if (!available) return;
      final isar = await Isar.open([
        AllergySafeFoodSchema,
      ], directory: ':memory:');
      try {
        final repo = _makeRepo(isar);
        await repo.saveSafeFood(
          AllergySafeFood(itemName: 'Burger', restaurantId: 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              overrides: [
                allergySafeFoodRepositoryProvider.overrideWithValue(
                  _makeRepo(isar),
                ),
              ],
              child: const AllergySafeFoodsScreen(restaurantId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Burger'), findsOneWidget);

        // Tap the remove button (IconButton with tooltip "Remove")
        final removeFinder = find.byIcon(Icons.delete_outline).last;
        await tester.tap(removeFinder);
        await tester.pumpAndSettle();

        expect(find.text('Burger'), findsNothing);
      } finally {
        await isar.close();
      }
    });
  });
}
