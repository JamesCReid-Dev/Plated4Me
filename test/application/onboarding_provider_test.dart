/// Application-layer tests for onboarding state management (AC-1 through AC-6).
///
/// Red Phase: These tests verify that an [OnboardingNotifier] manages the
/// multi-step flow — tracking current screen, collecting selections, applying
/// sensible defaults on skip, and building final [UserPreferences].
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/onboarding_state.dart';
import 'package:plated4me/domain/entities/entities.dart';

void main() {
  group('OnboardingState — Default values', () {
    test('starts at screen 0 (allergies) with empty selections', () {
      final state = OnboardingState.initial();

      expect(state.currentScreen, equals(0));
      expect(state.selectedAllergens, isEmpty);
      expect(state.cuisinePreferences, isEmpty);
      expect(state.ratingScaleChoice, isNull);
      expect(state.selectedOccasions, isEmpty);
    });

    test('rating scale defaults to 5 when skipped', () {
      final state = OnboardingState.initial();
      final prefs = state.buildPreferences();

      expect(prefs.ratingScale, equals(5));
    });

    test('allergies default to empty when skipped', () {
      final state = OnboardingState.initial();
      final prefs = state.buildPreferences();

      expect(prefs.allergies, isEmpty);
    });

    test('default occasions are pre-populated when skipped', () {
      final state = OnboardingState.initial();
      final prefs = state.buildPreferences();

      expect(prefs.defaultOccasions, contains('Date Night'));
      expect(prefs.defaultOccasions, contains('Family Dinner'));
      expect(prefs.defaultOccasions, contains('Business Lunch'));
      expect(prefs.defaultOccasions, contains('Quick Bite'));
      expect(prefs.defaultOccasions, contains('Celebration'));
      expect(prefs.defaultOccasions, contains('Trying Something New'));
    });
  });

  group('OnboardingState — Screen navigation', () {
    test('advances to next screen', () {
      final state = OnboardingState.initial();

      state.nextScreen();

      expect(state.currentScreen, equals(1));
    });

    test('goes back to previous screen', () {
      final state = OnboardingState.initial()..nextScreen()..nextScreen();

      state.previousScreen();

      expect(state.currentScreen, equals(1));
    });

    test('cannot go before screen 0', () {
      final state = OnboardingState.initial();

      state.previousScreen();

      expect(state.currentScreen, equals(0));
    });

    test('total screen count is 4', () {
      expect(OnboardingState.totalScreens, equals(4));
    });
  });

  group('OnboardingState — Allergen management (AC-1)', () {
    test('adds an allergen with Moderate severity', () {
      final state = OnboardingState.initial();

      state.addAllergen('Peanuts', AllergenSeverity.moderate);

      expect(state.selectedAllergens, hasLength(1));
      expect(state.selectedAllergens[0].name, equals('Peanuts'));
      expect(state.selectedAllergens[0].severity, equals(AllergenSeverity.moderate.value));
    });

    test('adds an allergen with Severe severity', () {
      final state = OnboardingState.initial();

      state.addAllergen('Shellfish', AllergenSeverity.severe);

      expect(state.selectedAllergens[0].severity, equals(AllergenSeverity.severe.value));
    });

    test('removes an allergen by name', () {
      final state = OnboardingState.initial()
        ..addAllergen('Peanuts', AllergenSeverity.moderate)
        ..addAllergen('Dairy', AllergenSeverity.severe);

      state.removeAllergen('Peanuts');

      expect(state.selectedAllergens, hasLength(1));
      expect(state.selectedAllergens[0].name, equals('Dairy'));
    });

    test('adding duplicate allergen replaces existing entry', () {
      final state = OnboardingState.initial()
        ..addAllergen('Peanuts', AllergenSeverity.moderate);

      state.addAllergen('Peanuts', AllergenSeverity.severe);

      expect(state.selectedAllergens, hasLength(1));
      expect(state.selectedAllergens[0].severity, equals(AllergenSeverity.severe.value));
    });
  });

  group('OnboardingState — Cuisine preferences (AC-2)', () {
    test('adds a cuisine preference', () {
      final state = OnboardingState.initial();

      state.addCuisinePreference('Japanese');

      expect(state.cuisinePreferences, contains('Japanese'));
    });

    test('removes a cuisine preference', () {
      final state = OnboardingState.initial()
        ..addCuisinePreference('Japanese')
        ..removeCuisinePreference('Japanese');

      expect(state.cuisinePreferences, isNot(contains('Japanese')));
    });

    test('preset cuisines include all 20 required options', () {
      const presets = OnboardingState.presetCuisines;

      expect(presets, contains('Japanese'));
      expect(presets, contains('Mexican'));
      expect(presets, contains('Italian'));
      expect(presets, contains('Chinese'));
      expect(presets, contains('Thai'));
      expect(presets, contains('Indian'));
      expect(presets, contains('American'));
      expect(presets, contains('Mediterranean'));
      expect(presets, contains('French'));
      expect(presets, contains('Korean'));
      expect(presets, contains('Vietnamese'));
      expect(presets, contains('Greek'));
      expect(presets, contains('Turkish'));
      expect(presets, contains('Ethiopian'));
      expect(presets, contains('Brazilian'));
      expect(presets, contains('Lebanese'));
      expect(presets, contains('Spanish'));
      expect(presets, contains('German'));
      expect(presets, contains('Swedish'));
      expect(presets, contains('Indonesian'));
    });

    test('preset count is 20', () {
      expect(OnboardingState.presetCuisines.length, equals(20));
    });
  });

  group('OnboardingState — Rating scale (AC-3)', () {
    test('sets rating scale to 5-star', () {
      final state = OnboardingState.initial();

      state.setRatingScale(5);

      expect(state.ratingScaleChoice, equals(5));
    });

    test('sets rating scale to 10-star', () {
      final state = OnboardingState.initial();

      state.setRatingScale(10);

      expect(state.ratingScaleChoice, equals(10));
    });

    test('valid rating scales are 5 and 10 only', () {
      const validScales = OnboardingState.validRatingScales;

      expect(validScales, contains(5));
      expect(validScales, contains(10));
      expect(validScales, hasLength(2));
    });
  });

  group('OnboardingState — Default occasions (AC-4)', () {
    test('adds a default occasion', () {
      final state = OnboardingState.initial();

      state.addOccasion('Date Night');

      expect(state.selectedOccasions, contains('Date Night'));
    });

    test('removes a default occasion', () {
      final state = OnboardingState.initial()
        ..addOccasion('Date Night')
        ..removeOccasion('Date Night');

      expect(state.selectedOccasions, isNot(contains('Date Night')));
    });

    test('adds a custom occasion', () {
      final state = OnboardingState.initial();

      state.addCustomOccasion('Brunch with Friends');

      expect(state.selectedOccasions, contains('Brunch with Friends'));
    });

    test('pre-populated occasions match the story requirements', () {
      const defaults = OnboardingState.defaultOccasions;

      expect(defaults, contains('Date Night'));
      expect(defaults, contains('Family Dinner'));
      expect(defaults, contains('Business Lunch'));
      expect(defaults, contains('Quick Bite'));
      expect(defaults, contains('Celebration'));
      expect(defaults, contains('Trying Something New'));
    });
  });

  group('OnboardingState — Skip defaults (AC-6)', () {
    test('skipping allergies applies empty list', () {
      final state = OnboardingState.initial();

      state.skipScreen(0);
      final prefs = state.buildPreferences();

      expect(prefs.allergies, isEmpty);
    });

    test('skipping rating scale defaults to 5', () {
      final state = OnboardingState.initial();

      state.skipScreen(2);
      final prefs = state.buildPreferences();

      expect(prefs.ratingScale, equals(5));
    });

    test('skipping occasions provides all pre-populated options', () {
      final state = OnboardingState.initial();

      state.skipScreen(3);
      final prefs = state.buildPreferences();

      expect(prefs.defaultOccasions, hasLength(6));
    });

    test('completing onboarding sets onboardingComplete flag', () {
      final state = OnboardingState.initial()
        ..addAllergen('Peanuts', AllergenSeverity.moderate)
        ..addCuisinePreference('Japanese')
        ..setRatingScale(10)
        ..addOccasion('Date Night');

      final prefs = state.buildPreferences();

      expect(prefs.onboardingComplete, isTrue);
    });
  });

  group('OnboardingState — Build preferences end-to-end', () {
    test('full flow produces correct UserPreferences', () {
      final state = OnboardingState.initial()
        ..addAllergen('Eggs', AllergenSeverity.severe)
        ..addCuisinePreference('Italian')
        ..addCuisinePreference('Thai')
        ..setRatingScale(10)
        ..addOccasion('Date Night')
        ..addOccasion('Family Dinner');

      final prefs = state.buildPreferences();

      expect(prefs.allergies, hasLength(1));
      expect(prefs.allergies[0].name, equals('Eggs'));
      expect(prefs.allergies[0].severity, equals(AllergenSeverity.severe.value));
      expect(prefs.cuisinePreferences, contains('Italian'));
      expect(prefs.cuisinePreferences, contains('Thai'));
      expect(prefs.ratingScale, equals(10));
      expect(prefs.defaultOccasions, contains('Date Night'));
      expect(prefs.defaultOccasions, contains('Family Dinner'));
      expect(prefs.onboardingComplete, isTrue);
    });
  });
}
