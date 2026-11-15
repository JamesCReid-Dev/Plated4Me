/// Domain unit tests for [Allergen] — severity validation (AC-1).
///
/// Red Phase: These tests verify that allergen entries require valid severity
/// values. The production code will need an [AllergenSeverity] enum with
/// Moderate and Severe options, and the [Allergen] constructor must reject
/// invalid severity values.
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';

void main() {
  group('Allergen — Severity Validation (AC-1)', () {
    test('can be created with Moderate severity', () {
      final allergen = Allergen(
        name: 'Peanuts',
        severity: AllergenSeverity.moderate.value,
      );

      expect(allergen.name, equals('Peanuts'));
      expect(allergen.severity, equals(AllergenSeverity.moderate.value));
    });

    test('can be created with Severe severity', () {
      final allergen = Allergen(
        name: 'Shellfish',
        severity: AllergenSeverity.severe.value,
      );

      expect(allergen.name, equals('Shellfish'));
      expect(allergen.severity, equals(AllergenSeverity.severe.value));
    });

    test('severity defaults to Moderate when not specified', () {
      final allergen = Allergen(name: 'Gluten');

      expect(allergen.severity, equals(AllergenSeverity.moderate.value));
    });

    test('copyWith preserves severity', () {
      final original = Allergen(
        name: 'Dairy',
        severity: AllergenSeverity.severe.value,
      );
      final updated = original.copyWith(name: 'Milk');

      expect(updated.severity, equals(AllergenSeverity.severe.value));
    });

    test('severity value maps to correct label — Moderate', () {
      expect(AllergenSeverity.moderate.label, equals('Moderate'));
    });

    test('severity value maps to correct label — Severe', () {
      expect(AllergenSeverity.severe.label, equals('Severe'));
    });

    test('all valid severity values are defined', () {
      const values = AllergenSeverity.values;

      expect(values, hasLength(2));
      expect(values, contains(AllergenSeverity.moderate));
      expect(values, contains(AllergenSeverity.severe));
    });
  });
}
