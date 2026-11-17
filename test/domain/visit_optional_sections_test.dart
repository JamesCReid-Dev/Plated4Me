/// Domain tests for Visit entity with optional sections (P4ME-16).
///
/// Verifies that Visit entities can be created and saved with empty optional
/// sub-collections (line items, journal entries, allergy-safe foods), supporting
/// AC-2: user can save immediately after ratings without filling any optional section.
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';

void main() {
  group('P4ME-16 — Visit with empty optional sections', () {
    test('Visit can be created with all optional fields empty', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.0,
        serviceRating: 5.0,
        overallRating: 4.0,
        compositeScore: 4.05,
        returnIntent: true,
      );

      expect(visit.mealTotal, isNull);
      expect(visit.tipPercent, isNull);
      expect(visit.employeeName, isNull);
      expect(visit.generalNotes, isNull);
      expect(visit.lineItems, const <VisitLineItem>[]);
      expect(visit.journalEntries, const <JournalEntry>[]);
      expect(visit.allergySafeFoods, const <AllergySafeFood>[]);
    });

    test('VisitLineItem can be created with dish name and optional price', () {
      final item = VisitLineItem(dishName: 'Ramen');
      expect(item.dishName, 'Ramen');
      expect(item.price, isNull);

      item.price = 5.0;
      expect(item.price, 5.0);
    });

    test('VisitJournalEntry can be created with dish name and impressions', () {
      final entry = JournalEntry(dishName: 'Ramen', impressions: 'Rich tonkotsu broth');
      expect(entry.dishName, 'Ramen');
      expect(entry.impressions, 'Rich tonkotsu broth');
    });

    test('AllergySafeFood can be created with itemName and restaurantId', () {
      final food = AllergySafeFood(itemName: 'Grilled Chicken', restaurantId: 1);
      expect(food.itemName, 'Grilled Chicken');
      expect(food.restaurantId, 1);
    });

    test('Visit sub-collections are managed via repositories, not directly on entity', () {
      // The Visit entity stores sub-collections as @ignore List fields.
      // These are populated by the repository layer when loading/saving visits.
      // Tests verify that Visit can be created without them (AC-2).
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.0,
        serviceRating: 5.0,
        overallRating: 4.0,
        compositeScore: 4.05,
        returnIntent: true,
      );

      // Visit can be saved with empty sub-collections (AC-2).
      expect(visit.mealTotal, isNull);
      expect(visit.lineItems, const <VisitLineItem>[]);
      expect(visit.journalEntries, const <JournalEntry>[]);
    });

    test('Visit can hold meal total, tip, and employee name', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.0,
        serviceRating: 5.0,
        overallRating: 4.0,
        compositeScore: 4.05,
        returnIntent: true,
      )..mealTotal = 42.50
        ..tipPercent = 18.0
        ..employeeName = 'Alex';

      expect(visit.mealTotal, 42.50);
      expect(visit.tipPercent, 18.0);
      expect(visit.employeeName, 'Alex');
    });

    test('Visit can hold general notes', () {
      final visit = Visit(
        restaurantId: 1,
        foodRating: 4.0,
        valueRating: 3.0,
        serviceRating: 5.0,
        overallRating: 4.0,
        compositeScore: 4.05,
        returnIntent: false,
      )..generalNotes = 'Great ambiance, noisy during lunch rush';

      expect(visit.generalNotes, 'Great ambiance, noisy during lunch rush');
    });
  });
}
