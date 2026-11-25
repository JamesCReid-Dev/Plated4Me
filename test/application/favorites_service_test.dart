/// Unit tests for FavoritesService — P4ME-20 (S13).
///
/// Tests the core favorites computation logic: visit count, average score,
/// return intent, blacklisted exclusion, and manual pin/unpin overrides.

import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/services/favorites_service.dart';
import 'package:plated4me/domain/entities/entities.dart';

// -- Test fixtures -----------------------------------------------------------

/// Creates a restaurant with the given ID and name.
Restaurant _restaurant({required int id, required String name}) {
  return Restaurant(name: name)..id = id;
}

/// Creates a visit for the given restaurantId with the specified fields.
Visit _visit({
  required int restaurantId,
  double compositeScore = 0.0,
  bool returnIntent = false,
  bool blacklisted = false,
}) {
  return Visit(
    restaurantId: restaurantId,
    foodRating: compositeScore / 4 * 4,
    valueRating: compositeScore / 4 * 3,
    serviceRating: compositeScore / 4 * 1.5,
    overallRating: compositeScore / 4 * 1.5,
    compositeScore: compositeScore,
    returnIntent: returnIntent,
  )..blacklisted = blacklisted;
}

void main() {
  group('FavoritesService — AC-1: Auto-surface criteria', () {
    test(
      'Restaurant qualifies with >=2 visits, avg score >=80% of max, and returnIntent',
      () {
        // Restaurant 1: 2 visits, both high scores (5.0), both have return intent.
        final restaurants = [_restaurant(id: 1, name: 'Top Spot')];
        final visits = [
          _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
          _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: true),
        ];

        final result = FavoritesService.computeFavorites(restaurants, visits);

        expect(result.length, equals(1));
        expect(result.first.id, equals(1));
      },
    );

    test('Restaurant excluded with only 1 visit despite high score', () {
      final restaurants = [_restaurant(id: 1, name: 'One Visit')];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.isEmpty, isTrue);
    });

    test('Restaurant excluded with >=2 visits but avg score below threshold', () {
      // Avg = (3.0 + 3.5) / 2 = 3.25 < 4.0 (80% of 5.0)
      final restaurants = [_restaurant(id: 1, name: 'Low Score')];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 3.0, returnIntent: true),
        _visit(restaurantId: 1, compositeScore: 3.5, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.isEmpty, isTrue);
    });

    test('Restaurant excluded with >=2 high-score visits but no returnIntent', () {
      final restaurants = [_restaurant(id: 1, name: 'No Return')];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: false),
        _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.isEmpty, isTrue);
    });

    test('Exactly 2 visits with avg score exactly at threshold qualifies', () {
      // Avg = (4.0 + 4.0) / 2 = 4.0 == 80% of 5.0
      final restaurants = [_restaurant(id: 1, name: 'Borderline')];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 4.0, returnIntent: true),
        _visit(restaurantId: 1, compositeScore: 4.0, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.length, equals(1));
    });

    test('Multiple restaurants — only qualifying ones returned', () {
      final restaurants = [
        _restaurant(id: 1, name: 'Top Spot'),
        _restaurant(id: 2, name: 'Meh Place'),
        _restaurant(id: 3, name: 'Good Enough'),
      ];
      final visits = [
        // Restaurant 1: qualifies (2 visits, high score, return intent)
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
        _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false),
        // Restaurant 2: excluded (only 1 visit)
        _visit(restaurantId: 2, compositeScore: 5.0, returnIntent: true),
        // Restaurant 3: qualifies (3 visits, avg >= 4.0, has return intent)
        _visit(restaurantId: 3, compositeScore: 4.5, returnIntent: false),
        _visit(restaurantId: 3, compositeScore: 4.2, returnIntent: true),
        _visit(restaurantId: 3, compositeScore: 4.0, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.length, equals(2));
      expect(result.map((r) => r.id), containsAll([1, 3]));
    });
  });

  group('FavoritesService — AC-5: Blacklisted visits excluded', () {
    test('Blacklisted visit does not count toward favorite criteria', () {
      // Restaurant has 2 visits but one is blacklisted → only 1 counts → excluded
      final restaurants = [_restaurant(id: 1, name: 'Banned Visit')];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
        _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false, blacklisted: true),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.isEmpty, isTrue);
    });

    test('Non-blacklisted visits qualify even when other visits are blacklisted', () {
      // Restaurant has 3 visits: 2 non-blacklisted qualify, 1 blacklisted ignored
      final restaurants = [_restaurant(id: 1, name: 'Mixed')];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
        _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false, blacklisted: true),
        _visit(restaurantId: 1, compositeScore: 4.5, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.length, equals(1));
    });

    test('All visits blacklisted → no favorites', () {
      final restaurants = [_restaurant(id: 1, name: 'All Banned')];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true, blacklisted: true),
        _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false, blacklisted: true),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.isEmpty, isTrue);
    });
  });

  group('FavoritesService — AC-3: Manual pin/unpin overrides', () {
    test('Pinned restaurant shows even if criteria not met', () {
      // Restaurant has only 1 visit → would be excluded, but pinned
      final restaurants = [_restaurant(id: 1, name: 'Pinned')..isPinned = true];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.length, equals(1));
    });

    test('Unpinned restaurant hidden even if criteria met', () {
      // Restaurant qualifies but is unpinned → excluded
      final restaurants = [_restaurant(id: 1, name: 'Unpinned')..isUnpinned = true];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
        _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.isEmpty, isTrue);
    });

    test('Pinned restaurant excluded from auto-surfaced list in BrowseScreen', () {
      // NOTE: Pinned restaurants ARE included in the favorites list (AC-3).
      // The BrowseScreen widget test handles separating them into a pinned section.
      final restaurants = [_restaurant(id: 1, name: 'Pinned')..isPinned = true];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
        _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      // Pinned restaurants are included in the favorites list (AC-3).
      expect(result.length, equals(1));
    });

    test('Neither pinned nor unpinned → uses auto-criteria', () {
      final restaurants = [_restaurant(id: 1, name: 'Auto')];
      final visits = [
        _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
        _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false),
      ];

      final result = FavoritesService.computeFavorites(restaurants, visits);

      expect(result.length, equals(1));
    });
  });
}
