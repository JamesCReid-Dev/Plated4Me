/// Domain unit tests for UserPreferences — cuisine preferences and occasions (AC-3, AC-4).
///
/// Red Phase: These tests verify that UserPreferences can manage cuisine preferences
/// and default occasions with add/remove/edit operations. The production code must
/// support these mutations on the existing [UserPreferences] entity.
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';

void main() {
  group('AC-3 — Cuisine Preferences Management', () {
    test('AC-3: creates with empty cuisine preferences by default', () {
      final prefs = UserPreferences();

      expect(prefs.cuisinePreferences, isEmpty);
    });

    test('AC-3: can be created with initial cuisine preferences', () {
      final prefs = UserPreferences(
        cuisinePreferences: ['Italian', 'Japanese'],
      );

      expect(prefs.cuisinePreferences, hasLength(2));
      expect(prefs.cuisinePreferences, contains('Italian'));
      expect(prefs.cuisinePreferences, contains('Japanese'));
    });

    test('AC-3: can add a cuisine preference', () {
      final prefs = UserPreferences();
      prefs.cuisinePreferences.add('Mexican');

      expect(prefs.cuisinePreferences, hasLength(1));
      expect(prefs.cuisinePreferences.first, equals('Mexican'));
    });

    test('AC-3: can remove a cuisine preference', () {
      final prefs = UserPreferences(
        cuisinePreferences: ['Italian', 'Japanese', 'Mexican'],
      );
      prefs.cuisinePreferences.remove('Japanese');

      expect(prefs.cuisinePreferences, hasLength(2));
      expect(prefs.cuisinePreferences, isNot(contains('Japanese')));
    });

    test('AC-3: can replace all cuisine preferences', () {
      final prefs = UserPreferences(
        cuisinePreferences: ['Italian'],
      );
      prefs.cuisinePreferences.clear();
      prefs.cuisinePreferences.addAll(['Chinese', 'Thai']);

      expect(prefs.cuisinePreferences, hasLength(2));
      expect(prefs.cuisinePreferences, contains('Chinese'));
      expect(prefs.cuisinePreferences, contains('Thai'));
    });

    test('AC-3: copyWith preserves cuisine preferences when not overridden', () {
      final original = UserPreferences(
        cuisinePreferences: ['Italian', 'Indian'],
      );
      final copied = original.copyWith(ratingScale: 10);

      expect(copied.cuisinePreferences, hasLength(2));
      expect(copied.cuisinePreferences, contains('Italian'));
      expect(copied.cuisinePreferences, contains('Indian'));
    });

    test('AC-3: copyWith replaces cuisine preferences when provided', () {
      final original = UserPreferences(
        cuisinePreferences: ['Italian'],
      );
      final copied = original.copyWith(
        cuisinePreferences: ['Korean', 'Vietnamese'],
      );

      expect(copied.cuisinePreferences, hasLength(2));
      expect(copied.cuisinePreferences, contains('Korean'));
      expect(copied.cuisinePreferences, contains('Vietnamese'));
    });

    test('AC-3: duplicate cuisine preferences are allowed at entity level', () {
      final prefs = UserPreferences();
      prefs.cuisinePreferences.add('Italian');
      prefs.cuisinePreferences.add('Italian');

      expect(prefs.cuisinePreferences, hasLength(2));
    });

    test('AC-3: contains check works for cuisine preferences', () {
      final prefs = UserPreferences(
        cuisinePreferences: ['Italian', 'Japanese'],
      );

      expect(prefs.cuisinePreferences.contains('Italian'), isTrue);
      expect(prefs.cuisinePreferences.contains('French'), isFalse);
    });
  });

  group('AC-4 — Default Occasions Management', () {
    test('AC-4: creates with empty default occasions by default', () {
      final prefs = UserPreferences();

      expect(prefs.defaultOccasions, isEmpty);
    });

    test('AC-4: can be created with initial default occasions', () {
      final prefs = UserPreferences(
        defaultOccasions: ['Birthday', 'Date Night'],
      );

      expect(prefs.defaultOccasions, hasLength(2));
      expect(prefs.defaultOccasions, contains('Birthday'));
      expect(prefs.defaultOccasions, contains('Date Night'));
    });

    test('AC-4: can add a default occasion', () {
      final prefs = UserPreferences();
      prefs.defaultOccasions.add('Anniversary');

      expect(prefs.defaultOccasions, hasLength(1));
      expect(prefs.defaultOccasions.first, equals('Anniversary'));
    });

    test('AC-4: can remove a default occasion', () {
      final prefs = UserPreferences(
        defaultOccasions: ['Birthday', 'Date Night', 'Casual'],
      );
      prefs.defaultOccasions.remove('Casual');

      expect(prefs.defaultOccasions, hasLength(2));
      expect(prefs.defaultOccasions, isNot(contains('Casual')));
    });

    test('AC-4: can replace all default occasions', () {
      final prefs = UserPreferences(
        defaultOccasions: ['Birthday'],
      );
      prefs.defaultOccasions.clear();
      prefs.defaultOccasions.addAll(['Work', 'Holiday']);

      expect(prefs.defaultOccasions, hasLength(2));
      expect(prefs.defaultOccasions, contains('Work'));
      expect(prefs.defaultOccasions, contains('Holiday'));
    });

    test('AC-4: copyWith preserves default occasions when not overridden', () {
      final original = UserPreferences(
        defaultOccasions: ['Birthday', 'Casual'],
      );
      final copied = original.copyWith(ratingScale: 10);

      expect(copied.defaultOccasions, hasLength(2));
      expect(copied.defaultOccasions, contains('Birthday'));
    });

    test('AC-4: copyWith replaces default occasions when provided', () {
      final original = UserPreferences(
        defaultOccasions: ['Birthday'],
      );
      final copied = original.copyWith(defaultOccasions: ['Work']);

      expect(copied.defaultOccasions, hasLength(1));
      expect(copied.defaultOccasions.first, equals('Work'));
    });

    test('AC-4: contains check works for default occasions', () {
      final prefs = UserPreferences(
        defaultOccasions: ['Birthday', 'Date Night'],
      );

      expect(prefs.defaultOccasions.contains('Birthday'), isTrue);
      expect(prefs.defaultOccasions.contains('Meeting'), isFalse);
    });

    test('AC-4: occasion tags are plain strings — no special type required', () {
      final prefs = UserPreferences();
      prefs.defaultOccasions.add('Any string value');

      expect(prefs.defaultOccasions.first, equals('Any string value'));
    });
  });

  group('AC-3 + AC-4 — Combined Preferences State', () {
    test('AC-3+4: full preferences can hold cuisine + occasions simultaneously', () {
      final prefs = UserPreferences(
        cuisinePreferences: ['Italian'],
        defaultOccasions: ['Birthday'],
        ratingScale: 5,
      );

      expect(prefs.cuisinePreferences, hasLength(1));
      expect(prefs.defaultOccasions, hasLength(1));
      expect(prefs.ratingScale, equals(5));
    });

    test('AC-3+4: modifying one field does not affect others', () {
      final prefs = UserPreferences(
        cuisinePreferences: ['Italian'],
        defaultOccasions: ['Birthday'],
        ratingScale: 5,
      );
      prefs.ratingScale = 10;

      expect(prefs.cuisinePreferences, hasLength(1));
      expect(prefs.defaultOccasions, hasLength(1));
      expect(prefs.ratingScale, equals(10));
    });
  });
}
