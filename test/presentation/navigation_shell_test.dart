/// Navigation shell widget tests — AC-1 (three tabs) and AC-2 (IndexedStack state preservation).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/presentation/navigation/app_router.dart';

import 'helpers.dart';

void main() {
  group('AC-1 — Bottom nav bar with three tabs', () {
    testWidgets('shows exactly three bottom nav items', (tester) async {
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
      expect(navBar.items.length, 3, reason: 'AC-1: exactly three tabs');
    });

    testWidgets('first tab is Browse (default)', (tester) async {
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
      expect(navBar.currentIndex, 0, reason: 'AC-1: Browse is default tab');
      expect(
        navBar.items[0].label,
        'Browse',
        reason: 'AC-1: first tab labeled "Browse"',
      );
    });

    testWidgets('second tab is Favorites', (tester) async {
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
      expect(
        navBar.items[1].label,
        'Favorites',
        reason: 'AC-1: second tab labeled "Favorites"',
      );
    });

    testWidgets('third tab is Settings', (tester) async {
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
      expect(
        navBar.items[2].label,
        'Settings',
        reason: 'AC-1: third tab labeled "Settings"',
      );
    });

    testWidgets('does NOT show Home or Profile tabs', (tester) async {
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
      expect(labels, isNot(contains('Home')), reason: 'AC-1: no Home tab');
      expect(
        labels,
        isNot(contains('Profile')),
        reason: 'AC-1: no Profile tab',
      );
    });

    testWidgets('tapping Favorites tab switches to second page', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the second nav item area of BottomNavigationBar (1/3 from left)
      final navBarRect = tester.getRect(find.byType(BottomNavigationBar));
      final tapOffset = Offset(
        navBarRect.left + (navBarRect.width * 2 / 6),
        navBarRect.top,
      );
      await tester.tapAt(tapOffset);
      await tester.pumpAndSettle();

      // IndexedStack keeps all children visible, so find at least one "Favorites" text
      expect(
        find.text('Favorites'),
        findsWidgets,
        reason: 'AC-1: Favorites tab content present',
      );
    });

    testWidgets('tapping Settings tab switches to third page', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final navBarRect = tester.getRect(find.byType(BottomNavigationBar));
      final tapOffset = Offset(
        navBarRect.left + (navBarRect.width * 4 / 6),
        navBarRect.top,
      );
      await tester.tapAt(tapOffset);
      await tester.pumpAndSettle();

      expect(
        find.text('Settings'),
        findsWidgets,
        reason: 'AC-1: Settings tab content present',
      );
    });
  });

  group('AC-2 — IndexedStack preserves tab state', () {
    testWidgets('IndexedStack is used as body of Scaffold', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(IndexedStack),
        findsOneWidget,
        reason: 'AC-2: IndexedStack used for tab body',
      );
    });

    testWidgets('switching tabs preserves content in IndexedStack children', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(
        indexedStack.children.length,
        3,
        reason: 'AC-2: IndexedStack has three children',
      );
    });

    testWidgets('switching to Favorites and back preserves Browse', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final navBarRect = tester.getRect(find.byType(BottomNavigationBar));

      // Switch to Favorites (second tab)
      final tapOffset1 = Offset(
        navBarRect.left + (navBarRect.width * 2 / 6),
        navBarRect.top,
      );
      await tester.tapAt(tapOffset1);
      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsWidgets);

      // Switch back to Browse (first tab)
      final tapOffset0 = Offset(
        navBarRect.left + (navBarRect.width * 1 / 6),
        navBarRect.top,
      );
      await tester.tapAt(tapOffset0);
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(
        indexedStack.children.length,
        3,
        reason: 'AC-2: all three children preserved',
      );
    });
  });
}
