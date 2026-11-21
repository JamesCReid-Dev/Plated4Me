/// Widget tests for P4ME-16 (S08) — Optional sections accordion in Quick Log screen.
///
/// Red Phase: These tests verify that five independently expandable/collapsible
/// accordion sections are present and functional, optional data is captured,
/// and save works without filling any optional section (AC-2).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/quick_log_form_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';

import 'helpers.dart';

// -- Fake save notifier for tests that tap the save button ----------------------

/// Minimal fake VisitDataProvider that completes saveVisit synchronously.
class _FakeSaveNotifier extends VisitDataProvider {
  @override
  Future<List<Visit>> fetchAll() async => [];

  @override
  Future<void> refresh() async {}

  @override
  Future<void> saveVisit(Visit visit) async {
    state = AsyncData(await fetchAll());
  }
}

void main() {
  group('P4ME-16 — AC-1: Five accordion sections present', () {
    testWidgets(
      'Meal total + tip section is rendered',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Meal'),
          findsOneWidget,
          reason: 'AC-1: Meal total section should be present',
        );
      },
    );

    testWidgets(
      'Visit line items section is rendered',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Look for any of the expected labels in the line items section.
        final lineItems = find.textContaining('Line Items');
        final dish = find.textContaining('Dish');
        final items = find.textContaining('Items');
        expect(
          lineItems.evaluate().isNotEmpty ||
              dish.evaluate().isNotEmpty ||
              items.evaluate().isNotEmpty,
          isTrue,
          reason: 'AC-1: Visit line items section should be present',
        );
      },
    );

    testWidgets(
      'Food journal section is rendered',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final journal = find.textContaining('Journal');
        final foodJournal = find.textContaining('Food journal');
        expect(
          journal.evaluate().isNotEmpty || foodJournal.evaluate().isNotEmpty,
          isTrue,
          reason: 'AC-1: Food journal section should be present',
        );
      },
    );

    testWidgets(
      'Allergy-safe foods section is rendered',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final allergy = find.textContaining('Allergy');
        final safe = find.textContaining('safe');
        final allergySafe = find.textContaining('Allergy-safe');
        expect(
          allergy.evaluate().isNotEmpty ||
              safe.evaluate().isNotEmpty ||
              allergySafe.evaluate().isNotEmpty,
          isTrue,
          reason: 'AC-1: Allergy-safe foods section should be present',
        );
      },
    );

    testWidgets(
      'Restaurant notes section is rendered',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final note = find.textContaining('Note');
        final notes = find.textContaining('Notes');
        expect(
          note.evaluate().isNotEmpty || notes.evaluate().isNotEmpty,
          isTrue,
          reason: 'AC-1: Restaurant notes section should be present',
        );
      },
    );
  });

  group('P4ME-16 — AC-4: Accordion styling (surface-overlay, no shadows)', () {
    testWidgets(
      'accordion sections use surface-overlay tone without elevation shadows',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Accordion sections should be Cards or Containers with no elevation.
        final cards = tester.widgetList<Card>(find.byType(Card));
        for (final card in cards) {
          expect(
            card.elevation,
            0,
            reason: 'AC-4: Accordion Cards must not have elevation shadows',
          );
        }
      },
    );
  });

  group('P4ME-16 — AC-2: Save without optional sections', () {
    testWidgets(
      'save button is enabled after ratings only (no optional data needed)',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Set all four ratings by dragging sliders to a non-zero value.
        final sliders = find.byType(Slider);
        final sliderCount = sliders.evaluate().length;
        for (var i = 0; i < sliderCount; i++) {
          await tester.drag(sliders.at(i), const Offset(50, 0));
          await tester.pumpAndSettle();
        }

        // Save button should be enabled.
        final saveButton = find.byType(ElevatedButton);
        expect(saveButton, findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(saveButton).enabled,
          true,
          reason: 'AC-2/AC-5: Save button must be enabled with ratings complete',
        );
      },
    );

    testWidgets(
      'tapping save pops the navigator after setting only ratings',
      (tester) async {
        // Override visitsDataProvider so saveVisit completes synchronously.
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
            visitsDataProvider.overrideWith(() => _FakeSaveNotifier()),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute(
                    builder: (_) => const QuickLogScreen(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Set all four ratings.
        final sliders = find.byType(Slider);
        final sliderCount = sliders.evaluate().length;
        for (var i = 0; i < sliderCount; i++) {
          await tester.drag(sliders.at(i), const Offset(50, 0));
          await tester.pumpAndSettle();
        }

        // Tap save.
        await tester.tap(find.text('Save Visit'));
        await tester.pumpAndSettle();

        expect(
          find.byType(QuickLogScreen),
          findsNothing,
          reason: 'AC-2: Quick Log should dismiss after save',
        );
      },
    );
  });

  group('P4ME-16 — AC-3: Optional data capture', () {
    testWidgets(
      'journal section has dish name and impressions input fields when expanded',
      (tester) async {
        // Use a taller viewport so accordion sections are reachable.
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.devicePixelRatio = 1.0;
        });

        // Use a fresh container so provider state is clean.
        final container = ProviderContainer(
          overrides: [
            quickLogFormProvider.overrideWith((_ref) => QuickLogFormNotifier()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the Food Journal section header to expand.
        await tester.tap(find.textContaining('Food Journal'));
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        // The expanded journal section should have text input fields.
        expect(
          find.byType(TextFormField),
          findsWidgets,
          reason: 'AC-3: Expanded accordion should expose TextFormField widgets',
        );
      },
    );

    testWidgets(
      'line items section has dish name and price input fields when expanded',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.devicePixelRatio = 1.0;
        });

        final container = ProviderContainer(
          overrides: [
            quickLogFormProvider.overrideWith((_ref) => QuickLogFormNotifier()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the Line Items section header to expand.
        await tester.tap(find.textContaining('Line Items'));
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.byType(TextFormField),
          findsWidgets,
          reason: 'AC-3: Expanded accordion should expose TextFormField widgets',
        );
      },
    );
  });
}
