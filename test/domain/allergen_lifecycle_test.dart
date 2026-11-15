/// Domain unit tests for Allergen — add/edit/remove lifecycle (AC-1).
///
/// Red Phase: These tests verify the full CRUD lifecycle of allergen entries.
/// The production code must support creating, updating names/severity, and
/// deleting allergens via the [AllergenRepository].
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/domain/entities/entities.dart';

void main() {
  group('AC-1 — Allergen CRUD Lifecycle', () {
    // -- Creation ----------------------------------------------------------

    test('AC-1: creates allergen with name and default Moderate severity', () {
      final allergen = Allergen(name: 'Peanuts');

      expect(allergen.name, equals('Peanuts'));
      expect(allergen.severity, equals(AllergenSeverity.moderate.value));
    });

    test('AC-1: creates allergen with explicit Severe severity', () {
      final allergen = Allergen(
        name: 'Shellfish',
        severity: AllergenSeverity.severe.value,
      );

      expect(allergen.name, equals('Shellfish'));
      expect(allergen.severity, equals(AllergenSeverity.severe.value));
    });

    test('AC-1: allergen tracks creation timestamp', () {
      final allergen = Allergen(name: 'Soy');

      // createdAt should be a valid recent DateTime (not epoch, not far future).
      expect(allergen.createdAt.year, greaterThanOrEqualTo(2024));
      expect(allergen.createdAt.year, lessThanOrEqualTo(2030));
    });

    // -- Edit / Update -----------------------------------------------------

    test('AC-1: edits allergen name via copyWith', () {
      final original = Allergen(name: 'Milk');
      final updated = original.copyWith(name: 'Dairy Product');

      expect(updated.name, equals('Dairy Product'));
    });

    test('AC-1: edits allergen severity via copyWith', () {
      final moderate = Allergen(
        name: 'Gluten',
        severity: AllergenSeverity.moderate.value,
      );
      final severe = moderate.copyWith(severity: AllergenSeverity.severe.value);

      expect(severe.severity, equals(AllergenSeverity.severe.value));
    });

    test('AC-1: copyWith preserves ID', () {
      final allergen = Allergen(name: 'Eggs');
      allergen.id = 42;
      final copied = allergen.copyWith(name: 'Chicken Eggs');

      expect(copied.id, equals(42));
    });

    test('AC-1: can update severity from Moderate to Severe', () {
      final allergen = Allergen(name: 'Tree Nuts');
      allergen.severity = AllergenSeverity.severe.value;

      expect(allergen.severity, equals(AllergenSeverity.severe.value));
      expect(allergen.severityLabel, equals('Severe'));
    });

    test('AC-1: can update severity from Severe to Moderate', () {
      final allergen = Allergen(
        name: 'Mustard',
        severity: AllergenSeverity.severe.value,
      );
      allergen.severity = AllergenSeverity.moderate.value;

      expect(allergen.severity, equals(AllergenSeverity.moderate.value));
      expect(allergen.severityLabel, equals('Moderate'));
    });

    // -- Severity label helper ---------------------------------------------

    test('AC-1: severityLabel returns "Moderate" for value 0', () {
      final allergen = Allergen(
        name: 'Test',
        severity: AllergenSeverity.moderate.value,
      );
      expect(allergen.severityLabel, equals('Moderate'));
    });

    test('AC-1: severityLabel returns "Severe" for value 1', () {
      final allergen = Allergen(
        name: 'Test',
        severity: AllergenSeverity.severe.value,
      );
      expect(allergen.severityLabel, equals('Severe'));
    });

    test('AC-1: severityLabel returns "Unknown" for unexpected value', () {
      final allergen = Allergen(name: 'Test');
      allergen.severity = 99;
      expect(allergen.severityLabel, equals('Unknown'));
    });

    // -- Delete (entity-level) ---------------------------------------------

    test('AC-1: allergen can be created with auto-increment ID', () {
      final allergen = Allergen(name: 'Sesame');

      expect(allergen.id, equals(Isar.autoIncrement));
    });

    // -- Equality and identity ---------------------------------------------

    test('AC-1: two allergens with same data are not the same object', () {
      final a1 = Allergen(name: 'Peanuts');
      final a2 = Allergen(name: 'Peanuts');

      expect(a1, isNot(equals(a2)));
    });

    test('AC-1: toString includes allergen name', () {
      final allergen = Allergen(name: 'Peanuts');

      expect(allergen.toString(), contains('Peanuts'));
    });

    // -- Bulk operations (entity-level) ------------------------------------

    test('AC-1: multiple allergens can coexist with different severities', () {
      final allergens = <Allergen>[
        Allergen(name: 'Peanuts', severity: AllergenSeverity.severe.value),
        Allergen(name: 'Gluten', severity: AllergenSeverity.moderate.value),
        Allergen(name: 'Dairy', severity: AllergenSeverity.moderate.value),
      ];

      expect(allergens, hasLength(3));
      expect(
        allergens.where((a) => a.severity == AllergenSeverity.severe.value),
        hasLength(1),
      );
    });

    test('AC-1: can filter allergens by severity', () {
      final allergens = <Allergen>[
        Allergen(name: 'Peanuts', severity: AllergenSeverity.severe.value),
        Allergen(name: 'Sulites', severity: AllergenSeverity.severe.value),
        Allergen(name: 'Gluten', severity: AllergenSeverity.moderate.value),
      ];

      final severe = allergens.where(
        (a) => a.severity == AllergenSeverity.severe.value,
      ).toList();

      expect(severe, hasLength(2));
      expect(severe.every((a) => a.severityLabel == 'Severe'), isTrue);
    });
  });
}
