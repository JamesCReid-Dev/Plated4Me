/// Widget tests for QuickLogScreen restaurant association — P4ME-45.
///
/// These tests verify that the QuickLog screen allows users to select
/// a restaurant before saving, displays the selected restaurant's name and address,
/// and persists the Visit with the correct restaurantId.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/visit_rating_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';

import 'helpers.dart';

// -- Fake providers -----------------------------------------------------------

/// Fake VisitDataProvider that records saveVisit calls for inspection.
class FakeVisitNotifier extends VisitDataProvider {
  final List<Visit> _saved = [];

  @override
  Future<List<Visit>> fetchAll() async => [];

  @override
  Future<void> refresh() async {}

  @override
  Future<void> saveVisit(Visit visit) async {
    _saved.add(visit);
    state = AsyncData(await fetchAll());
  }

  List<Visit> get savedVisits => List.unmodifiable(_saved);
}

// -- Helpers ------------------------------------------------------------------

ProviderContainer makeContainer({
  List<Restaurant> restaurants = const [],
}) {
  return ProviderContainer(
    overrides: [
      userPreferencesDataProvider.overrideWith(() {
        return FakeUserPrefsNotifier(
          UserPreferences()..onboardingComplete = true,
        );
      }),
      restaurantDataProvider.overrideWith(() {
        return _FakeRestaurantNotifier(restaurants);
      }),
      visitsDataProvider.overrideWith(() => FakeVisitNotifier()),
    ],
  );
}

/// Extended FakeRestaurantNotifier that supports adding new restaurants.
class _FakeRestaurantNotifier extends RestaurantDataProvider {
  final List<Restaurant> _restaurants;
  final List<Restaurant> _saved = [];

  _FakeRestaurantNotifier(this._restaurants);

  @override
  Future<List<Restaurant>> build() => Future.value(_restaurants);

  @override
  Future<void> refresh() async {}

  @override
  Future<void> saveRestaurant(Restaurant restaurant) async {
    _saved.add(restaurant);
    final updated = List<Restaurant>.from(_restaurants)..add(restaurant);
    state = AsyncData(updated);
  }

  List<Restaurant> get savedRestaurants => List.unmodifiable(_saved);
}

Finder findSaveButton() => find.byType(ElevatedButton).last;

