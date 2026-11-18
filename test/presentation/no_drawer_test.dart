/// Layout tests — AC-6 (no drawer, single-column layout with 16px horizontal margins).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/navigation/app_router.dart';
import 'package:plated4me/presentation/screens/browse_screen.dart';
import 'package:plated4me/presentation/screens/favorites_screen.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';
import 'package:plated4me/presentation/screens/settings_screen.dart';

import 'helpers.dart';

/// Creates sample visit data for layout tests.
ProviderContainer _sampleVisitsContainer() {
  final visits = <FilteredVisit>[];
  for (int i = 1; i <= 3; i++) {
    final visit = Visit(
      restaurantId: i,
      foodRating: 4.0,
      valueRating: 3.5,
      serviceRating: 4.0,
      overallRating: 4.5,
      compositeScore: 70.0 + i * 5,
      returnIntent: i % 2 == 0,
    )..id = i
      ..createdAt = DateTime(2025, 6, i)
      ..updatedAt = DateTime(2025, 6, i);
    final restaurant = Restaurant(name: 'Test Restaurant $i')..id = i;
    visits.add(FilteredVisit(visit: visit, restaurant: restaurant));
  }
  return ProviderContainer(
    overrides: [
      userPreferencesDataProvider.overrideWith(() {
        return _FakeUserPrefsNotifier(
          UserPreferences()..onboardingComplete = true,
        );
      }),
      visitsListFilterProvider.overrideWith(
        () => _FakeVisitFilterNotifier(visits),
      ),
    ],
  );
}

/// Fake notifier that returns a fixed list of filtered visits.
class _FakeVisitFilterNotifier extends VisitListFilterNotifier {
  final List<FilteredVisit> _visits;
  _FakeVisitFilterNotifier(this._visits);

  @override
  Future<List<FilteredVisit>> build() async => _visits;

  @override
  Future<void> refresh() async {}
}

/// Fake notifier for user preferences.
class _FakeUserPrefsNotifier extends UserPreferencesDataProvider {
  final UserPreferences _prefs;
  _FakeUserPrefsNotifier(this._prefs);

  @override
  Future<UserPreferences> build() => Future.value(_prefs);

  @override
  Future<void> refresh() async {}
}

void main() {
  group('AC-6 — No drawer, single-column layout with 16px margins', () {
    testWidgets('AppRouter Scaffold has no drawer', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNull, reason: 'AC-6: no drawer navigation');
    });

    testWidgets('BrowseScreen Scaffold has no drawer', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: _sampleVisitsContainer(),
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final browseFinder = find.ancestor(
        of: find.byType(BrowseScreen),
        matching: find.byType(Scaffold),
      );
      expect(browseFinder, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(browseFinder);
      expect(scaffold.drawer, isNull, reason: 'AC-6: Browse has no drawer');
    });

    testWidgets('FavoritesScreen Scaffold has no drawer', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Favorites tab first
      final navBarRect = tester.getRect(find.byType(BottomNavigationBar));
      final tapOffset1 = Offset(
        navBarRect.left + (navBarRect.width * 2 / 6),
        navBarRect.top,
      );
      await tester.tapAt(tapOffset1);
      await tester.pumpAndSettle();

      expect(
        find.text('Favorites'),
        findsWidgets,
        reason: 'AC-6: Favorites tab active',
      );

      final favFinder = find.ancestor(
        of: find.byType(FavoritesScreen),
        matching: find.byType(Scaffold),
      );
      expect(favFinder, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(favFinder);
      expect(scaffold.drawer, isNull, reason: 'AC-6: Favorites has no drawer');
    });

    testWidgets('SettingsScreen Scaffold has no drawer', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Settings tab first
      final navBarRect = tester.getRect(find.byType(BottomNavigationBar));
      final tapOffset2 = Offset(
        navBarRect.left + (navBarRect.width * 4 / 6),
        navBarRect.top,
      );
      await tester.tapAt(tapOffset2);
      await tester.pumpAndSettle();

      expect(
        find.text('Settings'),
        findsWidgets,
        reason: 'AC-6: Settings tab active',
      );

      final settingsFinder = find.ancestor(
        of: find.byType(SettingsScreen),
        matching: find.byType(Scaffold),
      );
      expect(settingsFinder, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(settingsFinder);
      expect(scaffold.drawer, isNull, reason: 'AC-6: Settings has no drawer');
    });

    testWidgets('BrowseScreen uses single-column scrollable layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: _sampleVisitsContainer(),
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      // Browse screen uses ListView.separated for its visit list (with sample data).
      expect(
        find.byType(ListView),
        findsWidgets,
        reason: 'AC-6: single-column (vertical) scrollable layout',
      );
    });

    testWidgets('Quick Log modal Scaffold has no drawer', (tester) async {
      // QuickLogScreen IS a Scaffold itself (not wrapped in one by its parent).
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: QuickLogScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Scaffold that IS the QuickLogScreen's root widget
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.drawer, isNull, reason: 'AC-6: Quick Log has no drawer');
    });

    testWidgets('no NavigationDrawer widget anywhere in tree', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(NavigationDrawer),
        findsNothing,
        reason: 'AC-6: no NavigationDrawer widget in entire app',
      );
    });

    testWidgets('no Drawer widget anywhere in tree', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: AppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(Drawer),
        findsNothing,
        reason: 'AC-6: no Drawer widget in entire app',
      );
    });
  });
}
