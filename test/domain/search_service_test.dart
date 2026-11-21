/// Domain layer tests for SearchService — 9-tier relevance ranking (AD-9).
///
/// P4ME-18 — Full-Text Search.
/// Covers AC-3: Results ranked by 9-tier relevance priority model.
///
/// TIER MODEL (AC-3 / AD-9):
///   1. Restaurant name exact match
///   2. Restaurant name partial match
///   3. Address match
///   4. Journal entry dish name match
///   5. Journal entry impressions match
///   6. Voice transcript match (field not yet present — skipped)
///   7. Employee name match
///   8. Occasion tag match
///   9. General notes match

import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/services/search_service.dart';

// -- Test data helpers --------------------------------------------------------

FilteredVisit _makeFilteredVisit({
  required String restaurantName,
  int? restaurantId,
  String? address,
  List<JournalEntry>? journalEntries,
  List<String>? occasions,
  String? employeeName,
  String? generalNotes,
}) {
  final id = restaurantId ?? restaurantName.hashCode;
  final restaurant = Restaurant(name: restaurantName, address: address)..id = id;
  final visit = Visit(
    restaurantId: id,
    foodRating: 4.0,
    valueRating: 3.5,
    serviceRating: 4.0,
    overallRating: 4.5,
    compositeScore: 80.0,
    returnIntent: false,
  )..id = id;
  if (journalEntries != null) visit.journalEntries = List.from(journalEntries);
  if (occasions != null) visit.occasions.addAll(occasions);
  visit.employeeName = employeeName;
  visit.generalNotes = generalNotes;
  return FilteredVisit(visit: visit, restaurant: restaurant);
}

// -- Tests --------------------------------------------------------------------

