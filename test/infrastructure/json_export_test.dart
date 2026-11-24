/// Infrastructure tests for JSON data export (AC-5).
///
/// Red Phase: These tests verify that the app can serialize all user data
/// (restaurants, visits, preferences, allergens) to a valid JSON string.
/// The production code will need an export service/repository method that
/// collects all entities and produces a JSON document.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/infrastructure/export_service.dart';

void main() {
  group('AC-5 — JSON Data Export', () {
    // -- Empty export ------------------------------------------------------

    test('AC-5: exports empty data structure when no entities exist', () {
      final json = exportToJson(
        restaurants: [],
        visits: [],
        preferences: null,
        allergens: [],
      );

      expect(json, isA<String>());
      final parsed = _parseJson(json);
      expect(parsed, isA<Map<String, dynamic>>());
    });

    test('AC-5: empty export contains expected top-level keys', () {
      final json = exportToJson(
        restaurants: [],
        visits: [],
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;

      expect(parsed.containsKey('restaurants'), isTrue);
      expect(parsed.containsKey('visits'), isTrue);
      expect(parsed.containsKey('preferences'), isTrue);
      expect(parsed.containsKey('allergens'), isTrue);
    });

    // -- Restaurant export -------------------------------------------------

    test('AC-5: exports restaurant name and address', () {
      final restaurants = [
        Restaurant(name: 'Test Restaurant', address: '123 Main St'),
      ];
      final json = exportToJson(
        restaurants: restaurants,
        visits: [],
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final restaurantList = parsed['restaurants'] as List<dynamic>;

      expect(restaurantList, hasLength(1));
      expect(restaurantList[0]['name'], equals('Test Restaurant'));
      expect(restaurantList[0]['address'], equals('123 Main St'));
    });

    test('AC-5: exports restaurant with null address', () {
      final restaurants = [Restaurant(name: 'Food Truck')];
      final json = exportToJson(
        restaurants: restaurants,
        visits: [],
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final restaurantList = parsed['restaurants'] as List<dynamic>;

      expect(restaurantList[0]['name'], equals('Food Truck'));
      expect(restaurantList[0]['address'], isNull);
    });

    // -- P4ME-51: Restaurant notes export ----------------------------------

    test('P4ME-51: exports restaurant with non-null notes', () {
      final restaurants = [Restaurant(name: 'Test')..notes = 'Great pasta'];
      final json = exportToJson(
        restaurants: restaurants,
        visits: [],
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final restaurantList = parsed['restaurants'] as List<dynamic>;

      expect(restaurantList[0]['notes'], equals('Great pasta'));
    });

    test('P4ME-51: exports restaurant with null notes', () {
      final restaurants = [Restaurant(name: 'Test')];
      final json = exportToJson(
        restaurants: restaurants,
        visits: [],
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final restaurantList = parsed['restaurants'] as List<dynamic>;

      expect(restaurantList[0]['notes'], isNull);
    });

    // -- Visit export ------------------------------------------------------

    test('AC-5: exports visit ratings', () {
      final visits = [
        Visit(
          restaurantId: 1,
          foodRating: 4.0,
          valueRating: 3.5,
          serviceRating: 4.5,
          overallRating: 4.0,
          compositeScore: 3.95,
          returnIntent: true,
        ),
      ];
      final json = exportToJson(
        restaurants: [],
        visits: visits,
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final visitList = parsed['visits'] as List<dynamic>;

      expect(visitList[0]['restaurantId'], equals(1));
      expect(visitList[0]['foodRating'], equals(4.0));
      expect(visitList[0]['valueRating'], equals(3.5));
      expect(visitList[0]['serviceRating'], equals(4.5));
      expect(visitList[0]['overallRating'], equals(4.0));
      expect(visitList[0]['compositeScore'], equals(3.95));
    });

    test('AC-5: exports visit blacklisted status', () {
      final visits = [
        Visit(
          restaurantId: 1,
          foodRating: 1.0,
          valueRating: 1.0,
          serviceRating: 1.0,
          overallRating: 1.0,
          compositeScore: 1.0,
          returnIntent: false,
        )..blacklisted = true,
      ];
      final json = exportToJson(
        restaurants: [],
        visits: visits,
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final visitList = parsed['visits'] as List<dynamic>;

      expect(visitList[0]['blacklisted'], isTrue);
    });

    test('AC-5: exports visit occasions', () {
      final visits = [
        Visit(
          restaurantId: 1,
          foodRating: 4.0,
          valueRating: 3.5,
          serviceRating: 4.5,
          overallRating: 4.0,
          compositeScore: 3.95,
          returnIntent: true,
        )..occasions.addAll(['Birthday', 'Date Night']),
      ];
      final json = exportToJson(
        restaurants: [],
        visits: visits,
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final visitList = parsed['visits'] as List<dynamic>;

      expect(visitList[0]['occasions'], hasLength(2));
    });

    // -- Preferences export ------------------------------------------------

    test('AC-5: exports user preferences rating scale', () {
      final prefs = UserPreferences(ratingScale: 10);
      final json = exportToJson(
        restaurants: [],
        visits: [],
        preferences: prefs,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final exportedPrefs = parsed['preferences'] as Map<String, dynamic>?;

      expect(exportedPrefs!['ratingScale'], equals(10));
    });

    test('AC-5: exports user preferences cuisine list', () {
      final prefs = UserPreferences(cuisinePreferences: ['Italian', 'Japanese']);
      final json = exportToJson(
        restaurants: [],
        visits: [],
        preferences: prefs,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final exportedPrefs = parsed['preferences'] as Map<String, dynamic>?;

      expect(exportedPrefs!['cuisinePreferences'], contains('Italian'));
      expect(exportedPrefs['cuisinePreferences'], contains('Japanese'));
    });

    test('AC-5: exports user preferences default occasions', () {
      final prefs = UserPreferences(defaultOccasions: ['Birthday']);
      final json = exportToJson(
        restaurants: [],
        visits: [],
        preferences: prefs,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final exportedPrefs = parsed['preferences'] as Map<String, dynamic>?;

      expect(exportedPrefs!['defaultOccasions'], contains('Birthday'));
    });

    // -- Allergen export ---------------------------------------------------

    test('AC-5: exports allergen name and severity', () {
      final allergens = [
        Allergen(name: 'Peanuts', severity: AllergenSeverity.severe.value),
      ];
      final json = exportToJson(
        restaurants: [],
        visits: [],
        preferences: null,
        allergens: allergens,
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final allergenList = parsed['allergens'] as List<dynamic>;

      expect(allergenList[0]['name'], equals('Peanuts'));
      expect(allergenList[0]['severity'], equals(AllergenSeverity.severe.value));
    });

    // -- Combined export ---------------------------------------------------

    test('AC-5: exports all entity types in one document', () {
      final json = exportToJson(
        restaurants: [Restaurant(name: 'Test')],
        visits: [
          Visit(
            restaurantId: 1,
            foodRating: 4.0,
            valueRating: 3.5,
            serviceRating: 4.5,
            overallRating: 4.0,
            compositeScore: 3.95,
            returnIntent: true,
          ),
        ],
        preferences: UserPreferences(ratingScale: 10),
        allergens: [Allergen(name: 'Peanuts')],
      );

      final parsed = _parseJson(json) as Map<String, dynamic>;
      expect((parsed['restaurants'] as List).length, equals(1));
      expect((parsed['visits'] as List).length, equals(1));
      expect(parsed['preferences'], isNotNull);
      expect((parsed['allergens'] as List).length, equals(1));
    });

    // -- JSON validity -----------------------------------------------------

    test('AC-5: exported JSON is valid and parseable', () {
      final json = exportToJson(
        restaurants: [],
        visits: [],
        preferences: null,
        allergens: [],
      );

      expect(() => _parseJson(json), returnsNormally);
    });

    test('AC-5: exported JSON is pretty-printable (contains newlines)', () {
      final json = exportToJson(
        restaurants: [Restaurant(name: 'A')],
        visits: [],
        preferences: null,
        allergens: [],
      );

      expect(json.contains('\n'), isTrue);
    });

    // -- Blacklisted visit export (AC-6) -----------------------------------

    test('AC-5+AC-6: blacklisted visits include blacklistReason in export', () {
      final visits = [
        Visit(
          restaurantId: 1,
          foodRating: 1.0,
          valueRating: 1.0,
          serviceRating: 1.0,
          overallRating: 1.0,
          compositeScore: 1.0,
          returnIntent: false,
        )..blacklisted = true
          ..blacklistReason = 'Food poisoning',
      ];
      final json = exportToJson(
        restaurants: [],
        visits: visits,
        preferences: null,
        allergens: [],
      );
      final parsed = _parseJson(json) as Map<String, dynamic>;
      final visitList = parsed['visits'] as List<dynamic>;

      expect(visitList[0]['blacklisted'], isTrue);
      expect(visitList[0]['blacklistReason'], equals('Food poisoning'));
    });
  });
}

/// Parses a JSON string into a Dart object.
dynamic _parseJson(String json) => jsonDecode(json);