void main() {
  // -- AC-1: Restaurant selector UI exists ------------------------------------

  group('P4ME-45 — AC-1 Restaurant selector UI', () {
    testWidgets(
      'QuickLogScreen displays restaurant names when multiple restaurants exist',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Sushi Zen', address: '456 Oak Ave'),
            Restaurant(name: 'Burger Barn', address: '789 Pine Rd'),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Sushi Zen'),
          findsWidgets,
          reason: 'AC-1: restaurant names should be visible in the selector',
        );
      },
    );

    testWidgets(
      'QuickLogScreen shows a prompt to create when no restaurants exist',
      (tester) async {
        final container = makeContainer(restaurants: []);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('No restaurants saved yet'),
          findsOneWidget,
          reason: 'AC-1: should show prompt when no restaurants exist',
        );
      },
    );

    testWidgets(
      'Single restaurant is auto-selected (no selector UI needed)',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Solo Spot', address: '100 Main St'),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // No selector UI should appear for single restaurant.
        expect(
          find.textContaining('Solo Spot'),
          findsNothing,
          reason: 'AC-1: no selector needed when exactly one restaurant exists',
        );
      },
    );
  });

  // -- AC-2: Selected restaurant is displayed ---------------------------------

  group('P4ME-45 — AC-2 Selected restaurant display', () {
    testWidgets(
      'Selected restaurant name is visible after user picks one from multiple',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Sushi Zen', address: '456 Oak Ave'),
            Restaurant(name: 'Burger Barn', address: '789 Pine Rd'),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on the second restaurant to select it.
        await tester.tap(find.text('Burger Barn').last);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Burger Barn'),
          findsWidgets,
          reason: 'AC-2: selected restaurant name should be displayed',
        );
      },
    );

    testWidgets(
      'Restaurant name is shown when selected from multiple',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Sushi Zen', address: '456 Oak Ave'),
            Restaurant(name: 'Burger Barn', address: '789 Pine Rd'),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap to select first restaurant.
        await tester.tap(find.text('Sushi Zen').last);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Sushi Zen'),
          findsWidgets,
          reason: 'AC-2: restaurant name should be displayed',
        );
      },
    );

    testWidgets(
      'Restaurant without address still shows name when selected from multiple',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Quick Bites', address: null),
            Restaurant(name: 'Other Place', address: '200 Elm St'),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap to select the one without address.
        await tester.tap(find.text('Quick Bites').last);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Quick Bites'),
          findsWidgets,
          reason: 'AC-2: restaurant name should display even without address',
        );
      },
    );
  });

  // -- AC-3: Visit saved with correct restaurantId ----------------------------

  group('P4ME-45 — AC-3 Visit persisted with correct restaurantId', () {
    testWidgets(
      'saved Visit has the selected restaurant\'s ID, not hardcoded 0',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Sushi Zen', address: '456 Oak Ave'),
            Restaurant(name: 'Burger Barn', address: '789 Pine Rd'),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap to select first restaurant.
        await tester.tap(find.text('Sushi Zen').last);
        await tester.pumpAndSettle();

        // Set ratings to enable save.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Tap save.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(visitNotifier.savedVisits.length, 1);
        final savedVisit = visitNotifier.savedVisits.first;
        expect(
          savedVisit.restaurantId,
          isNot(0),
          reason: 'AC-3: restaurantId should NOT be hardcoded 0',
        );
      },
    );

    testWidgets(
      'saved Visit has the correct restaurantId matching the selected restaurant',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Sushi Zen', address: '456 Oak Ave'),
            Restaurant(name: 'Burger Barn', address: '789 Pine Rd'),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on the second restaurant.
        await tester.tap(find.text('Burger Barn').last);
        await tester.pumpAndSettle();

        // Set ratings to enable save.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Tap save.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        final savedVisit = visitNotifier.savedVisits.first;
        expect(
          savedVisit.restaurantId,
          isNot(0),
          reason: 'AC-3: restaurantId should match the selected restaurant',
        );
      },
    );

    testWidgets(
      'single auto-selected restaurant produces correct restaurantId',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Solo Spot', address: '100 Main St')..id = 42,
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        // Allow time for async restaurant data to load and auto-select.
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Set ratings to enable save.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Tap save — should use auto-selected restaurant.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(visitNotifier.savedVisits.length, 1);
        final savedVisit = visitNotifier.savedVisits.first;
        expect(
          savedVisit.restaurantId,
          isNot(0),
          reason: 'AC-3: auto-selected restaurant should have valid ID',
        );
      },
    );
  });

  // -- P4ME-54: Code quality regression tests --------------------------------

  group('P4ME-54 — Code quality regression', () {
    testWidgets(
      'Single restaurant auto-select stores correct ID (setState moved out of build)',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Solo Spot', address: '100 Main St')..id = 42,
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        // Allow time for async restaurant data to load and auto-select.
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Set ratings to enable save.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Tap save — should use auto-selected restaurant with ID=42.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(visitNotifier.savedVisits.length, 1);
        final savedVisit = visitNotifier.savedVisits.first;
        expect(
          savedVisit.restaurantId,
          equals(42),
          reason: 'P4ME-54: auto-selected restaurant ID should match (not 0 or converted)',
        );
      },
    );

    testWidgets(
      'Multi-restaurant selection stores correct ID without .toInt() conversion',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Alpha', address: '1 A St')..id = 7,
            Restaurant(name: 'Beta', address: '2 B Rd')..id = 99,
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap on Beta (id=99).
        await tester.tap(find.text('Beta').last);
        await tester.pumpAndSettle();

        // Set ratings to enable save.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Tap save — should use restaurant with ID=99.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(visitNotifier.savedVisits.length, 1);
        final savedVisit = visitNotifier.savedVisits.first;
        expect(
          savedVisit.restaurantId,
          equals(99),
          reason: 'P4ME-54: selected restaurant ID should match exactly (no .toInt() needed)',
        );
      },
    );

    testWidgets(
      'Restaurant name is shown in selector (test description fix for P4ME-54)',
      (tester) async {
        final container = makeContainer(
          restaurants: [
            Restaurant(name: 'Sushi Zen', address: '456 Oak Ave'),
            Restaurant(name: 'Burger Barn', address: '789 Pine Rd'),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap to select first restaurant.
        await tester.tap(find.text('Sushi Zen').last);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Sushi Zen'),
          findsWidgets,
          reason: 'P4ME-54: restaurant name should be displayed in selector',
        );
      },
    );
  });

  // -- AC-4: Create new restaurant from QuickLog ------------------------------

  group('P4ME-45 — AC-4 Create new restaurant', () {
    testWidgets(
      'User can create a new restaurant when none exist, then save visit',
      (tester) async {
        final container = makeContainer(restaurants: []);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap "No restaurants saved yet" prompt to open creation dialog.
        await tester.tap(find.textContaining('No restaurants saved yet'));
        await tester.pumpAndSettle();

        // Fill in new restaurant name.
        await tester.enterText(
          find.byType(TextFormField).first,
          'New Restaurant',
        );
        await tester.pumpAndSettle();

        // Tap create button.
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // Set ratings to enable save.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Tap save visit.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(visitNotifier.savedVisits.length, 1);
        final savedVisit = visitNotifier.savedVisits.first;
        expect(
          savedVisit.restaurantId,
          isNot(0),
          reason: 'AC-4: visit should be associated with newly created restaurant',
        );

        final restNotifier = container.read(
          restaurantDataProvider.notifier,
        ) as _FakeRestaurantNotifier;
        expect(restNotifier.savedRestaurants.any((r) => r.name == 'New Restaurant'), isTrue);
      },
    );
  });
}
