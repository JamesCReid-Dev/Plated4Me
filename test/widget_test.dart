// Basic Flutter widget smoke test for Plated4Me.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Override providers to avoid Isar dependency in this smoke test.
    final container = ProviderContainer(
      overrides: [
        userPreferencesDataProvider.overrideWith(
          () => _FakeUserPrefsNotifier(),
        ),
        restaurantDataProvider.overrideWith(() => _FakeRestaurantNotifier()),
        visitsListFilterProvider.overrideWith(() => _FakeVisitFilterNotifier()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Plated4MeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The app should render a bottom navigation bar with 3 tabs.
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    final bottomNav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bottomNav.items, hasLength(3));
    expect(bottomNav.items[0].label, 'Browse');
    expect(bottomNav.items[1].label, 'Favorites');
    expect(bottomNav.items[2].label, 'Settings');

    // The initial page is the Browse screen (P4ME-25: 3 tabs = Browse, Favorites, Settings).
    // P4ME-17: BrowseScreen now shows visit history with "Visit History" title.
    expect(find.text('Visit History'), findsOneWidget);
  });
}

/// Fake notifier that returns onboarding-complete user preferences.
class _FakeUserPrefsNotifier extends UserPreferencesDataProvider {
  @override
  Future<UserPreferences> build() =>
      Future.value(UserPreferences()..onboardingComplete = true);

  @override
  Future<void> refresh() async {}
}

/// Fake notifier that returns an empty restaurant list.
class _FakeRestaurantNotifier extends RestaurantDataProvider {
  @override
  Future<List<Restaurant>> build() => Future.value([]);

  @override
  Future<void> refresh() async {}
}

/// Fake notifier that returns an empty filtered visit list.
class _FakeVisitFilterNotifier extends VisitListFilterNotifier {
  @override
  Future<List<FilteredVisit>> build() async => [];

  @override
  Future<void> refresh() async {}
}
