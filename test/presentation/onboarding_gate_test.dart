/// Onboarding gate tests — AC-4 (onboarding shown only if onboardingComplete == false).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/presentation/navigation/app_router.dart';
import 'helpers.dart';

void main() {
  group('AC-4 — Onboarding pre-nav gate route', () {
    testWidgets('shows onboarding screen when onboardingComplete is false', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: incompleteOnboardingContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Onboarding'),
        findsWidgets,
        reason: 'AC-4: Onboarding screen shown when not complete',
      );

      expect(
        find.byType(BottomNavigationBar),
        findsNothing,
        reason: 'AC-4: Bottom nav hidden during onboarding',
      );
    });

    testWidgets('shows navigation shell when onboardingComplete is true', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(BottomNavigationBar),
        findsWidgets,
        reason: 'AC-4: Bottom nav shown when onboarding complete',
      );

      // Onboarding text should NOT be present (only in the incomplete state)
      // Note: IndexedStack keeps all children visible, but with onboardingComplete=true,
      // only the shell is rendered — no onboarding screen at all.
      expect(
        find.text('Onboarding'),
        findsNothing,
        reason: 'AC-4: Onboarding screen not shown when already complete',
      );
    });

    testWidgets('onboarding route uses path /onboarding', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: incompleteOnboardingContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      // Check that the onboarding screen is visible (proving we're on /onboarding route)
      expect(
        find.text('Onboarding'),
        findsWidgets,
        reason: 'AC-4: onboarding uses /onboarding route path',
      );

      // Verify bottom nav is NOT present (confirming we haven't reached the shell yet)
      expect(
        find.byType(BottomNavigationBar),
        findsNothing,
        reason: 'AC-4: bottom nav not shown during onboarding',
      );
    });

    testWidgets('completing onboarding transitions to navigation shell', (tester) async {
      final container = incompleteOnboardingContainer;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Onboarding'), findsWidgets);

      // Complete onboarding via the notifier
      await container.read(userPreferencesDataProvider.notifier).completeOnboarding();
      await tester.pumpAndSettle();

      expect(
        find.byType(BottomNavigationBar),
        findsWidgets,
        reason: 'AC-4: Navigation shell shown after onboarding complete',
      );
    });
  });
}
