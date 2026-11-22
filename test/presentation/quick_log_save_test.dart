/// Widget tests for QuickLogScreen save behaviour — P4ME-40 (visit persistence defect).
///
/// Red Phase: These tests verify that pressing "Save Visit" constructs and persists
/// a Visit entity via visitsDataProvider, then navigates back. All tests FAIL because
/// _handleSave() is currently a TODO stub that only calls Navigator.pop().
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/quick_log_form_provider.dart';
import 'package:plated4me/application/providers/visit_rating_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/visit_repository.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';

import 'helpers.dart';

// -- Fake visit data provider ---------------------------------------------------

/// Fake VisitDataProvider that records saveVisit calls for inspection.
class FakeVisitNotifier extends VisitDataProvider {
  final List<Visit> _saved = [];
  bool failNext = false;

  @override
  Future<List<Visit>> fetchAll() async => [];

  @override
  Future<void> refresh() async {}

  @override
  Future<void> saveVisit(Visit visit) async {
    try {
      if (failNext) {
        throw Exception('Save failed');
      }
      _saved.add(visit);
      state = AsyncData(await fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  List<Visit> get savedVisits => List.unmodifiable(_saved);
}

/// Fake VisitRepository that can be configured to fail on save.
class FakeVisitRepository implements VisitRepository {
  final bool failSave;
  FakeVisitRepository({this.failSave = false});

  @override
  Future<List<Visit>> getAllVisits() async => [];

  @override
  Future<Visit?> getVisitById(Id id) async => null;

  @override
  Future<List<Visit>> getVisitsByRestaurantId(int restaurantId) async => [];

  @override
  Future<Visit> saveVisit(Visit visit) async {
    if (failSave) throw Exception('Repository save failed');
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

/// Builds a container with default prefs, restaurants, and a fake visit provider.
ProviderContainer makeContainer({bool failSave = false}) {
  return ProviderContainer(
    overrides: [
      userPreferencesDataProvider.overrideWith(() {
        return FakeUserPrefsNotifier(
          UserPreferences()..onboardingComplete = true,
        );
      }),
      restaurantDataProvider.overrideWith(() {
        return FakeRestaurantNotifier([
          Restaurant(name: 'Test Restaurant', address: '123 Main St'),
        ]);
      }),
      visitsDataProvider.overrideWith(
        () => FakeVisitNotifier()..failNext = failSave,
      ),
    ],
  );
}

/// Finds the save button (ElevatedButton containing "Save Visit" text).
Finder findSaveButton() => find.byType(ElevatedButton).last;

// -- AC-1: Save Visit persists data ---------------------------------------------

void main() {
  group('P4ME-40 — AC-1 Save Visit persists data', () {
    testWidgets(
      'saveVisit is called on visitsDataProvider when save button is pressed with valid ratings',
      (tester) async {
        final container = makeContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set all four ratings to make save button enabled.
        final notifier = container.read(visitRatingProvider.notifier);
        notifier.setFoodRating(4.0);
        notifier.setValueRating(3.0);
        notifier.setServiceRating(5.0);
        notifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Verify save button is now enabled (green).
        final saveButton = tester.widget<ElevatedButton>(findSaveButton());
        expect(saveButton.onPressed, isNotNull,
            reason: 'Save button should be enabled with valid ratings');

        // Tap the save button.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        // Verify saveVisit was called.
        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(
          visitNotifier.savedVisits.isNotEmpty,
          isTrue,
          reason: 'AC-1: saveVisit should have been called',
        );
      },
    );

    testWidgets(
      'saved Visit has correct ratings from visitRatingProvider',
      (tester) async {
        final container = makeContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set specific rating values.
        final notifier = container.read(visitRatingProvider.notifier);
        notifier.setFoodRating(4.5);
        notifier.setValueRating(3.0);
        notifier.setServiceRating(5.0);
        notifier.setOverallRating(2.0);
        notifier.toggleReturnIntent(true);
        await tester.pumpAndSettle();

        // Tap save.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(visitNotifier.savedVisits.length, 1);

        final savedVisit = visitNotifier.savedVisits.first;
        expect(savedVisit.foodRating, 4.5, reason: 'AC-1: food rating should match');
        expect(savedVisit.valueRating, 3.0, reason: 'AC-1: value rating should match');
        expect(savedVisit.serviceRating, 5.0, reason: 'AC-1: service rating should match');
        expect(
          savedVisit.overallRating,
          2.0,
          reason: 'AC-1: overall rating should match',
        );
      },
    );

    testWidgets(
      'saved Visit has correct composite score',
      (tester) async {
        final container = makeContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set ratings that produce a known composite.
        final notifier = container.read(visitRatingProvider.notifier);
        notifier.setFoodRating(4.0);
        notifier.setValueRating(3.0);
        notifier.setServiceRating(5.0);
        notifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        final expectedComposite = container.read(visitRatingProvider).compositeScore;
        expect(expectedComposite, isNotNull, reason: 'Composite score should be computed');

        // Tap save.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        final savedVisit = visitNotifier.savedVisits.first;
        expect(
          savedVisit.compositeScore,
          expectedComposite!,
          reason: 'AC-1: composite score should be preserved in saved Visit',
        );
      },
    );

    testWidgets(
      'saved Visit has correct return intent',
      (tester) async {
        final container = makeContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set ratings.
        final notifier = container.read(visitRatingProvider.notifier);
        notifier.setFoodRating(4.0);
        notifier.setValueRating(3.0);
        notifier.setServiceRating(5.0);
        notifier.setOverallRating(4.0);
        notifier.toggleReturnIntent(false); // Would NOT come back
        await tester.pumpAndSettle();

        // Tap save.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(visitNotifier.savedVisits.length, 1);
        expect(
          visitNotifier.savedVisits.first.returnIntent,
          isFalse,
          reason: 'AC-1: return intent should be preserved in saved Visit',
        );
      },
    );
  });

  // -- AC-2: Save Visit navigates back after persisting -------------------------

  group('P4ME-40 — AC-2 Save Visit navigates back', () {
    testWidgets(
      'QuickLogScreen pops navigator after saveVisit succeeds',
      (tester) async {
        final container = makeContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: const Center(child: Text('Home')),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const QuickLogScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open Quick Log.
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.text('Quick Log'), findsWidgets);

        // Set all four ratings.
        final notifier = container.read(visitRatingProvider.notifier);
        notifier.setFoodRating(4.0);
        notifier.setValueRating(3.0);
        notifier.setServiceRating(5.0);
        notifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Tap save.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        expect(
          find.text('Quick Log'),
          findsNothing,
          reason: 'AC-2: QuickLogScreen should have been dismissed after save',
        );
      },
    );
  });

  // -- AC-3: Save Visit includes optional form data -----------------------------

  group('P4ME-40 — AC-3 Save Visit includes optional form fields', () {
    // NOTE: P4ME-50 fix — restaurant notes now persist to Restaurant.notes via
    // restaurantRepositoryProvider, not Visit.generalNotes. The old test that
    // verified visit.generalNotes from QuickLogScreen has been removed; the
    // correct behavior is covered by quick_log_restaurant_notes_test.dart.

    testWidgets(
      'saved Visit includes meal total and tip percent from form data',
      (tester) async {
        final container = makeContainer();

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

        // Expand the meal accordion to initialize controllers (index 0).
        final formNotifier = container.read(quickLogFormProvider.notifier);
        formNotifier.toggleAccordion(0);
        await tester.pumpAndSettle();

        // Set meal total and tip via form provider.
        final formState = container.read(quickLogFormProvider);
        expect(formState.mealTotalController, isNotNull);
        expect(formState.tipPercentController, isNotNull);
        formState.mealTotalController!.text = '85.50';
        formState.tipPercentController!.text = '18';

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
          savedVisit.mealTotal,
          85.50,
          reason: 'AC-3: meal total should be included in saved Visit',
        );
        expect(
          savedVisit.tipPercent,
          18.0,
          reason: 'AC-3: tip percent should be included in saved Visit',
        );
      },
    );

    testWidgets(
      'saved Visit includes employee name from form data',
      (tester) async {
        final container = makeContainer();

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

        // Expand the meal accordion to initialize controller (index 0).
        final formNotifier = container.read(quickLogFormProvider.notifier);
        formNotifier.toggleAccordion(0);
        await tester.pumpAndSettle();

        // Set employee name via form provider.
        final formState = container.read(quickLogFormProvider);
        expect(formState.employeeNameController, isNotNull);
        formState.employeeNameController!.text = 'Sarah';

        await tester.pumpAndSettle();

        // Tap save.
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitNotifier = container.read(
          visitsDataProvider.notifier,
        ) as FakeVisitNotifier;
        expect(visitNotifier.savedVisits.length, 1);
        expect(
          visitNotifier.savedVisits.first.employeeName,
          'Sarah',
          reason: 'AC-3: employee name should be included in saved Visit',
        );
      },
    );

    testWidgets(
      'saved Visit includes line items from form data',
      (tester) async {
        final container = makeContainer();

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

        // Add line items via form provider.
        final formNotifier = container.read(quickLogFormProvider.notifier);
        formNotifier.addLineItem('Grilled Salmon', 28.0);
        formNotifier.addLineItem('Caesar Salad', 12.0);

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
          savedVisit.lineItems.length,
          2,
          reason: 'AC-3: line items should be included in saved Visit',
        );
        expect(
          savedVisit.lineItems[0].dishName,
          'Grilled Salmon',
          reason: 'AC-3: first line item dish name should match',
        );
        expect(
          savedVisit.lineItems[1].dishName,
          'Caesar Salad',
          reason: 'AC-3: second line item dish name should match',
        );
      },
    );

    testWidgets(
      'saved Visit includes journal entries from form data',
      (tester) async {
        final container = makeContainer();

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

        // Add journal entries via form provider.
        final formNotifier = container.read(quickLogFormProvider.notifier);
        formNotifier.addJournalEntry('Grilled Salmon', 'Fresh, perfectly cooked');
        formNotifier.addJournalEntry('Tiramisu', 'Rich and not too sweet');

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
          savedVisit.journalEntries.length,
          2,
          reason: 'AC-3: journal entries should be included in saved Visit',
        );
        expect(
          savedVisit.journalEntries[0].dishName,
          'Grilled Salmon',
          reason: 'AC-3: first journal entry dish name should match',
        );
        expect(
          savedVisit.journalEntries[1].impressions,
          'Rich and not too sweet',
          reason: 'AC-3: second journal entry impressions should match',
        );
      },
    );
  });

  // -- AC-4: Save failure handling ------------------------------------------------

  group('P4ME-40 — AC-4 Save failure handling', () {
    testWidgets(
      'saveVisit failure results in error state on visitsDataProvider',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            userPreferencesDataProvider.overrideWith(() {
              return FakeUserPrefsNotifier(
                UserPreferences()..onboardingComplete = true,
              );
            }),
            restaurantDataProvider.overrideWith(() {
              return FakeRestaurantNotifier([
                Restaurant(name: 'Test Restaurant', address: '123 Main St'),
              ]);
            }),
            visitRepositoryProvider.overrideWith((ref) => FakeVisitRepository(failSave: true)),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set all four ratings.
        final notifier = container.read(visitRatingProvider.notifier);
        notifier.setFoodRating(4.0);
        notifier.setValueRating(3.0);
        notifier.setServiceRating(5.0);
        notifier.setOverallRating(4.0);
        await tester.pumpAndSettle();

        // Tap save — should trigger error path in visitsDataProvider.saveVisit().
        await tester.tap(findSaveButton());
        await tester.pumpAndSettle();

        final visitAsync = container.read(visitsDataProvider);
        expect(
          visitAsync.maybeWhen(
            error: (e, st) => true,
            orElse: () => false,
          ),
          isTrue,
          reason: 'AC-4: visitsDataProvider state should be AsyncError after save failure',
        );
      },
    );
  });
}
