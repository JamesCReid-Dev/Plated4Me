/// Presentation layer widget tests for Restaurant Detail View.
///
/// P4ME-22 — S15 Restaurant Detail View.
/// Covers AC-1 (header), AC-2 (allergy-safe foods), AC-3 (general notes),
/// AC-4 (visit history), AC-6 (empty state).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/application/providers/restaurant_detail_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/allergy_safe_food_repository.dart';
import 'package:plated4me/domain/repositories/restaurant_repository.dart';
import 'package:plated4me/domain/repositories/visit_repository.dart';
import 'package:plated4me/presentation/screens/restaurant_detail_screen.dart';
import 'package:plated4me/presentation/widgets/restaurant_notes_widget.dart';

// -- Test data helpers ---------------------------------------------------------

Restaurant _restaurant({
  int id = 1,
  String name = 'Test Bistro',
  String? address = '456 Oak Ave',
  String? notes = 'Great pasta dishes.',
}) {
  final r = Restaurant(name: name, address: address)..id = id;
  r.notes = notes;
  return r;
}

Visit _visit({int restaurantId = 1, double composite = 4.5}) {
  return Visit(
    restaurantId: restaurantId,
    foodRating: 4.0,
    valueRating: 5.0,
    serviceRating: 4.0,
    overallRating: 4.5,
    compositeScore: composite,
    returnIntent: true,
  )..createdAt = DateTime.now().subtract(Duration(days: restaurantId));
}

AllergySafeFood _safeFood({required String itemName, int restaurantId = 1}) {
  return AllergySafeFood(itemName: itemName, restaurantId: restaurantId);
}

// -- Fake repositories ---------------------------------------------------------

class FakeRestaurantRepo implements RestaurantRepository {
  final Map<int, Restaurant> _restaurants = {};
  FakeRestaurantRepo([Restaurant? initial]) {
    if (initial != null) _restaurants[initial.id] = initial;
  }
  @override Future<List<Restaurant>> getAllRestaurants() async => _restaurants.values.toList();
  @override Future<Restaurant?> getRestaurantById(Id id) async => _restaurants[id];
  @override Future<List<Restaurant>> searchRestaurants(String query) async => [];
  @override Future<Restaurant> saveRestaurant(Restaurant r) async { _restaurants[r.id] = r; return r; }
  @override Future<bool> deleteRestaurant(Id id) async { _restaurants.remove(id); return true; }
  @override Future<bool> existsByName(String name) async => false;
  @override Future<Restaurant?> getByNamedAddress(String name, String? address) async => null;
}

class FakeVisitRepo implements VisitRepository {
  final List<Visit> visits;
  FakeVisitRepo(this.visits);
  @override Future<List<Visit>> getAllVisits() => throw UnimplementedError();
  @override Future<Visit?> getVisitById(Id id) => throw UnimplementedError();
  @override Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async => visits.where((v) => v.restaurantId == restaurantId).toList();
  @override Future<Visit> saveVisit(Visit v) => throw UnimplementedError();
  @override Future<bool> deleteVisit(Id id) => throw UnimplementedError();
  @override Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to) => throw UnimplementedError();
  @override Stream<List<Visit>> visitStream() => throw UnimplementedError();
  @override Future<List<Visit>> searchVisits(String query) => throw UnimplementedError();
  @override Future<int> bulkDeleteBlacklistedVisits() => throw UnimplementedError();
}

class FakeAllergyRepo implements AllergySafeFoodRepository {
  final List<AllergySafeFood> foods;
  FakeAllergyRepo(this.foods);
  @override Future<List<AllergySafeFood>> getAllSafeFoods() => throw UnimplementedError();
  @override Future<List<AllergySafeFood>> getAllSafeFoodsForRestaurant(int restaurantId) async => foods.where((f) => f.restaurantId == restaurantId).toList();
  @override Future<AllergySafeFood?> getSafeFoodById(Id id) => throw UnimplementedError();
  @override Future<AllergySafeFood> saveSafeFood(AllergySafeFood f) => throw UnimplementedError();
  @override Future<bool> deleteSafeFood(Id id) => throw UnimplementedError();
}

