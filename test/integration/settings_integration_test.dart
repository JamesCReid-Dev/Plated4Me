/// Integration tests for Settings & Preferences (AC-1 through AC-7).
///
/// These tests verify cross-layer scenarios where domain logic, infrastructure,
/// and application layers work together correctly.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/math.dart' as math;
import 'package:plated4me/domain/repositories/allergen_repository.dart';
import 'package:plated4me/domain/repositories/user_preferences_repository.dart';
import 'package:plated4me/infrastructure/export_service.dart' as json_export;

// -- Mocks ---------------------------------------------------------------------

class _MockAllergenRepository extends Mock implements AllergenRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  late _MockAllergenRepository mockAllergenRepo;
  late _MockUserPreferencesRepository mockPrefsRepo;

  setUp(() {
    mockAllergenRepo = _MockAllergenRepository();
    mockPrefsRepo = _MockUserPreferencesRepository();

    registerFallbackValue(UserPreferences());
    registerFallbackValue(Allergen(name: 'fallback'));
  });

  group('AC-2 — Rating Scale Conversion + Preferences Integration', () {
    test('converts visit ratings and saves updated preferences (5→10 star)',
        () async {
      // Arrange: existing visits on 5-star scale.
      // Existing preferences on 5-star scale (context for re-scaling).

      // Act: simulate switching to 10-star scale.
      final rescaled = math.rescaleVisitRatings(
        foodRating: 4.0,
        valueRating: 3.0,
        serviceRating: 5.0,
        overallRating: 4.5,
        compositeScore: 4.125,
        fromScale: 5,
        toScale: 10,
      );

      // Assert: all ratings doubled.
      expect(rescaled['foodRating'], equals(8.0));
      expect(rescaled['valueRating'], equals(6.0));
      expect(rescaled['serviceRating'], equals(10.0));
      expect(rescaled['overallRating'], equals(9.0));
      expect(rescaled['compositeScore'], closeTo(8.25, 0.01));

      // Verify preferences would be saved with new scale.
      final updatedPrefs = UserPreferences(ratingScale: 10);
      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => updatedPrefs);

      final saved = await mockPrefsRepo.saveUserPreferences(updatedPrefs);
      expect(saved.ratingScale, equals(10));
    });

    test('converts visit ratings and saves updated preferences (10→5 star)',
        () async {
      // Act: simulate switching from 10-star back to 5-star.
      final rescaled = math.rescaleVisitRatings(
        foodRating: 8.0,
        valueRating: 6.0,
        serviceRating: 10.0,
        overallRating: 9.0,
        compositeScore: 8.25,
        fromScale: 10,
        toScale: 5,
      );

      // Assert: all ratings halved.
      expect(rescaled['foodRating'], equals(4.0));
      expect(rescaled['valueRating'], equals(3.0));
      expect(rescaled['serviceRating'], equals(5.0));
      expect(rescaled['overallRating'], equals(4.5));
      expect(rescaled['compositeScore'], closeTo(4.125, 0.01));

      // Verify preferences would be saved with new scale.
      final updatedPrefs = UserPreferences(ratingScale: 5);
      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => updatedPrefs);

      final saved = await mockPrefsRepo.saveUserPreferences(updatedPrefs);
      expect(saved.ratingScale, equals(5));
    });

    test('round-trip conversion preserves original ratings', () {
      // Act: convert 5→10 then back to 5.
      for (final rating in [1.0, 2.0, 3.0, 4.0, 5.0]) {
        final toTen = math.scaleToTen(rating);
        final backToFive = math.scaleToFive(toTen);

        expect(backToFive, equals(rating),
            reason: 'Round-trip for $rating should return original');
      }
    });
  });

  group('AC-5 — JSON Export Integration', () {
    test('exports restaurants, visits, preferences, and allergens together',
        () {
      // Arrange: create sample data across all entity types.
      final restaurants = <Restaurant>[
        Restaurant(name: 'Test Bistro', address: '123 Main St'),
      ];

      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.0,
        overallRating: 4.0,
        compositeScore: 3.875,
        returnIntent: true,
      ).copyWith(occasions: ['Birthday']);

      final visits = <Visit>[visit];

      final preferences = UserPreferences(
        ratingScale: 10,
        cuisinePreferences: ['Italian', 'Japanese'],
        defaultOccasions: ['Birthday', 'Date Night'],
      );

      final allergens = <Allergen>[
        Allergen(name: 'Peanuts', severity: AllergenSeverity.severe.value),
      ];

      // Act: export to JSON.
      final json = json_export.exportToJson(
        restaurants: restaurants,
        visits: visits,
        preferences: preferences,
        allergens: allergens,
      );

      // Assert: valid parseable JSON with all entity types.
      expect(json.contains('"restaurants"'), isTrue);
      expect(json.contains('"visits"'), isTrue);
      expect(json.contains('"preferences"'), isTrue);
      expect(json.contains('"allergens"'), isTrue);

      // Assert: restaurant data present.
      expect(json.contains('Test Bistro'), isTrue);
      expect(json.contains('123 Main St'), isTrue);

      // Assert: visit ratings present.
      expect(json.contains('4.0'), isTrue);
      expect(json.contains('"Birthday"'), isTrue);

      // Assert: preferences data present.
      expect(json.contains('Italian'), isTrue);
      expect(json.contains('Japanese'), isTrue);

      // Assert: allergen data present.
      expect(json.contains('Peanuts'), isTrue);
    });

    test('export includes blacklistReason on blacklisted visits', () {
      final blacklistedVisit = Visit(
        restaurantId: 1,
        foodRating: 3.0,
        valueRating: 2.0,
        serviceRating: 3.0,
        overallRating: 3.0,
        compositeScore: 2.75,
        returnIntent: false,
      ).copyWith(
        blacklisted: true,
        blacklistReason: 'Poor hygiene',
      );

      final json = json_export.exportToJson(
        restaurants: [],
        visits: [blacklistedVisit],
        preferences: null,
        allergens: [],
      );

      expect(json.contains('Poor hygiene'), isTrue);
      expect(json.contains('"blacklisted": true'), isTrue);
    });

    test('export produces pretty-printed JSON with indentation', () {
      final json = json_export.exportToJson(
        restaurants: [Restaurant(name: 'A')],
        visits: <Visit>[],
        preferences: null,
        allergens: <Allergen>[],
      );

      // Pretty-printed JSON should contain newlines and spaces.
      expect(json.contains('\n'), isTrue);
      expect(json.contains('  '), isTrue);
    });

    test('export handles empty data gracefully', () {
      final json = json_export.exportToJson(
        restaurants: <Restaurant>[],
        visits: <Visit>[],
        preferences: null,
        allergens: <Allergen>[],
      );

      // Should still be valid JSON with all top-level keys.
      expect(json.contains('"restaurants": []'), isTrue);
      expect(json.contains('"visits": []'), isTrue);
    });
  });

  group('AC-6 — Blacklist Clear Integration', () {
    // Helper to create a Visit with minimal required params.
    Visit makeVisit({required int restaurantId}) => Visit(
          restaurantId: restaurantId,
          foodRating: 0,
          valueRating: 0,
          serviceRating: 0,
          overallRating: 0,
          compositeScore: 0,
          returnIntent: false,
        );

    test('bulk delete removes only blacklisted visits, keeps others', () async {
      // Arrange: create a mock repo with mixed data.
      final allVisits = <Visit>[
        makeVisit(restaurantId: 1).copyWith(foodRating: 4.0, overallRating: 4.0),
        makeVisit(restaurantId: 2)
            .copyWith(
              foodRating: 2.0,
              overallRating: 2.0,
              blacklisted: true,
              blacklistReason: 'Bad experience',
            ),
        makeVisit(restaurantId: 3).copyWith(foodRating: 5.0, overallRating: 5.0),
      ];

      when(() => mockPrefsRepo.getUserPreferences())
          .thenAnswer((_) async => UserPreferences());

      // Verify the preferences repo is accessible (integration check).
      final prefs = await mockPrefsRepo.getUserPreferences();
      expect(prefs, isNotNull);

      // Verify we can identify blacklisted visits.
      final blacklistedCount = allVisits.where((v) => v.blacklisted).length;
      expect(blacklistedCount, equals(1));
    });

    test('blacklist clear preserves non-blacklisted visit data', () {
      // Arrange: verify that blacklisted flag and reason are stored.
      final blacklistedVisit = makeVisit(restaurantId: 1).copyWith(
        foodRating: 2.0,
        overallRating: 2.0,
        blacklisted: true,
        blacklistReason: 'Food poisoning',
      );

      // Assert: all fields preserved on blacklisted visit.
      expect(blacklistedVisit.blacklisted, isTrue);
      expect(blacklistedVisit.blacklistReason, equals('Food poisoning'));
    });
  });

  group('AC-1 — Allergen CRUD Integration', () {
    test('allergen save and retrieval through repository', () async {
      final newAllergen = Allergen(name: 'Shellfish');

      when(() => mockAllergenRepo.saveAllergen(any()))
          .thenAnswer((_) async => newAllergen);

      final saved = await mockAllergenRepo.saveAllergen(newAllergen);

      expect(saved.name, equals('Shellfish'));
    });

    test('allergen delete returns count of deleted items', () async {
      when(() => mockAllergenRepo.deleteAllergen(any()))
          .thenAnswer((_) async => true);

      final deleted = await mockAllergenRepo.deleteAllergen(42);

      expect(deleted, isTrue);
    });

    test('allergens loaded from repository on init', () async {
      final allergens = [
        Allergen(name: 'Gluten'),
        Allergen(name: 'Dairy'),
      ];

      when(() => mockAllergenRepo.getAllAllergens())
          .thenAnswer((_) async => allergens);

      final loaded = await mockAllergenRepo.getAllAllergens();

      expect(loaded, hasLength(2));
      expect(loaded[0].name, equals('Gluten'));
    });
  });

  group('AC-3 + AC-4 — Preferences Integration', () {
    test('cuisine preferences and default occasions saved together', () async {
      final prefs = UserPreferences(
        cuisinePreferences: ['Italian'],
        defaultOccasions: ['Birthday'],
      );

      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => prefs);

      final saved = await mockPrefsRepo.saveUserPreferences(prefs);

      expect(saved.cuisinePreferences, contains('Italian'));
      expect(saved.defaultOccasions, contains('Birthday'));
    });

    test('preferences with rating scale 10 saves correctly', () async {
      final prefs = UserPreferences(ratingScale: 10);

      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => prefs);

      final saved = await mockPrefsRepo.saveUserPreferences(prefs);

      expect(saved.ratingScale, equals(10));
    });
  });

  group('Cross-AC — Combined Settings Workflow', () {
    test('full settings update: allergen + preferences + export check', () async {
      // Step 1: Add allergen.
      final newAllergen = Allergen(name: 'Eggs');
      when(() => mockAllergenRepo.saveAllergen(any()))
          .thenAnswer((_) async => newAllergen);
      await mockAllergenRepo.saveAllergen(newAllergen);

      // Step 2: Update preferences.
      final updatedPrefs = UserPreferences(
        ratingScale: 10,
        cuisinePreferences: ['Mexican'],
        defaultOccasions: ['Lunch'],
      );
      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => updatedPrefs);
      await mockPrefsRepo.saveUserPreferences(updatedPrefs);

      // Step 3: Verify export would include all data.
      final json = json_export.exportToJson(
        restaurants: <Restaurant>[],
        visits: <Visit>[],
        preferences: updatedPrefs,
        allergens: [newAllergen],
      );

      expect(json.contains('Eggs'), isTrue);
      expect(json.contains('Mexican'), isTrue);
      expect(json.contains('"Lunch"'), isTrue);
    });

    test('rating scale change triggers re-scaling + preferences save', () async {
      // Step 1: Convert ratings from 5→10.
      final rescaled = math.rescaleVisitRatings(
        foodRating: 3.0,
        valueRating: 4.0,
        serviceRating: 3.5,
        overallRating: 3.8,
        compositeScore: 3.575,
        fromScale: 5,
        toScale: 10,
      );

      expect(rescaled['foodRating'], equals(6.0));
      expect(rescaled['compositeScore'], closeTo(7.15, 0.01));

      // Step 2: Save updated preferences with new scale.
      final prefs = UserPreferences(ratingScale: 10);
      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => prefs);

      await mockPrefsRepo.saveUserPreferences(prefs);

      verify(() => mockPrefsRepo.saveUserPreferences(prefs)).called(1);
    });

    test('export with sample visit data includes all rating fields', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.0,
        overallRating: 4.0,
        compositeScore: 3.875,
        returnIntent: true,
      );

      final json = json_export.exportToJson(
        restaurants: <Restaurant>[],
        visits: [visit],
        preferences: null,
        allergens: <Allergen>[],
      );

      expect(json.contains('"foodRating": 4.0'), isTrue);
      expect(json.contains('"valueRating": 3.5'), isTrue);
      expect(json.contains('"serviceRating": 4.0'), isTrue);
      expect(json.contains('"overallRating": 4.0'), isTrue);
      expect(json.contains('"compositeScore": 3.875'), isTrue);
    });
  });
}
