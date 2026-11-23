/// Regression tests for P4ME-39: Onboarding chip selection overflow when >6 items selected.
///
/// These tests verify that selecting many chips does not cause layout overflow or clip the
/// "Selected:" summary section off-screen. The fix wraps each screen body in SingleChildScrollView.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/onboarding_state.dart';
import 'package:plated4me/presentation/screens/onboarding_screen.dart';

/// Builds a test widget tree with Riverpod scope and MaterialApp.
Widget _testWrapper(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProviderScope(child: child),
  );
}

void main() {
  group('P4ME-39 — Cuisine screen overflow (>6 selections)', () {
    testWidgets(
      'selecting >6 cuisines: Selected summary is visible',
      (tester) async {
        await tester.pumpWidget(_testWrapper(const OnboardingScreen()));
        await tester.pumpAndSettle();

        // Navigate to cuisine screen (screen 1)
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Select 8 cuisines — more than the ~6 threshold from the defect report
        final presetCuisines = [
          'Japanese',
          'Mexican',
          'Italian',
          'Chinese',
          'Thai',
          'Indian',
          'American',
          'Mediterranean',
        ];

        for (final cuisine in presetCuisines) {
          final chipFinder = find.widgetWithText(FilterChip, cuisine);
          if (chipFinder.evaluate().isNotEmpty) {
            await tester.tap(chipFinder);
            await tester.pumpAndSettle();
          }
        }

        // P4ME-39: The "Selected:" summary must be present and visible.
        // Before the fix, this text was clipped off-screen by overflow.
        expect(
          find.text('Selected:'),
          findsOneWidget,
          reason: 'P4ME-39: Selected summary must be visible after >6 selections',
        );

        expect(find.byType(Chip), findsWidgets);
      },
    );

    testWidgets(
      'selecting all 20 preset cuisines: Selected summary is visible',
      (tester) async {
        await tester.pumpWidget(_testWrapper(const OnboardingScreen()));
        await tester.pumpAndSettle();

        // Navigate to cuisine screen
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Select all preset cuisines
        for (final cuisine in OnboardingState.presetCuisines) {
          final chipFinder = find.widgetWithText(FilterChip, cuisine);
          if (chipFinder.evaluate().isNotEmpty) {
            await tester.tap(chipFinder);
            await tester.pumpAndSettle();
          }
        }

        // P4ME-39: Even with all 20 cuisines selected, summary must be visible.
        expect(
          find.text('Selected:'),
          findsOneWidget,
          reason: 'P4ME-39: Selected summary must be visible with all 20 selections',
        );

        expect(find.byType(Chip), findsWidgets);
      },
    );
  });

  group('P4ME-39 — Allergies screen overflow (>6 selections)', () {
    testWidgets(
      'selecting >6 allergens: chip list renders without clipping',
      (tester) async {
        await tester.pumpWidget(_testWrapper(const OnboardingScreen()));
        await tester.pumpAndSettle();

        // Select severity: Moderate — tap ElevatedButton
        final moderateBtn = find.widgetWithText(ElevatedButton, 'Moderate');
        await tester.tap(moderateBtn);
        await tester.pumpAndSettle();

        // Add 7 allergens by entering text and tapping Add
        for (final name in [
          'Peanuts',
          'Shellfish',
          'Eggs',
          'Milk',
          'Soy',
          'Wheat',
          'Fish',
        ]) {
          final textField = find.byType(TextFormField);
          await tester.enterText(textField, name);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
          await tester.pumpAndSettle();
          // Clear for next entry
          await tester.enterText(textField, '');
          await tester.pumpAndSettle();
        }

        // P4ME-39: All allergen chips should be present.
        expect(find.byType(Chip), findsWidgets);

        final chips = find.byType(Chip).evaluate();
        expect(chips.length, greaterThanOrEqualTo(7));
      },
    );
  });

  group('P4ME-39 — Occasions screen overflow (all selections)', () {
    testWidgets(
      'selecting all default occasions: Selected summary is visible',
      (tester) async {
        await tester.pumpWidget(_testWrapper(const OnboardingScreen()));
        await tester.pumpAndSettle();

        // Navigate to occasions screen (screen 3): skip allergies, cuisine, rating
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        // Select all 6 default occasions
        for (final occasion in OnboardingState.defaultOccasions) {
          final chipFinder = find.widgetWithText(FilterChip, occasion);
          if (chipFinder.evaluate().isNotEmpty) {
            await tester.tap(chipFinder);
            await tester.pumpAndSettle();
          }
        }

        // P4ME-39: Selected summary must be visible.
        expect(
          find.text('Selected:'),
          findsOneWidget,
          reason: 'P4ME-39: Selected summary must be visible with all occasions selected',
        );

        expect(find.byType(Chip), findsWidgets);
      },
    );
  });
}
