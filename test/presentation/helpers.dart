/// Test helpers for presentation layer tests.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/domain/entities/entities.dart';

/// Default container override that provides a fake UserPreferences with onboarding complete.
/// Use this in tests that don't need to test the onboarding gate itself.
ProviderContainer get defaultPrefsContainer => ProviderContainer(
  overrides: [
    userPreferencesDataProvider.overrideWith(() {
      return _FakeUserPrefsNotifier(
        UserPreferences()..onboardingComplete = true,
      );
    }),
    restaurantDataProvider.overrideWith(() {
      return _FakeRestaurantNotifier([
        Restaurant(name: 'Test Restaurant', address: '123 Main St'),
      ]);
    }),
  ],
);

/// Container override for testing with onboarding NOT complete.
ProviderContainer get incompleteOnboardingContainer => ProviderContainer(
  overrides: [
    userPreferencesDataProvider.overrideWith(() {
      return _FakeUserPrefsNotifier(
        UserPreferences()..onboardingComplete = false,
      );
    }),
  ],
);

/// Fake notifier that returns a fixed UserPreferences value.
class _FakeUserPrefsNotifier extends UserPreferencesDataProvider {
  final UserPreferences _prefs;
  _FakeUserPrefsNotifier(this._prefs);

  @override
  Future<UserPreferences> build() => Future.value(_prefs);

  @override
  Future<void> refresh() async {}

  /// Completes onboarding by updating the flag.
  @override
  Future<void> completeOnboarding() async {
    state = AsyncData(UserPreferences()..onboardingComplete = true);
  }
}

/// Fake notifier that returns a fixed list of restaurants.
class _FakeRestaurantNotifier extends RestaurantDataProvider {
  final List<Restaurant> _restaurants;
  _FakeRestaurantNotifier(this._restaurants);

  @override
  Future<List<Restaurant>> build() => Future.value(_restaurants);

  @override
  Future<void> refresh() async {}
}

/// Builds a MaterialApp with the given home widget.
Widget buildApp(Widget home) =>
    MaterialApp(debugShowCheckedModeBanner: false, home: home);
