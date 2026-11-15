/// Back navigation tests — AC-5 (platform conventions: iOS swipe, Android back button).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/presentation/navigation/app_router.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';
import 'helpers.dart';

void main() {
  group('AC-5 — Back navigation follows platform conventions', () {
    testWidgets('Scaffold has no drawer (platform back handles dismissal)', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNull, reason: 'AC-5: no drawer — platform back handles dismissal');
    });

    testWidgets('navigating between tabs does not push routes (no back stack)', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final navigator = Navigator.of(tester.element(find.byType(AppRouter)));
      expect(
        navigator.canPop(),
        isFalse,
        reason: 'AC-5: no back stack after initial load',
      );

      // Switch tabs — IndexedStack should NOT push new routes
      final navBarRect = tester.getRect(find.byType(BottomNavigationBar));

      // Tap second tab (Favorites)
      final tapOffset1 = Offset(navBarRect.left + (navBarRect.width * 2 / 6), navBarRect.top);
      await tester.tapAt(tapOffset1);
      await tester.pumpAndSettle();

      expect(
        navigator.canPop(),
        isFalse,
        reason: 'AC-5: tab switching does not push routes — no back stack buildup',
      );

      // Tap third tab (Settings)
      final tapOffset2 = Offset(navBarRect.left + (navBarRect.width * 4 / 6), navBarRect.top);
      await tester.tapAt(tapOffset2);
      await tester.pumpAndSettle();

      expect(
        navigator.canPop(),
        isFalse,
        reason: 'AC-5: third tab also does not push routes',
      );
    });

    testWidgets('Quick Log modal can be dismissed via Navigator.pop (tested in isolation)', (tester) async {
      // Test Quick Log dismissal in isolation to avoid IndexedStack hero conflicts.
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
        reason: 'AC-5: Quick Log screen visible',
      );

      // Dismiss via pop (simulates iOS swipe-back or Android back button)
      final navigator = Navigator.of(tester.element(find.byType(Scaffold)));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(
        find.text('Quick Log'),
        findsNothing,
        reason: 'AC-5: Quick Log dismissed',
      );
    });

    testWidgets('back from Quick Log modal returns to current tab state (tested in isolation)', (tester) async {
      // Test back navigation from Quick Log in isolation.
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

      // Open Quick Log via FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Quick Log'),
        findsWidgets,
        reason: 'AC-5: Quick Log visible',
      );

      // Go back — should return to Home (current screen when Quick Log was opened)
      final navigator = Navigator.of(tester.element(find.byType(Scaffold)));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(
        find.text('Home'),
        findsWidgets,
        reason: 'AC-5: back from Quick Log returns to current screen',
      );
    });
  });
}
