/// Unit tests for domain entity constructors, copyWith, toString, and field access.
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';

void main() {
  // -- Restaurant ----------------------------------------------------------------

  group('Restaurant', () {
    test('can be created with required name only', () {
      final restaurant = Restaurant(name: 'Test Restaurant');

      expect(restaurant.name, equals('Test Restaurant'));
      expect(restaurant.address, isNull);
      expect(restaurant.createdAt, isNotNull);
      expect(restaurant.updatedAt, isNotNull);
    });

    test('can be created with name and address', () {
      final restaurant = Restaurant(
        name: 'Test Restaurant',
        address: '123 Main St',
      );

      expect(restaurant.name, equals('Test Restaurant'));
      expect(restaurant.address, equals('123 Main St'));
    });

    test('touch() updates updatedAt timestamp', () async {
      final before = DateTime.now();
      final restaurant = Restaurant(name: 'Test');

      await Future<void>.delayed(const Duration(milliseconds: 10));
      restaurant.touch();

      expect(restaurant.updatedAt.isAfter(before), isTrue);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Restaurant(name: 'Old Name');
      final updated = original.copyWith(name: 'New Name');

      expect(updated.name, equals('New Name'));
      expect(updated.address, isNull); // unchanged
      expect(updated.id, equals(original.id)); // id preserved
    });

    test('copyWith preserves unmodified fields', () {
      final original = Restaurant(name: 'Name', address: 'Addr');
      final updated = original.copyWith(name: 'New Name');

      expect(updated.address, equals('Addr'));
    });

    test('toString includes name and address', () {
      final restaurant = Restaurant(name: 'Test', address: '123 Main');

      expect(restaurant.toString(), contains('Test'));
      expect(restaurant.toString(), contains('123 Main'));
    });

    test('allergySafeFoods sub-collection starts empty', () {
      final restaurant = Restaurant(name: 'Test');

      expect(restaurant.allergySafeFoods, isEmpty);
    });

    test('copyWith preserves allergySafeFoods when not overridden', () {
      final original = Restaurant(name: 'Test');

      final updated = original.copyWith(name: 'New Name');

      expect(updated.allergySafeFoods, isEmpty);
      expect(updated.id, equals(original.id)); // id preserved
    });
  });

  // -- Visit ---------------------------------------------------------------------

  group('Visit', () {
    test('can be created with required fields only', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.5,
        overallRating: 4.0,
        compositeScore: 3.95,
        returnIntent: true,
      );

      expect(visit.restaurantId, equals(1));
      expect(visit.foodRating, equals(4.0));
      expect(visit.valueRating, equals(3.5));
      expect(visit.serviceRating, equals(4.5));
      expect(visit.overallRating, equals(4.0));
      expect(visit.compositeScore, equals(3.95));
      expect(visit.returnIntent, isTrue);
      expect(visit.createdAt, isNotNull);
      expect(visit.updatedAt, isNotNull);
    });

    test('optional fields default to null or empty', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.5,
        overallRating: 4.0,
        compositeScore: 3.95,
        returnIntent: false,
      );

      expect(visit.mealTotal, isNull);
      expect(visit.tipPercent, isNull);
      expect(visit.employeeName, isNull);
      expect(visit.generalNotes, isNull);
      expect(visit.blacklistReason, isNull);
      expect(visit.blacklisted, isFalse);
      expect(visit.occasions, isEmpty);
    });

    test('sub-collections start empty', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.5,
        overallRating: 4.0,
        compositeScore: 3.95,
        returnIntent: false,
      );

      expect(visit.journalEntries, isEmpty);
      expect(visit.lineItems, isEmpty);
      expect(visit.photos, isEmpty);
      expect(visit.allergySafeFoods, isEmpty);
    });

    test('touch() updates updatedAt timestamp', () {
      final before = DateTime.now();
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.5,
        overallRating: 4.0,
        compositeScore: 3.95,
        returnIntent: false,
      );

      visit.touch();

      expect(visit.updatedAt.isAfter(before), isTrue);
    });

    test('copyWith updates specified fields and preserves others', () {
      final original = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.5,
        overallRating: 4.0,
        compositeScore: 3.95,
        returnIntent: true,
      );

      final updated = original.copyWith(overallRating: 5.0);

      expect(updated.overallRating, equals(5.0));
      expect(updated.foodRating, equals(4.0)); // preserved
      expect(updated.restaurantId, equals(1)); // preserved
    });

    test('toString includes restaurantId and composite score', () {
      final visit = Visit(
        restaurantId: 42,
        foodRating: 4.0,
        valueRating: 3.5,
        serviceRating: 4.5,
        overallRating: 4.0,
        compositeScore: 3.95,
        returnIntent: true,
      );

      final str = visit.toString();
      expect(str, contains('42'));
      expect(str, contains('3.95'));
    });
  });

  // -- UserPreferences -----------------------------------------------------------

  group('UserPreferences', () {
    test('creates with default values', () {
      final prefs = UserPreferences();

      expect(prefs.ratingScale, equals(5));
      expect(prefs.onboardingComplete, isFalse);
      expect(prefs.allergies, isEmpty);
      expect(prefs.cuisinePreferences, isEmpty);
      expect(prefs.defaultOccasions, isEmpty);
      expect(prefs.createdAt, isNotNull);
      expect(prefs.updatedAt, isNotNull);
    });

    test('copyWith updates allergies', () {
      final original = UserPreferences();
      final updated = original.copyWith(
        allergies: [Allergen(name: 'Peanuts', severity: 1)],
      );

      expect(updated.allergies, hasLength(1));
      expect(updated.allergies[0].name, equals('Peanuts'));
    });

    test('copyWith preserves existing allergies when not overridden', () {
      final original = UserPreferences();
      original.allergies.add(Allergen(name: 'Shellfish', severity: 0));

      final updated = original.copyWith();
      expect(updated.allergies, hasLength(1));
      expect(updated.allergies[0].name, equals('Shellfish'));
    });

    test('copyWith updates cuisine preferences', () {
      final original = UserPreferences();
      final updated = original.copyWith(
        cuisinePreferences: ['Italian', 'Japanese'],
      );

      expect(updated.cuisinePreferences, hasLength(2));
      expect(updated.cuisinePreferences[0], equals('Italian'));
    });

    test('copyWith updates rating scale', () {
      final original = UserPreferences();
      final updated = original.copyWith(ratingScale: 10);

      expect(updated.ratingScale, equals(10));
    });

    test('copyWith preserves rating scale when not overridden', () {
      final original = UserPreferences();
      final updated = original.copyWith(onboardingComplete: true);

      expect(updated.ratingScale, equals(5)); // default preserved
    });

    test('copyWith updates onboarding complete flag', () {
      final original = UserPreferences();
      final updated = original.copyWith(onboardingComplete: true);

      expect(updated.onboardingComplete, isTrue);
    });

    test('toString includes rating scale', () {
      final prefs = UserPreferences();

      expect(prefs.toString(), contains('scale: 5'));
    });
  });

  // -- Allergen ------------------------------------------------------------------

  group('Allergen', () {
    test('can be created with name and severity', () {
      final allergen = Allergen(name: 'Peanuts', severity: 1);

      expect(allergen.name, equals('Peanuts'));
      expect(allergen.severity, equals(1));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Allergen(name: 'Peanuts', severity: 1);
      final updated = original.copyWith(severity: 0);

      expect(updated.name, equals('Peanuts'));
      expect(updated.severity, equals(0));
    });
  });

  // -- JournalEntry --------------------------------------------------------------

  group('JournalEntry', () {
    test('can be created with required fields', () {
      final entry = JournalEntry(
        dishName: 'Pad Thai',
        impressions: 'Spicy and delicious',
      );

      expect(entry.dishName, equals('Pad Thai'));
      expect(entry.impressions, equals('Spicy and delicious'));
      expect(entry.createdAt, isNotNull);
    });

    test('copyWith preserves dish name when only updating impressions', () {
      final original = JournalEntry(dishName: 'Sushi', impressions: 'Fresh');
      final updated = original.copyWith(impressions: 'Very fresh');

      expect(updated.dishName, equals('Sushi'));
      expect(updated.impressions, equals('Very fresh'));
    });
  });

  // -- VisitLineItem -------------------------------------------------------------

  group('VisitLineItem', () {
    test('can be created with dish name only', () {
      final item = VisitLineItem(dishName: 'Burger');

      expect(item.dishName, equals('Burger'));
      expect(item.price, isNull);
    });

    test('copyWith updates price', () {
      final original = VisitLineItem(dishName: 'Burger');
      final updated = original.copyWith(price: 12.99);

      expect(updated.price, equals(12.99));
    });
  });

  // -- AllergySafeFood -----------------------------------------------------------

  group('AllergySafeFood', () {
    test('can be created with item name', () {
      final safe = AllergySafeFood(itemName: 'Grilled Chicken');

      expect(safe.itemName, equals('Grilled Chicken'));
      expect(safe.createdAt, isNotNull);
    });

    test('copyWith updates item name', () {
      final original = AllergySafeFood(itemName: 'Chicken');
      final updated = original.copyWith(itemName: 'Turkey');

      expect(updated.itemName, equals('Turkey'));
    });
  });

  // -- PhotoAttachment -----------------------------------------------------------

  group('PhotoAttachment', () {
    test('can be created with file path and timestamp', () {
      final now = DateTime.now();
      final photo = PhotoAttachment(
        filePath: '/photos/img001.jpg',
        timestamp: now,
      );

      expect(photo.filePath, equals('/photos/img001.jpg'));
      expect(photo.timestamp, equals(now));
    });

    test('copyWith updates file path and timestamp', () {
      final oldTime = DateTime.utc(2024, 1, 1);
      final newTime = DateTime.utc(2024, 6, 1);
      final original = PhotoAttachment(
        filePath: '/old.jpg',
        timestamp: oldTime,
      );
      final updated = original.copyWith(
        filePath: '/new.jpg',
        timestamp: newTime,
      );

      expect(updated.filePath, equals('/new.jpg'));
      expect(updated.timestamp, equals(newTime));
    });
  });
}
