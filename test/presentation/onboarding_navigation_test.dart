/// Regression tests for P4ME-36: Onboarding Skip and Next button navigation.
///
/// These tests verify that tapping Skip and Next buttons actually advances
/// the onboarding flow to the next screen. Without setState() calls in
/// _skip() and _next(), the UI would not rebuild after state changes,
/// leaving users stuck on a single screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/presentation/screens/onboarding_screen.dart';

/// Builds a test widget tree with Riverpod scope and MaterialApp.
Widget _testWrapper(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProviderScope(child: child),
  );
}

void main() {
  group('P4ME-36 — Skip button advances screen', () {
    testWidgets(
      'AC1 — tapping Skip on allergies screen advances to cuisine preferences',
      (tester) async {
        await tester.pumpWidget(_testWrapper(const OnboardingScreen()));

        // Start on allergies screen — verify allergy-specific content is visible.
        expect(
          find.text('Do you have any food allergies?'),
          findsOneWidget,
          reason: 'Should start on Screen 0 (Allergies)',
        );

        // Tap the Skip button.
        await tester.tap(find.widgetWithText(TextButton, 'Skip for now'));
        await tester.pumpAndSettle();

        // After skip, should be on cuisine preferences screen.
        // Allergies title must no longer be present; cuisine title should appear.
        expect(
          find.text('Do you have any food allergies?'),
          findsNothing,
          reason: 'Should have advanced past allergies screen',
        );
        expect(
          find.text('What are your cuisine preferences?'),
          findsOneWidget,
          reason: 'AC1: Should now be on Screen 1 (Cuisine Preferences)',
        );
      },
    );

    testWidgets(
      'AC2 — tapping Skip on cuisine screen advances to rating scale',
      (tester) async {
        await tester.pumpWidget(_testWrapper(const OnboardingScreen()));

        // Skip from allergies -> cuisine.
        await tester.tap(find.widgetWithText(TextButton, 'Skip for now'));
        await tester.pumpAndSettle();

        // Now skip from cuisine -> rating scale.
        await tester.tap(find.widgetWithText(TextButton, 'Skip for now'));
        await tester.pumpAndSettle();

        expect(
          find.text('What are your cuisine preferences?'),
          findsNothing,
          reason: 'Should have advanced past cuisine screen',
        );
        expect(
          find.text('How would you like to rate restaurants?'),
          findsOneWidget,
          reason: 'AC2: Should now be on Screen 2 (Rating Scale)',
        );
      },
    );

    testWidgets('Skip on rating scale advances to occasions screen', (
      tester,
    ) async {
      await tester.pumpWidget(_testWrapper(const OnboardingScreen()));

      // Skip through allergies, cuisine, then rating.
      await tester.tap(find.widgetWithText(TextButton, 'Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Skip for now'));
      await tester.pumpAndSettle();

      expect(
        find.text('How would you like to rate restaurants?'),
        findsNothing,
        reason: 'Should have advanced past rating scale screen',
      );
      expect(
        find.text('What are your default occasions?'),
        findsOneWidget,
        reason: 'Should now be on Screen 3 (Occasions)',
      );
    });
  });

  group('P4ME-36 — Next button advances screen', () {
    testWidgets(
      'AC3 — tapping Next on allergies screen advances to cuisine preferences',
      (tester) async {
        await tester.pumpWidget(_testWrapper(const OnboardingScreen()));

        // Start on allergies screen.
        expect(
          find.text('Do you have any food allergies?'),
          findsOneWidget,
          reason: 'Should start on Screen 0 (Allergies)',
        );

        // Tap the Next button.
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Should be on cuisine preferences screen.
        expect(
          find.text('Do you have any food allergies?'),
          findsNothing,
          reason: 'Should have advanced past allergies screen',
        );
        expect(
          find.text('What are your cuisine preferences?'),
          findsOneWidget,
          reason: 'AC3: Should now be on Screen 1 (Cuisine Preferences)',
        );
      },
    );

    testWidgets('AC4 — tapping Next repeatedly advances through all screens', (
      tester,
    ) async {
      await tester.pumpWidget(_testWrapper(const OnboardingScreen()));

      // Tap Next 3 times to reach the last screen.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(
        find.text('What are your default occasions?'),
        findsOneWidget,
        reason: 'AC4: Should now be on Screen 3 (Occasions)',
      );
    });

    testWidgets('Next button becomes Done on the final screen', (tester) async {
      await tester.pumpWidget(_testWrapper(const OnboardingScreen()));

      // Tap Next 3 times to reach the last screen.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(
        find.text('Done'),
        findsOneWidget,
        reason: 'Final screen should show Done button',
      );
    });
  });
}
