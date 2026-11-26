/// Widget tests for blacklist toggle in Visit Detail View (AC-1).
///
/// Red Phase: These tests verify that the Visit Detail View has a blacklist toggle.
/// The current implementation is a placeholder; these tests define the expected UI.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/widgets/visit_card_widget.dart';

/// Default container with fake providers for VisitDetailView tests.
ProviderContainer _makeContainer() => ProviderContainer(
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
  ],
);

/// Fake notifier that returns a fixed list of restaurants.
class FakeRestaurantNotifier extends RestaurantDataProvider {
  final List<Restaurant> _restaurants;
  FakeRestaurantNotifier(this._restaurants);

  @override
  Future<List<Restaurant>> build() => Future.value(_restaurants);

  @override
  Future<void> refresh() async {}
}

/// Fake notifier that returns a fixed UserPreferences value.
class FakeUserPrefsNotifier extends UserPreferencesDataProvider {
  final UserPreferences _prefs;
  FakeUserPrefsNotifier(this._prefs);

  @override
  Future<UserPreferences> build() => Future.value(_prefs);

  @override
  Future<void> refresh() async {}
}

void main() {
  group('AC-1 — Blacklist toggle in Visit Detail View', () {
    testWidgets(
      'AC-1: VisitDetailView renders a blacklist toggle switch',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _makeContainer(),
            child: const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: VisitDetailView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The Visit Detail View must contain a blacklist toggle.
        expect(
          find.byType(Switch),
          findsOneWidget,
          reason: 'AC-1: VisitDetailView must have a blacklist toggle switch',
        );
      },
    );

    testWidgets(
      'AC-1: blacklist toggle is OFF by default for non-blacklisted visits',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _makeContainer(),
            child: const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: VisitDetailView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final switchWidget = tester.widget<Switch>(find.byType(Switch).first);
        expect(switchWidget.value, isFalse,
            reason: 'AC-1: A non-blacklisted visit should have the toggle in OFF state');
      },
    );

    testWidgets(
      'AC-1: toggling blacklist ON shows reason category selection',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _makeContainer(),
            child: const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: VisitDetailView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle the blacklist switch ON.
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();

        // Reason category chips/buttons should appear below the toggle.
        expect(
          find.textContaining('Poor Food'),
          findsOneWidget,
          reason: 'AC-2: "Poor Food" reason category must be shown when blacklist is toggled ON',
        );
        expect(
          find.textContaining('Bad Service'),
          findsOneWidget,
          reason: 'AC-2: "Bad Service" reason category must be shown',
        );
        expect(
          find.textContaining('Overpriced'),
          findsOneWidget,
          reason: 'AC-2: "Overpriced" reason category must be shown',
        );
        expect(
          find.textContaining('Allergy Issue'),
          findsOneWidget,
          reason: 'AC-2: "Allergy Issue" reason category must be shown',
        );
        expect(
          find.textContaining('Other'),
          findsOneWidget,
          reason: 'AC-2: "Other" reason category must be shown',
        );
      },
    );

    testWidgets(
      'AC-1: toggling blacklist OFF clears the stored reason',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: _makeContainer(),
            child: const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: VisitDetailView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Toggle ON, select a reason, then toggle OFF.
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Poor Food').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();

        // The reason category selection UI should no longer be visible.
        expect(
          find.textContaining('Poor Food'),
          findsNothing,
          reason: 'AC-1: Reason categories should disappear when blacklist is toggled OFF',
        );
      },
    );
  });
}