void main() {
  group('P4ME-18 — SearchService', () {
    test(
      'AC-3 tier 1 — exact restaurant name match ranks highest',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Sakura',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura'),
            _makeFilteredVisit(restaurantName: 'Sakura Garden'),
          ],
        );
        expect(results.length, equals(2));
        // Exact match should be first.
        expect(results[0].restaurant.name, equals('Sakura'));
      },
    );

    test(
      'AC-3 tier 2 — partial restaurant name match',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Saku',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura'),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results.length, equals(1));
        expect(results[0].restaurant.name, equals('Sakura'));
      },
    );

    test(
      'AC-3 tier 3 — address match ranks below partial restaurant name',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Main Street',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', address: '123 Main Street'), // tier 3 — address
            _makeFilteredVisit(restaurantName: 'Main Street Cafe'), // tier 2 — partial name
          ],
        );
        expect(results.length, equals(2));
        // Tier 2 (partial name) should rank above tier 3 (address).
        expect(results[0].restaurant.name, equals('Main Street Cafe'));
      },
    );

    test(
      'AC-3 tier 4 — journal entry dish name match',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Ramen',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              journalEntries: [JournalEntry(dishName: 'Ramen', impressions: '')],
            ),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-3 tier 5 — journal entry impressions match',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'delicious',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              journalEntries: [JournalEntry(dishName: 'Sushi', impressions: 'Delicious fresh fish')],
            ),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-3 tier 7 — employee name match',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'John',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', employeeName: 'John'),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-3 tier 8 — occasion tag match',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Date Night',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', occasions: ['Date Night']),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-3 tier 9 — general notes match',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'great ambiance',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', generalNotes: 'Great ambiance and friendly staff'),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-3 — mixed matches respect tier ordering across all tiers',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Sakura',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura'), // tier 1 — exact
            _makeFilteredVisit(restaurantName: 'Sakura Garden'), // tier 2 — partial
            _makeFilteredVisit(restaurantName: 'Pizza', address: 'Sakura Lane'), // tier 3 — address
            _makeFilteredVisit(
              restaurantName: 'Bistro',
              journalEntries: [JournalEntry(dishName: 'Sakura Cake', impressions: '')], // tier 4
            ),
            _makeFilteredVisit(restaurantName: 'Diner', employeeName: 'Sakura'), // tier 7
          ],
        );
        expect(results.length, equals(5));
        expect(results[0].restaurant.name, equals('Sakura')); // tier 1
        expect(results[1].restaurant.name, equals('Sakura Garden')); // tier 2
        expect(results[2].restaurant.name, equals('Pizza')); // tier 3
        expect(results[3].restaurant.name, equals('Bistro')); // tier 4
        expect(results[4].restaurant.name, equals('Diner')); // tier 7
      },
    );

    test(
      'Empty query returns empty list',
      () async {
        final service = SearchService();
        final results = service.search(
          query: '',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura'),
          ],
        );
        expect(results, isEmpty);
      },
    );

    test(
      'Whitespace-only query returns empty list',
      () async {
        final service = SearchService();
        final results = service.search(
          query: '   ',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura'),
          ],
        );
        expect(results, isEmpty);
      },
    );

    test(
      'No matches returns empty list',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'xyznonexistent',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura'),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results, isEmpty);
      },
    );

    test(
      'Case-insensitive search — uppercase query matches lowercase data',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'SAKURA',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura'),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'Case-insensitive search — lowercase query matches uppercase data',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'sakura',
          visits: [
            _makeFilteredVisit(restaurantName: 'SAKURA'),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-4 — match highlights returned for matching text in restaurant name',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Saku',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura'),
          ],
        );
        expect(results.length, equals(1));
        // Should have highlights for the matched text.
        expect(results[0].matchHighlights.isNotEmpty, isTrue);
      },
    );

    test(
      'AC-4 — match highlights returned for journal entry dish name',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Ramen',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              journalEntries: [JournalEntry(dishName: 'Ramen Deluxe', impressions: '')],
            ),
          ],
        );
        expect(results.length, equals(1));
        expect(results[0].matchHighlights.isNotEmpty, isTrue);
      },
    );

    test(
      'Multiple visits with same tier — stable sort by date (most recent first)',
      () async {
        final service = SearchService();
        final visit1 = _makeFilteredVisit(restaurantName: 'Sakura');
        visit1.visit.createdAt = DateTime(2025, 1, 1);

        final visit2 = _makeFilteredVisit(restaurantName: 'Sakura Garden');
        visit2.visit.createdAt = DateTime(2025, 6, 1);

        final results = service.search(
          query: 'Saku',
          visits: [visit1, visit2],
        );
        expect(results.length, equals(2));
        // Same tier (tier 2) — most recent first.
        expect(results[0].restaurant.name, equals('Sakura Garden'));
      },
    );

    test(
      'Multi-word query matches across different fields',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'John Date',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', employeeName: 'John', occasions: ['Date Night']),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'Partial word match — "ram" matches "Ramen"',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'ram',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              journalEntries: [JournalEntry(dishName: 'Ramen', impressions: '')],
            ),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-4 — match highlights for general notes',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'ambiance',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', generalNotes: 'Great ambiance'),
          ],
        );
        expect(results.length, equals(1));
        expect(results[0].matchHighlights.isNotEmpty, isTrue);
      },
    );

    test(
      'AC-4 — match highlights for occasion tags',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Date Night',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', occasions: ['Date Night']),
          ],
        );
        expect(results.length, equals(1));
        expect(results[0].matchHighlights.isNotEmpty, isTrue);
      },
    );

    test(
      'AC-4 — match highlights for employee name',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'John',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', employeeName: 'John Smith'),
          ],
        );
        expect(results.length, equals(1));
        expect(results[0].matchHighlights.isNotEmpty, isTrue);
      },
    );

    test(
      'AC-4 — match highlights for address',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Main St',
          visits: [
            _makeFilteredVisit(restaurantName: 'Sakura', address: '123 Main Street'),
          ],
        );
        expect(results.length, equals(1));
        expect(results[0].matchHighlights.isNotEmpty, isTrue);
      },
    );

    test(
      'AC-4 — match highlights for journal impressions',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'fresh',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              journalEntries: [JournalEntry(dishName: 'Sushi', impressions: 'Very fresh fish')],
            ),
          ],
        );
        expect(results.length, equals(1));
        expect(results[0].matchHighlights.isNotEmpty, isTrue);
      },
    );

    test(
      'Performance — search completes in <200ms for 500 visits',
      () async {
        final service = SearchService();
        final visits = List.generate(500, (i) => _makeFilteredVisit(
          restaurantName: 'Restaurant $i',
          address: '$i Some Street',
          occasions: ['Occasion $i'],
          employeeName: 'Server $i',
          generalNotes: 'Notes for visit $i',
          journalEntries: [JournalEntry(dishName: 'Dish $i', impressions: 'Tasty')],
        ));

        final stopwatch = Stopwatch()..start();
        service.search(query: 'Restaurant', visits: visits);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      },
    );

    // -- P4ME-47: Single-pass journal entry iteration regression tests --------

    test(
      'P4ME-47 — both dish name and impressions highlights returned from same entry (single pass)',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Ramen',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              journalEntries: [JournalEntry(dishName: 'Ramen Deluxe', impressions: 'Best ramen in town')],
            ),
          ],
        );
        expect(results.length, equals(1));
        // Both dish name (tier 4) and impressions (tier 5) should be highlighted.
        final dishHighlights = results[0].matchHighlights.where((h) => h.field == 'dishName').toList();
        final impHighlights = results[0].matchHighlights.where((h) => h.field == 'impressions').toList();
        expect(dishHighlights.length, equals(1));
        expect(dishHighlights[0].matchedText, contains('Ramen'));
        expect(impHighlights.length, equals(1));
        expect(impHighlights[0].matchedText, contains('ramen'));
      },
    );

    test(
      'P4ME-47 — multiple entries with mixed dish/impressions matches in single pass',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Sushi',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Tokyo',
              journalEntries: [
                JournalEntry(dishName: 'Sushi Platter', impressions: ''),           // dish match only
                JournalEntry(dishName: 'Tempura', impressions: 'Great sushi'),      // impressions match only
                JournalEntry(dishName: 'Sushi Roll', impressions: 'Fresh sushi'),   // both matches
              ],
            ),
          ],
        );
        expect(results.length, equals(1));
        final dishHighlights = results[0].matchHighlights.where((h) => h.field == 'dishName').toList();
        final impHighlights = results[0].matchHighlights.where((h) => h.field == 'impressions').toList();
        // Two dish name matches (Sushi Platter, Sushi Roll) + two impressions matches (Great sushi, Fresh sushi)
        expect(dishHighlights.length, equals(2));
        expect(impHighlights.length, equals(2));
      },
    );

    test(
      'P4ME-47 — single pass handles empty journal entries gracefully',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Ramen',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              journalEntries: [],
            ),
          ],
        );
        expect(results, isEmpty);
      },
    );

    test(
      'P4ME-47 — single pass handles null/empty dish name and impressions',
      () async {
        final service = SearchService();
        // JournalEntry with empty strings should not crash the single-pass loop.
        expect(() => service.search(
          query: 'test',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Test',
              journalEntries: [JournalEntry(dishName: '', impressions: '')],
            ),
          ],
        ), returnsNormally);
      },
    );
  });
}
