/// Domain layer tests for Restaurant.notes field.
///
/// P4ME-19 — Restaurant General Notes.
/// Covers AC-1: Editable free-text field at Restaurant level.

import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';

void main() {
  group('P4ME-19 — Restaurant.notes entity field', () {
    test(
      'AC-1 — Restaurant has a nullable notes field that defaults to null',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant');
        expect(restaurant.notes, isNull);
      },
    );

    test(
      'AC-1 — Restaurant.notes can be set to a non-null value',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'Great ambiance';
        expect(restaurant.notes, equals('Great ambiance'));
      },
    );

    test(
      'AC-1 — Restaurant.notes can be cleared (set back to null)',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'Initial notes';
        restaurant.notes = null;
        expect(restaurant.notes, isNull);
      },
    );

    test(
      'AC-1 — Restaurant.notes preserves empty string',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = '';
        expect(restaurant.notes, equals(''));
      },
    );

    test(
      'AC-2 — Notes persist across copyWith (unchanged when not overridden)',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'Persistent notes';
        final copied = restaurant.copyWith();
        expect(copied.notes, equals('Persistent notes'));
      },
    );

    test(
      'AC-2 — Notes can be updated via copyWith',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'Old notes';
        final copied = restaurant.copyWith(notes: 'New notes');
        expect(copied.notes, equals('New notes'));
        // Original unchanged.
        expect(restaurant.notes, equals('Old notes'));
      },
    );

    test(
      'AC-2 — copyWith with null notes keeps existing (standard ?? convention)',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'Some notes';
        final copied = restaurant.copyWith(notes: null);
        // Standard Flutter/Dart copyWith uses ?? so null means "keep existing".
        expect(copied.notes, equals('Some notes'));
      },
    );

    test(
      'AC-2 — copyWith with explicit non-null notes updates the field',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'Old';
        final copied = restaurant.copyWith(notes: 'New');
        expect(copied.notes, equals('New'));
      },
    );

    test(
      'touch() updates updatedAt without affecting notes',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'Stable notes';
        final before = restaurant.updatedAt;
        // touch() should update updatedAt.
        restaurant.touch();
        expect(restaurant.updatedAt.isAfter(before), isTrue);
        expect(restaurant.notes, equals('Stable notes'));
      },
    );

    test(
      'toString() includes notes when present',
      () {
        final restaurant = Restaurant(name: 'Test')..notes = 'Notes here';
        expect(restaurant.toString(), contains('Notes here'));
      },
    );

    test(
      'toString() omits null notes',
      () {
        final restaurant = Restaurant(name: 'Test');
        expect(restaurant.toString(), isNot(contains('notes')));
      },
    );
  });
}
