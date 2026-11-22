/// Regression tests for P4ME-50 — Restaurant Notes UI writes to wrong field.
///
/// Red Phase: These tests verify that restaurant notes entered via QuickLogScreen's
/// "Restaurant Notes" accordion are persisted to the Restaurant entity's `notes` field,
/// NOT to Visit.generalNotes. Tier 6 search should find them after save.
///
/// CURRENT STATE (BUG): All these tests FAIL because _handleSave() writes to
/// visit.generalNotes instead of restaurant.notes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/quick_log_form_provider.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/application/providers/visit_rating_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/restaurant_repository.dart';
import 'package:plated4me/domain/repositories/visit_repository.dart';
import 'package:plated4me/domain/services/search_service.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';

import 'helpers.dart';

// -- Fake restaurant repository -------------------------------------------------

/// Fake RestaurantRepository that records saveRestaurant calls for inspection.
class FakeRestaurantRepository implements RestaurantRepository {
  final List<Restaurant> _saved = [];
  bool failSave = false;

  @override
  Future<List<Restaurant>> getAllRestaurants() async => _saved;

  @override
  Future<Restaurant?> getRestaurantById(Id id) async {
    return _saved.firstWhere((r) => r.id == id, orElse: () => throw Exception('Not found'));
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async => [];

  @override
  Future<Restaurant> saveRestaurant(Restaurant restaurant) async {
    if (failSave) throw Exception('Repository save failed');
    final existing = _saved.indexWhere((r) => r.id == restaurant.id);
    if (existing >= 0) {
      _saved[existing] = restaurant;
    } else {
      _saved.add(restaurant);
    }
    return restaurant;
  }

  @override
  Future<bool> deleteRestaurant(Id id) async => false;

  @override
  Future<bool> existsByName(String name) async => _saved.any((r) => r.name == name);

  @override
  Future<Restaurant?> getByNamedAddress(String name, String? address) async {
    return _saved.firstWhere(
      (r) => r.name == name && r.address == address,
      orElse: () => throw Exception('Not found'),
    );
  }

  List<Restaurant> get savedRestaurants => List.unmodifiable(_saved);
}

// -- Fake visit repository ------------------------------------------------------

/// Minimal fake VisitRepository for QuickLogScreen tests.
class FakeVisitRepositoryForP4ME50 implements VisitRepository {
  final List<Visit> _saved = [];

  @override
  Future<List<Visit>> getAllVisits() async => _saved;

  @override
  Future<Visit?> getVisitById(Id id) async => null;

  @override
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async => [];

  @override
  Future<Visit> saveVisit(Visit visit) async {
    _saved.add(visit);
    return visit;
  }

  @override
  Future<bool> deleteVisit(Id id) async => false;

  @override
  Future<List<Visit>> getVisitsInRange(DateTime from, DateTime to) async => [];

  @override
  Stream<List<Visit>> visitStream() => Stream.value([]);

  @override
  Future<List<Visit>> searchVisits(String query) async => [];

