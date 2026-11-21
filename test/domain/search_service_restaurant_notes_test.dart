/// Domain layer tests for SearchService with Restaurant.notes support.
///
/// P4ME-19 — Restaurant General Notes.
/// Covers AC-4: Notes included in full-text search results.

import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/services/search_service.dart';

// -- Test data helpers --------------------------------------------------------

FilteredVisit _makeFilteredVisit({
  required String restaurantName,
  int? restaurantId,
  String? address,
  String? restaurantNotes,
  List<JournalEntry>? journalEntries,
  List<String>? occasions,
  String? employeeName,
  String? generalNotes,
}) {
  final id = restaurantId ?? restaurantName.hashCode;
  final restaurant = Restaurant(name: restaurantName, address: address)
    ..id = id
    ..notes = restaurantNotes;
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
  group('P4ME-19 — SearchService with Restaurant.notes', () {
    test(
      'AC-4 — searching by restaurant notes returns matching visits',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'great ambiance',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              restaurantNotes: 'Great ambiance and friendly staff',
            ),
            _makeFilteredVisit(restaurantName: 'Pizza Place'),
          ],
        );
        expect(results.length, equals(1));
        expect(results[0].restaurant.name, equals('Sakura'));
      },
    );

    test(
      'AC-4 — restaurant notes search is case-insensitive',
      () async {
        final service = SearchService();
        final resultsUpper = service.search(
          query: 'GREAT AMBIANCE',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              restaurantNotes: 'Great ambiance',
            ),
          ],
        );
        expect(resultsUpper.length, equals(1));

        final resultsLower = service.search(
          query: 'great ambiance',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura',
              restaurantNotes: 'GREAT AMBIANCE',
            ),
          ],
        );
        expect(resultsLower.length, equals(1));
      },
    );

    test(
      'AC-4 — restaurant notes match ranks below address, above employee name',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'cozy',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Cafe A',
              address: 'Cozy Lane', // tier 3 — address
              restaurantNotes: 'Very cozy interior', // tier 6 — notes
            ),
            _makeFilteredVisit(
              restaurantName: 'Cafe B',
              employeeName: 'Cozy', // tier 7 — employee
              restaurantNotes: 'Not cozy at all', // tier 6 — notes
            ),
          ],
        );
        expect(results.length, equals(2));
        // Address match (tier 3) should rank above notes (tier 6).
        expect(results[0].restaurant.name, equals('Cafe A'));
        // Notes match (tier 6) should rank above employee (tier 7).
        expect(results[1].restaurant.name, equals('Cafe B'));
      },
    );

    test(
      'AC-4 — restaurant notes with no visit data still surfaces restaurant',
      () async {
        final service = SearchService();
        // A restaurant with notes but the search only finds via notes.
        final results = service.search(
          query: 'hidden gem',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Hidden Spot',
              restaurantNotes: 'A hidden gem of a place',
            ),
          ],
        );
        expect(results.length, equals(1));
        // The match highlight should reference restaurant notes.
        final noteHighlights = results[0].matchHighlights.where((h) => h.field == 'restaurantNotes').toList();
        expect(noteHighlights.isNotEmpty, isTrue);
      },
    );

    test(
      'AC-4 — empty restaurant notes do not produce false matches',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'nonexistent',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Empty Notes',
              restaurantNotes: '',
            ),
            _makeFilteredVisit(
              restaurantName: 'Null Notes',
              restaurantNotes: null,
            ),
          ],
        );
        expect(results, isEmpty);
      },
    );

    test(
      'AC-4 — match highlights include restaurant notes field',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'romantic',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Romance',
              restaurantNotes: 'Very romantic setting',
            ),
          ],
        );
        expect(results.length, equals(1));
        final noteHighlights = results[0].matchHighlights.where((h) => h.field == 'restaurantNotes').toList();
        expect(noteHighlights, hasLength(1));
        expect(noteHighlights[0].tier, equals(6));
      },
    );

    test(
      'AC-4 — restaurant name exact match still ranks above notes',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Sakura',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura Garden',
              restaurantNotes: 'Named after Sakura flowers', // tier 6 — notes match
            ),
            _makeFilteredVisit(restaurantName: 'Sakura'), // tier 1 — exact name
          ],
        );
        expect(results.length, equals(2));
        expect(results[0].restaurant.name, equals('Sakura')); // tier 1 first
      },
    );

    test(
      'AC-4 — multi-word query matches restaurant notes',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'friendly staff',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Corner Diner',
              restaurantNotes: 'Known for friendly staff and home cooking',
            ),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-4 — partial word match in notes works',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'cozin',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Brazilian Grill',
              restaurantNotes: 'Authentic cozinhas brasileiras',
            ),
          ],
        );
        expect(results.length, equals(1));
      },
    );

    test(
      'AC-4 — notes search does not interfere with other tier searches',
      () async {
        final service = SearchService();
        final results = service.search(
          query: 'Sakura',
          visits: [
            _makeFilteredVisit(
              restaurantName: 'Sakura', // tier 1 — exact name
              restaurantNotes: 'Not about sakura at all', // also contains "sakura"
            ),
          ],
        );
        expect(results.length, equals(1));
        // Best tier should be 1 (exact name), not 6 (notes).
        expect(results[0].bestTier, equals(1));
      },
    );

    test(
      'Performance — restaurant notes search does not exceed 200ms for 500 visits',
      () async {
        final service = SearchService();
        final visits = List.generate(500, (i) => _makeFilteredVisit(
          restaurantName: 'Restaurant $i',
          address: '$i Some Street',
          restaurantNotes: i % 2 == 0 ? 'Notes for restaurant $i' : null,
          occasions: ['Occasion $i'],
          employeeName: 'Server $i',
          generalNotes: 'Visit notes $i',
          journalEntries: [JournalEntry(dishName: 'Dish $i', impressions: 'Tasty')],
        ));

        final stopwatch = Stopwatch()..start();
        service.search(query: 'Restaurant', visits: visits);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      },
    );
  });
}
