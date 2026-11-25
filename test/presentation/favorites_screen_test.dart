/// Widget tests for Favorites feature — P4ME-20 (S13).
///
/// Tests BrowseScreen favorites section (AC-4) and FavoritesScreen display/empty state (AC-6).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/favorites_provider.dart';
import 'package:plated4me/application/providers/search_provider.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/application/services/favorites_service.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/screens/browse_screen.dart';
import 'package:plated4me/presentation/screens/favorites_screen.dart';

// -- Test helpers ------------------------------------------------------------

/// Builds a container with pre-computed favorites.
ProviderContainer _favoritesContainer({
  required List<Restaurant> restaurants,
  required List<Visit> visits,
}) {
  final favorites = FavoritesService.computeFavorites(restaurants, visits);

  // Build FilteredVisits from the raw data for BrowseScreen override.
  final restaurantMap = <int, Restaurant>{};
  for (final r in restaurants) {
    restaurantMap[r.id] = r;
  }
  final unknownRestaurant = Restaurant(name: 'Unknown Restaurant');
  final filteredVisits = visits.map((visit) {
    final restaurant = restaurantMap[visit.restaurantId] ?? unknownRestaurant;
    return FilteredVisit(visit: visit, restaurant: restaurant);
  }).toList();

  return ProviderContainer(
    overrides: [
      // Override data providers for FavoritesNotifier.
      restaurantDataProvider.overrideWith(() => FakeRestaurantNotifier(restaurants)),
      visitsDataProvider.overrideWith(() => FakeVisitNotifier(visits)),
      // Override favorites provider with pre-computed value.
      favoritesProvider.overrideWith(() => _FakeFavoritesNotifier(favorites)),
      // Override visit list filter for BrowseScreen.
      visitsListFilterProvider.overrideWith(
        () => _FakeVisitListFilterNotifier(filteredVisits),
      ),
      // Override search provider to return no active search.
      searchProvider.overrideWith(() => FakeSearchNotifier()),
    ],
  );
}

/// Minimal fake notifier for testing FavoritesScreen UI — extends real type.
class _FakeFavoritesNotifier extends FavoritesNotifier {
  final List<Restaurant> _favorites;
  _FakeFavoritesNotifier(this._favorites);

  @override
  List<Restaurant> build() => _favorites;

  @override
  void refresh() {}

  @override
  Future<void> togglePin(Id restaurantId) async {}
}

/// Fake AsyncNotifier for visits list filter — extends real type.
class _FakeVisitListFilterNotifier extends VisitListFilterNotifier {
  final List<FilteredVisit> _visits;
  _FakeVisitListFilterNotifier(this._visits);

  @override
  Future<List<FilteredVisit>> build() async => _visits;

  @override
  Future<void> refresh() async {}
}

/// Fake notifier for search state — extends real type.
class FakeSearchNotifier extends SearchNotifier {
  @override
  SearchState build() => const SearchState();

  void refresh() {}
}

/// Fake notifier for restaurants.
class FakeRestaurantNotifier extends RestaurantDataProvider {
  final List<Restaurant> _restaurants;
  FakeRestaurantNotifier(this._restaurants);

  @override
  Future<List<Restaurant>> build() => Future.value(_restaurants);

  @override
  Future<void> refresh() async {}
}

/// Fake notifier for visits.
class FakeVisitNotifier extends VisitDataProvider {
  final List<Visit> _visits;
  FakeVisitNotifier(this._visits);

  @override
  Future<List<Visit>> build() => Future.value(_visits);

  @override
  Future<void> refresh() async {}
}

// -- AC-4: Favorites section in BrowseScreen ----------------------------------

void main() {
  group('BrowseScreen — AC-4: Favorites section', () {
    testWidgets(
      'Favorites section appears at top when auto-surfaced criteria are met',
      (tester) async {
        final restaurants = [
          Restaurant(name: 'Top Spot')..id = 1,
          Restaurant(name: 'Meh Place')..id = 2,
        ];
        final visits = <Visit>[
          // Top Spot qualifies: 2 visits, high score, return intent
          _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
          _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false),
          // Meh Place excluded: only 1 visit
          _visit(restaurantId: 2, compositeScore: 5.0, returnIntent: true),
        ];

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _favoritesContainer(restaurants: restaurants, visits: visits),
            child: const MaterialApp(home: BrowseScreen()),
          ),
        );

        // Pump to resolve async providers.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Favorites section header visible.
        expect(find.text('Favorites'), findsOneWidget);
        // Favorite restaurant name visible.
        expect(find.text('Top Spot'), findsWidgets);
      },
    );

    testWidgets(
      'Favorites section hidden when no restaurants qualify',
      (tester) async {
        final restaurants = [Restaurant(name: 'Meh Place')..id = 1];
        final visits = <Visit>[
          // Only 1 visit — doesn't qualify
          _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
        ];

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _favoritesContainer(restaurants: restaurants, visits: visits),
            child: const MaterialApp(home: BrowseScreen()),
          ),
        );

        expect(find.text('Favorites'), findsNothing);
      },
    );
  });

  group('FavoritesScreen — AC-6: Empty state', () {
    testWidgets(
      'Empty state shows informational message when no favorites exist',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _favoritesContainer(restaurants: [], visits: []),
            child: const MaterialApp(home: FavoritesScreen()),
          ),
        );

        expect(
          find.text('Favorites appear here when you have 2+ great visits with a return intent.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Empty state is informational only — no actionable buttons',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _favoritesContainer(restaurants: [], visits: []),
            child: const MaterialApp(home: FavoritesScreen()),
          ),
        );

        // No buttons or interactive elements in empty state.
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );
  });

  group('FavoritesScreen — AC-1: Restaurant display', () {
    testWidgets(
      'Displays favorite restaurant names and addresses',
      (tester) async {
        final restaurants = [Restaurant(name: 'Top Spot', address: '456 Oak Ave')..id = 1];
        final visits = <Visit>[
          _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
          _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false),
        ];

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _favoritesContainer(restaurants: restaurants, visits: visits),
            child: const MaterialApp(home: FavoritesScreen()),
          ),
        );

        expect(find.text('Top Spot'), findsOneWidget);
        expect(find.text('456 Oak Ave'), findsOneWidget);
      },
    );

    testWidgets(
      'Shows pin toggle button on each favorite',
      (tester) async {
        final restaurants = [Restaurant(name: 'Pinned Place')..id = 1];
        final visits = <Visit>[
          _visit(restaurantId: 1, compositeScore: 5.0, returnIntent: true),
          _visit(restaurantId: 1, compositeScore: 4.8, returnIntent: false),
        ];

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _favoritesContainer(restaurants: restaurants, visits: visits),
            child: const MaterialApp(home: FavoritesScreen()),
          ),
        );

        expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      },
    );
  });
}

/// Creates a visit with the given fields.
Visit _visit({
  required int restaurantId,
  double foodRating = 5.0,
  double valueRating = 5.0,
  double serviceRating = 5.0,
  double overallRating = 5.0,
  double compositeScore = 5.0,
  bool returnIntent = false,
}) {
  return Visit(
    restaurantId: restaurantId,
    foodRating: foodRating,
    valueRating: valueRating,
    serviceRating: serviceRating,
    overallRating: overallRating,
    compositeScore: compositeScore,
    returnIntent: returnIntent,
  );
}