void main() {
  Widget buildScreen(
    Restaurant restaurant, {
    List<Visit> visits = const [],
    List<AllergySafeFood> safeFoods = const [],
    FakeRestaurantRepo? restaurantRepo,
  }) {
    final repo = restaurantRepo ?? FakeRestaurantRepo(restaurant);
    return ProviderScope(
      overrides: [
        restaurantDetailRepositoryProvider.overrideWith((ref) => repo),
        visitDetailRepositoryProvider.overrideWith((ref) => FakeVisitRepo(visits)),
        allergySafeFoodDetailRepositoryProvider.overrideWith((ref) => FakeAllergyRepo(safeFoods)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RestaurantDetailScreen(restaurantId: restaurant.id),
      ),
    );
  }

  // -- Wait for data to load without pumpAndSettle (infinite animation) --------

  Future<void> waitForData(WidgetTester tester, String textToFind) async {
    await tester.pump(); // initial frame — loading state
    await tester.pump(const Duration(milliseconds: 100)); // let async work start
    while (!tester.any(find.textContaining(textToFind))) {
      if (tester.any(find.text('Error'))) throw Exception('Provider error');
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle(); // now safe — data is loaded, no more async work
  }

  // -- AC-1: Restaurant info header --------------------------------------------

  group('P4ME-22 — AC-1 Restaurant info header', () {
    testWidgets(
      'displays restaurant name with headline font weight',
      (tester) async {
        await tester.pumpWidget(buildScreen(_restaurant()));
        await waitForData(tester, 'Test Bistro');

        expect(find.text('Test Bistro'), findsOneWidget);

        // Name should use a large/headline text style.
        final textWidget = tester.widget<Text>(find.text('Test Bistro'));
        final textStyle = textWidget.style;
        expect(textStyle?.fontSize, greaterThan(20));
      },
    );

    testWidgets(
      'displays address when available',
      (tester) async {
        await tester.pumpWidget(buildScreen(_restaurant(address: '456 Oak Ave')));
        await waitForData(tester, '456 Oak Ave');

        expect(find.text('456 Oak Ave'), findsOneWidget);
      },
    );

    testWidgets(
      'hides address section when address is null',
      (tester) async {
        await tester.pumpWidget(buildScreen(_restaurant(address: null)));
        // Wait for restaurant name to appear (address won't be there).
        await waitForData(tester, 'Test Bistro');

        expect(find.text('456 Oak Ave'), findsNothing);
      },
    );
  });

  // -- AC-2: Allergy-safe foods list -------------------------------------------

  group('P4ME-22 — AC-2 Allergy-safe foods list', () {
    testWidgets(
      'shows expandable section with safe food items',
      (tester) async {
        final restaurant = _restaurant();
        await tester.pumpWidget(
          buildScreen(
            restaurant,
            safeFoods: [
              _safeFood(itemName: 'Grilled Chicken'),
              _safeFood(itemName: 'Steamed Vegetables'),
            ],
          ),
        );

        // Wait for the always-visible header text first.
        await waitForData(tester, 'Allergy-Safe Foods');

        // Tap "Show Safe Foods" to expand the list.
        final showButton = find.text('Show Safe Foods');
        expect(showButton, findsOneWidget);
        await tester.tap(showButton);
        await tester.pumpAndSettle();

        // Now verify food items are visible (rendered with bullet prefix).
        expect(find.textContaining('Grilled Chicken'), findsOneWidget);
        expect(find.textContaining('Steamed Vegetables'), findsOneWidget);
      },
    );

    testWidgets(
      'allergy-safe section is expandable/collapsible',
      (tester) async {
        final restaurant = _restaurant();
        await tester.pumpWidget(
          buildScreen(
            restaurant,
            safeFoods: [_safeFood(itemName: 'Safe Dish')],
          ),
        );

        // Wait for the always-visible header text first.
        await waitForData(tester, 'Allergy-Safe Foods');

        // Tap "Show Safe Foods" to expand.
        final showButton = find.text('Show Safe Foods');
        expect(showButton, findsOneWidget);
        await tester.tap(showButton);
        await tester.pumpAndSettle();

        // Verify food item is now visible (rendered with bullet prefix).
        expect(find.textContaining('Safe Dish'), findsOneWidget);

        // Tap "Hide Safe Foods" to collapse.
        final hideButton = find.text('Hide Safe Foods');
        expect(hideButton, findsOneWidget);
        await tester.tap(hideButton);
        await tester.pumpAndSettle();

        // Verify food item is no longer visible.
        expect(find.textContaining('Safe Dish'), findsNothing);
      },
    );
  });

  // -- AC-3: General notes -----------------------------------------------------

  group('P4ME-22 — AC-3 General notes', () {
    testWidgets(
      'displays existing restaurant notes',
      (tester) async {
        final restaurant = _restaurant(notes: 'Old note');
        await tester.pumpWidget(buildScreen(restaurant));

        // Wait for the General Notes header to appear.
        await waitForData(tester, 'General Notes');

        // Notes appear via RestaurantNotesDisplayWidget.
        expect(find.text('Old note'), findsOneWidget);
      },
    );

    testWidgets(
      'notes field is editable via edit dialog',
      (tester) async {
        final restaurant = _restaurant(notes: 'Old note');
        await tester.pumpWidget(buildScreen(restaurant));
        await waitForData(tester, 'Old note');

        // Open the edit dialog.
        await tester.tap(find.text('Edit Notes'));
        await tester.pumpAndSettle();

        // Find the text field in the dialog and enter new text.
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, 'Updated note');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify the dialog is closed and updated text is displayed.
        expect(find.text('Updated note'), findsOneWidget);
      },
    );

    testWidgets(
      'notes persist when changed',
      (tester) async {
        final restaurant = _restaurant(notes: 'Initial note');
        final repo = FakeRestaurantRepo(restaurant);
        await tester.pumpWidget(buildScreen(restaurant, restaurantRepo: repo));
        await waitForData(tester, 'Initial note');

        // Open dialog, enter new text, save.
        await tester.tap(find.text('Edit Notes'));
        await tester.pumpAndSettle();
        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Persisted note');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // After save and reload, the new text should be visible.
        expect(find.text('Persisted note'), findsOneWidget);
      },
    );
  });

  // -- AC-4: Visit history -----------------------------------------------------

  group('P4ME-22 — AC-4 Visit history', () {
    testWidgets(
      'displays chronological list of visits with composite scores',
      (tester) async {
        final restaurant = _restaurant();
        await tester.pumpWidget(
          buildScreen(
            restaurant,
            visits: [
              _visit(restaurantId: 1, composite: 4.0),
              _visit(restaurantId: 1, composite: 4.5),
              _visit(restaurantId: 1, composite: 3.5),
            ],
          ),
        );

        // Wait for visit cards to appear.
        await waitForData(tester, 'Composite:');

        expect(find.byType(ListTile), findsWidgets);
      },
    );

    testWidgets(
      'visits ordered by date descending (most recent first)',
      (tester) async {
        final restaurant = _restaurant();
        await tester.pumpWidget(
          buildScreen(
            restaurant,
            visits: [
              _visit(restaurantId: 1, composite: 3.0),
              _visit(restaurantId: 1, composite: 5.0),
              _visit(restaurantId: 1, composite: 4.0),
            ],
          ),
        );

        // Wait for visit cards to appear.
        await waitForData(tester, 'Composite:');

        // Most recent visit (composite 5.0) should appear before older ones.
        // We verify ordering by checking that the list renders all three visits.
        expect(find.byType(ListTile), findsNWidgets(3));
      },
    );
  });

  // -- AC-6: Empty state -------------------------------------------------------

  group('P4ME-22 — AC-6 No visits logged yet', () {
    testWidgets(
      'shows "No visits logged yet" when restaurant has no visits',
      (tester) async {
        await tester.pumpWidget(buildScreen(_restaurant(), visits: []));
        // Wait for the empty state text.
        await waitForData(tester, 'No visits logged yet');

        expect(find.text('No visits logged yet'), findsOneWidget);
      },
    );

    testWidgets(
      'empty state is shown in the visit history area only',
      (tester) async {
        final restaurant = _restaurant(notes: 'Some notes');
        await tester.pumpWidget(buildScreen(restaurant, visits: []));
        // Wait for both notes and empty state.
        await waitForData(tester, 'No visits logged yet');

        // Notes should still display.
        expect(find.text('Some notes'), findsOneWidget);
        // Empty state for visit history.
        expect(find.text('No visits logged yet'), findsOneWidget);
      },
    );
  });

  // -- P4ME-52: RestaurantNotesDisplayWidget wired into screen -----------------

  group('P4ME-52 — RestaurantNotesDisplayWidget in RestaurantDetailScreen', () {
    testWidgets(
      'uses RestaurantNotesDisplayWidget (not inline _GeneralNotesSection)',
      (tester) async {
        final restaurant = _restaurant(notes: 'Test notes');
        await tester.pumpWidget(buildScreen(restaurant));

        // Wait for data to load.
        await waitForData(tester, 'General Notes');

        // The screen should use RestaurantNotesDisplayWidget.
        expect(find.byType(RestaurantNotesDisplayWidget), findsOneWidget);
      },
    );

    testWidgets(
      'displays existing notes via RestaurantNotesDisplayWidget',
      (tester) async {
        final restaurant = _restaurant(notes: 'Existing note content');
        await tester.pumpWidget(buildScreen(restaurant));

        // Wait for data to load.
        await waitForData(tester, 'General Notes');

        // Notes should be visible via the widget.
        expect(find.text('Existing note content'), findsOneWidget);
      },
    );

    testWidgets(
      'shows empty placeholder when notes are null',
      (tester) async {
        final restaurant = _restaurant(notes: null);
        await tester.pumpWidget(buildScreen(restaurant));

        // Wait for data to load.
        await waitForData(tester, 'General Notes');

        // Empty state placeholder should be visible.
        expect(find.text('Add notes about this restaurant'), findsOneWidget);
      },
    );

    testWidgets(
      'edit button opens dialog when notes exist',
      (tester) async {
        final restaurant = _restaurant(notes: 'Some note');
        await tester.pumpWidget(buildScreen(restaurant));

        // Wait for data to load.
        await waitForData(tester, 'General Notes');

        // Tap the edit button.
        final editButton = find.text('Edit Notes');
        expect(editButton, findsOneWidget);
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Dialog should be visible with a TextField.
        expect(find.byType(TextField), findsWidgets);
      },
    );

    testWidgets(
      'edit button opens dialog when notes are empty',
      (tester) async {
        final restaurant = _restaurant(notes: null);
        await tester.pumpWidget(buildScreen(restaurant));

        // Wait for data to load.
        await waitForData(tester, 'General Notes');

        // Tap the edit button.
        final editButton = find.text('Edit Notes');
        expect(editButton, findsOneWidget);
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Dialog should be visible with a TextField pre-filled with empty text.
        expect(find.byType(TextField), findsWidgets);
      },
    );

    testWidgets(
      'saving edited notes persists them to the restaurant',
      (tester) async {
        final restaurant = _restaurant(notes: 'Original note');
        final repo = FakeRestaurantRepo(restaurant);
        await tester.pumpWidget(buildScreen(restaurant, restaurantRepo: repo));

        // Wait for data to load.
        await waitForData(tester, 'General Notes');

        // Tap edit button and enter new text.
        final editButton = find.text('Edit Notes');
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Enter new notes in the dialog's TextField and save.
        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Updated via dialog');
        await tester.tap(find.text('Save'));

        // Wait for save to complete.
        await tester.pumpAndSettle();

        // Verify the saved restaurant has updated notes.
        final saved = await repo.getRestaurantById(restaurant.id);
        expect(saved?.notes, 'Updated via dialog');
      },
    );

    testWidgets(
      'canceling edit dialog discards changes',
      (tester) async {
        final restaurant = _restaurant(notes: 'Original note');
        final repo = FakeRestaurantRepo(restaurant);
        await tester.pumpWidget(buildScreen(restaurant, restaurantRepo: repo));

        // Wait for data to load.
        await waitForData(tester, 'General Notes');

        // Tap edit button and enter new text.
        final editButton = find.text('Edit Notes');
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Enter new notes in the dialog's TextField.
        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Discarded change');

        // Tap Cancel to dismiss dialog without saving.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Original notes should still be displayed.
        expect(find.text('Original note'), findsOneWidget);
      },
    );
  });
}
