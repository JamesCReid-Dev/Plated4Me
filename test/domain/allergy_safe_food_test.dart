/// Unit tests for [AllergySafeFood] entity — P4ME-14 (S06).
///
/// Verifies the new `restaurantId` foreign key field and its defaults.
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';

void main() {
  group('AllergySafeFood — P4ME-14', () {
    test('can be created with itemName only (restaurantId defaults to 0)', () {
      final safe = AllergySafeFood(itemName: 'Grilled Chicken');

      expect(safe.itemName, equals('Grilled Chicken'));
      expect(safe.restaurantId, equals(0));
      expect(safe.createdAt, isNotNull);
    });

    test('can be created with itemName and restaurantId', () {
      final safe = AllergySafeFood(itemName: 'Pad Thai', restaurantId: 42);

      expect(safe.itemName, equals('Pad Thai'));
      expect(safe.restaurantId, equals(42));
    });

    test('copyWith updates itemName and preserves restaurantId', () {
      final original = AllergySafeFood(itemName: 'Chicken', restaurantId: 7);
      final updated = original.copyWith(itemName: 'Turkey');

      expect(updated.itemName, equals('Turkey'));
      expect(updated.restaurantId, equals(7)); // preserved
    });

    test('copyWith updates restaurantId', () {
      final original = AllergySafeFood(itemName: 'Sushi', restaurantId: 1);
      final updated = original.copyWith(restaurantId: 99);

      expect(updated.itemName, equals('Sushi'));
      expect(updated.restaurantId, equals(99));
    });

    test('toString includes itemName and restaurantId', () {
      final safe = AllergySafeFood(itemName: 'Burger', restaurantId: 5);

      final str = safe.toString();
      expect(str, contains('Burger'));
      expect(str, contains('5'));
    });
  });
}
