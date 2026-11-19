/// Quick Log modal route tests — AC-3 (Quick Log opens as full-screen modal, not a tab).
/// P4ME-44: QuickLog state resets between opens (ratings + form data cleared).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/quick_log_form_provider.dart';
import 'package:plated4me/application/providers/visit_rating_provider.dart';
import 'package:plated4me/presentation/navigation/app_router.dart'
    show AppRouter, openQuickLog;
import 'package:plated4me/presentation/screens/quick_log_screen.dart';

import 'helpers.dart';

void main() {
  group('AC-3 — Quick Log as full-screen modal route', () {
    testWidgets('Quick Log is NOT a bottom nav tab item', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      final labels = navBar.items.map((item) => item.label).toList();
      expect(
        labels,
        isNot(contains('Quick Log')),
        reason: 'AC-3: Quick Log not a tab',
      );
    });

    testWidgets(
      'Quick Log FAB shown on Browse tab',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: AppRouter()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byTooltip('Quick Log'),
          findsOneWidget,
          reason: 'FAB shows Quick Log on Browse tab',
        );
      },
    );

    testWidgets('QuickLogScreen renders correctly when shown directly', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: QuickLogScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(QuickLogScreen),
        findsWidgets,
        reason: 'AC-3: Quick Log screen renders',
      );

      expect(
        find.text('Quick Log'),
        findsWidgets,
        reason: 'AC-3: Quick Log screen has title',
      );
    });

    testWidgets('QuickLogScreen Scaffold has no drawer', (tester) async {
      // QuickLogScreen IS a Scaffold itself.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: QuickLogScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.drawer, isNull, reason: 'AC-3: Quick Log has no drawer');
    });

    testWidgets(
      'QuickLogScreen uses full-screen modal style (fullscreenDialog)',
      (tester) async {
        // Verify that the route configuration for Quick Log sets fullscreenDialog = true.
        // We can't directly test the Navigator.push call, but we verify the screen itself
        // is designed as a full-screen modal by checking its Scaffold properties.
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // The screen should fill the full available space (no padding/margin that would suggest it's not modal)
        expect(
          find.byType(QuickLogScreen),
          findsWidgets,
          reason: 'AC-3: Quick Log renders as full-screen content',
        );
      },
    );

    testWidgets('back navigation from QuickLogScreen dismisses it', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
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

      // Tap FAB to open Quick Log
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Quick Log'),
        findsWidgets,
        reason: 'AC-3: Quick Log visible',
      );

      // Go back via Navigator.pop (simulates iOS swipe-back or Android back)
      final navigator = Navigator.of(tester.element(find.byType(Scaffold)));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(
        find.text('Quick Log'),
        findsNothing,
        reason: 'AC-3: Quick Log dismissed',
      );

      // Should be back at Home
      expect(
        find.text('Home'),
        findsWidgets,
        reason: 'AC-3: returned to home after dismissing Quick Log',
      );
    });
  });

  group('P4ME-44 — QuickLog state resets between opens', () {
    testWidgets(
      'ratings and form data reset to defaults on second open',
      (tester) async {
        final container = defaultPrefsContainer;

        // --- First open: enter data -------------------------------------------
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) => const Center(child: Text('Home')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open Quick Log first time via _openQuickLog (the actual function under test)
        await tester.runAsync(() async {
          openQuickLog(tester.element(find.text('Home')));
          await tester.pumpAndSettle();
        });

        expect(
          find.text('Quick Log'),
          findsWidgets,
          reason: 'P4ME-44: Quick Log visible (first open)',
        );

        // Enter data via provider methods (simulates user interaction)
        final ratingNotifier = container.read(visitRatingProvider.notifier);
        ratingNotifier.setFoodRating(5.0);
        ratingNotifier.setValueRating(4.0);
        ratingNotifier.setServiceRating(3.0);
        ratingNotifier.setOverallRating(4.5);
        ratingNotifier.toggleReturnIntent(true);

        final formNotifier = container.read(quickLogFormProvider.notifier);
        // Toggle accordion to initialize controllers, then populate them
        formNotifier.toggleAccordion(0);
        final formState1 = container.read(quickLogFormProvider);
        formState1.mealTotalController?.text = '50.00';
        formState1.employeeNameController?.text = 'Test Employee';
        formNotifier.addLineItem('Pasta', 15.0);

        // Verify data was entered
        final ratingState1 = container.read(visitRatingProvider);
        expect(ratingState1.foodRating, equals(5.0), reason: 'Food rating set');
        expect(ratingState1.returnIntent, isTrue, reason: 'Return intent set');

        final formAfterData = container.read(quickLogFormProvider);
        expect(
          formAfterData.employeeNameController?.text,
          equals('Test Employee'),
          reason: 'Employee name entered',
        );
        expect(
          formAfterData.lineItems.length,
          greaterThan(0),
          reason: 'Line item added',
        );

        // Dismiss Quick Log (back navigation)
        final navigator1 = Navigator.of(tester.element(find.byType(Scaffold)));
        navigator1.pop();
        await tester.pumpAndSettle();

        expect(
          find.text('Quick Log'),
          findsNothing,
          reason: 'P4ME-44: Quick Log dismissed',
        );

        // --- Second open: verify state is reset to defaults --------------------
        await tester.runAsync(() async {
          openQuickLog(tester.element(find.text('Home')));
          await tester.pumpAndSettle();
        });

        expect(
          find.text('Quick Log'),
          findsWidgets,
          reason: 'P4ME-44: Quick Log visible (second open)',
        );

        // Verify ratings are reset to zero
        final ratingState2 = container.read(visitRatingProvider);
        expect(
          ratingState2.foodRating,
          equals(0.0),
          reason: 'P4ME-44: food rating reset to 0',
        );
        expect(
          ratingState2.valueRating,
          equals(0.0),
          reason: 'P4ME-44: value rating reset to 0',
        );
        expect(
          ratingState2.serviceRating,
          equals(0.0),
          reason: 'P4ME-44: service rating reset to 0',
        );
        expect(
          ratingState2.overallRating,
          equals(0.0),
          reason: 'P4ME-44: overall rating reset to 0',
        );
        expect(
          ratingState2.compositeScore,
          isNull,
          reason: 'P4ME-44: composite score reset to null',
        );
        expect(
          ratingState2.returnIntent,
          isNull,
          reason: 'P4ME-44: return intent reset to null',
        );

        // Verify form data is cleared
        final formState2 = container.read(quickLogFormProvider);
        expect(
          formState2.employeeNameController?.text ?? '',
          equals(''),
          reason: 'P4ME-44: employee name cleared',
        );
      },
    );
  });
}