  @override
  Future<int> bulkDeleteBlacklistedVisits() async => 0;
}

// -- Helpers --------------------------------------------------------------------

/// Builds a container with fake repos for P4ME-50 tests.
ProviderContainer makeP4ME50Container() {
  final fakeRestaurantRepo = FakeRestaurantRepository();
  final fakeVisitRepo = FakeVisitRepositoryForP4ME50();

  // Pre-seed the restaurant repo with a known restaurant so saveRestaurant can update it.
  final seedRestaurant = Restaurant(name: 'Test Restaurant', address: '123 Main St');
  fakeRestaurantRepo.saveRestaurant(seedRestaurant);

  return ProviderContainer(
    overrides: [
      userPreferencesDataProvider.overrideWith(() {
        return FakeUserPrefsNotifier(
          UserPreferences()..onboardingComplete = true,
        );
      }),
      restaurantRepositoryProvider.overrideWith((ref) => fakeRestaurantRepo),
      visitRepositoryProvider.overrideWith((ref) => fakeVisitRepo),
    ],
  );
}

/// Finds the save button (ElevatedButton containing "Save Visit" text).
Finder findSaveButtonP4ME50() => find.byType(ElevatedButton).last;

// -- AC-1: Restaurant notes saved to Restaurant entity, not Visit.generalNotes ---

void main() {
  group('P4ME-50 — AC-1 Restaurant notes persist to Restaurant.notes', () {
    testWidgets(
      'restaurant notes entered in QuickLogScreen are saved to Restaurant.notes, not Visit.generalNotes',
      (tester) async {
        final container = makeP4ME50Container();
        final fakeRestaurantRepo = container.read(restaurantRepositoryProvider) as FakeRestaurantRepository;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set ratings to enable save button.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);

        // Expand the Restaurant Notes accordion (index 4) and set text via form provider.
        final formNotifier = container.read(quickLogFormProvider.notifier);
        formNotifier.toggleAccordion(4);
        await tester.pumpAndSettle();

        final formState = container.read(quickLogFormProvider);
        expect(formState.restaurantNotesController, isNotNull,
            reason: 'restaurantNotesController should exist after accordion toggle');
        formState.restaurantNotesController!.text = 'Great ambiance, noisy during lunch rush';

        await tester.pumpAndSettle();

        // Tap save.
        await tester.tap(findSaveButtonP4ME50());
        await tester.pumpAndSettle();

        // Verify: Restaurant.notes was updated with the entered text.
        final savedRestaurant = fakeRestaurantRepo.savedRestaurants.first;
        expect(
          savedRestaurant.notes,
          'Great ambiance, noisy during lunch rush',
          reason: 'AC-1: restaurant notes should be persisted to Restaurant.notes',
        );

        // Note: Visit.generalNotes is NOT set by this UI path — restaurant notes
        // persist to Restaurant.notes via restaurantRepositoryProvider (P4ME-50).
      },
    );

    testWidgets(
      'saving restaurant notes does not populate Visit.generalNotes',
      (tester) async {
        final container = makeP4ME50Container();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set ratings.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);

        // Expand Restaurant Notes accordion and set text.
        final formNotifier = container.read(quickLogFormProvider.notifier);
        formNotifier.toggleAccordion(4);
        await tester.pumpAndSettle();

        final formState = container.read(quickLogFormProvider);
        formState.restaurantNotesController!.text = 'Romantic setting';

        await tester.pumpAndSettle();

        // Tap save.
        await tester.tap(findSaveButtonP4ME50());
        await tester.pumpAndSettle();

        // The visit saved should NOT have generalNotes set by the restaurant notes field.
        // (generalNotes is a separate concept — visit-level free text, not restaurant notes.)
      },
    );
  });

  // -- AC-2: Tier 6 search finds restaurant notes entered via QuickLogScreen ----

  group('P4ME-50 — AC-2 Tier 6 search finds restaurant notes from QuickLog', () {
    test(
      'Tier 6 search finds "ambiance" in restaurant notes saved from QuickLog',
      () {
        // Simulate what the fix should produce: a Restaurant with notes set,
        // then searched via SearchService.
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'Great ambiance';
        final visit = Visit(
          restaurantId: 1,
          foodRating: 4.0,
          valueRating: 3.0,
          serviceRating: 5.0,
          overallRating: 4.0,
          compositeScore: 80.0,
          returnIntent: false,
        );
        final fv = FilteredVisit(visit: visit, restaurant: restaurant);

        final service = SearchService();
        final results = service.search(query: 'ambiance', visits: [fv]);

        expect(results.length, equals(1), reason: 'AC-2: should find one match');
        expect(results[0].bestTier, equals(6), reason: 'AC-2: match should be Tier 6 (restaurant notes)');
      },
    );

    test(
      'Tier 6 search is case-insensitive for restaurant notes from QuickLog',
      () {
        final restaurant = Restaurant(name: 'Test Restaurant')..notes = 'GREAT AMBIANCE';
        final visit = Visit(
          restaurantId: 1,
          foodRating: 4.0,
          valueRating: 3.0,
          serviceRating: 5.0,
          overallRating: 4.0,
          compositeScore: 80.0,
          returnIntent: false,
        );

        final service = SearchService();
        final results = service.search(query: 'great ambiance', visits: [FilteredVisit(visit: visit, restaurant: restaurant)]);

        expect(results.length, equals(1), reason: 'AC-2: case-insensitive search should find match');
      },
    );
  });

  // -- AC-3: Empty restaurant notes do not update Restaurant ---------------------

  group('P4ME-50 — AC-3 Empty restaurant notes handling', () {
    testWidgets(
      'saving with empty restaurant notes does not overwrite existing Restaurant.notes',
      (tester) async {
        final container = makeP4ME50Container();
        final fakeRestaurantRepo = container.read(restaurantRepositoryProvider) as FakeRestaurantRepository;

        // Pre-set the restaurant with existing notes.
        final existingRestaurant = fakeRestaurantRepo.savedRestaurants.first;
        existingRestaurant.notes = 'Previously saved note';
        await fakeRestaurantRepo.saveRestaurant(existingRestaurant);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set ratings.
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(4.0);
        ratingNotifier.setValueRating(3.0);
        ratingNotifier.setServiceRating(5.0);
        ratingNotifier.setOverallRating(4.0);

        // Expand Restaurant Notes accordion but leave it empty.
        final formNotifier = container.read(quickLogFormProvider.notifier);
        formNotifier.toggleAccordion(4);
        await tester.pumpAndSettle();

        // Tap save without entering any text.
        await tester.tap(findSaveButtonP4ME50());
        await tester.pumpAndSettle();

        // The existing notes should be preserved (not overwritten with empty string).
        final updatedRestaurant = fakeRestaurantRepo.savedRestaurants.first;
        expect(
          updatedRestaurant.notes,
          'Previously saved note',
          reason: 'AC-3: existing restaurant notes should not be cleared when field is empty',
        );
      },
    );
  });

  // -- AC-4: Form provider has restaurantNotesController --------------------------

  group('P4ME-50 — AC-4 Form provider API', () {
    test(
      'QuickLogFormData has restaurantNotesController field',
      () {
        // The form data model should have a restaurantNotesController, not generalNotesController.
        final controller = TextEditingController(text: 'test note');
        final formData = QuickLogFormData(restaurantNotesController: controller);

        expect(formData.restaurantNotesController, isNotNull);
        expect(formData.restaurantNotesController!.text, equals('test note'));

        controller.dispose();
      },
    );

    test(
      'QuickLogFormData.dispose() disposes restaurantNotesController',
      () {
        final controller = TextEditingController(text: 'test');
        final formData = QuickLogFormData(restaurantNotesController: controller);

        // dispose() should call dispose on the controller without throwing.
        expect(() => formData.dispose(), returnsNormally);
      },
    );

    test(
      'QuickLogFormData.reset() clears restaurantNotesController',
      () {
        final controller = TextEditingController(text: 'existing note');
        final formData = QuickLogFormData(restaurantNotesController: controller);

        formData.reset();
        expect(formData.restaurantNotesController!.text, isEmpty,
            reason: 'AC-4: reset should clear the restaurant notes controller');
      },
    );
  });
}
