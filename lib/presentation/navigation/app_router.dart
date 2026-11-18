/// App router — bottom nav shell with IndexedStack, onboarding gate, and Quick Log modal.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/presentation/screens/browse_screen.dart';
import 'package:plated4me/presentation/screens/favorites_screen.dart';
import 'package:plated4me/presentation/screens/onboarding_screen.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';
import 'package:plated4me/presentation/screens/settings_screen.dart';

/// AppRouter — top-level navigation with onboarding gate and bottom nav shell.
/// P4ME-25: 3 tabs (Browse, Favorites, Settings), IndexedStack state preservation,
/// Quick Log as full-screen modal route, /onboarding pre-nav gate.
class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Watch user preferences to determine if onboarding is needed.
    final prefsAsync = ref.watch(userPreferencesDataProvider);

    return prefsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (prefs) {
        // AC-4: Show /onboarding gate only if onboarding not complete.
        final needsOnboarding = !prefs.onboardingComplete;

        if (needsOnboarding) {
          return const _OnboardingGate();
        }

        // Main navigation shell with bottom nav bar.
        return _NavigationShell(
          currentIndex: _currentIndex,
          onPageSelected: (index) => setState(() => _currentIndex = index),
        );
      },
    );
  }
}

/// Onboarding gate — shows the onboarding screen and waits for completion.
class _OnboardingGate extends ConsumerWidget {
  const _OnboardingGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: OnboardingScreen());
  }
}

/// Navigation shell — IndexedStack with BottomNavigationBar and Quick Log FAB.
class _NavigationShell extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onPageSelected;

  const _NavigationShell({
    required this.currentIndex,
    required this.onPageSelected,
  });

  @override
  ConsumerState<_NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<_NavigationShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: widget.currentIndex,
        children: _NavigationShellState._pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onPageSelected,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Browse'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      // AC-3 / P4ME-37: Conditional FAB on Browse screen.
      // Show Quick Log when no restaurants exist; show Add Restaurant otherwise.
      floatingActionButton: widget.currentIndex == 0
          ? _BrowseFab(context, ref)
          : null,
    );
  }

  static const List<Widget> _pages = [
    BrowseScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];
}

/// Conditional FAB for the Browse tab (P4ME-37 fix).
/// Shows Quick Log when no restaurants exist; Add Restaurant otherwise.
class _BrowseFab extends ConsumerWidget {
  final BuildContext context;
  final WidgetRef ref;

  const _BrowseFab(this.context, this.ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantDataProvider);
    return restaurantsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => FloatingActionButton(
        onPressed: () => _openQuickLog(context),
        tooltip: 'Quick Log',
        child: const Icon(Icons.add),
      ),
      data: (restaurants) {
        final hasRestaurants = restaurants.isNotEmpty;
        return FloatingActionButton(
          onPressed: hasRestaurants
              ? () => BrowseScreen.showAddRestaurantDialog(context, ref)
              : () => _openQuickLog(context),
          tooltip: hasRestaurants ? 'Add Restaurant' : 'Quick Log',
          child: const Icon(Icons.add),
        );
      },
    );
  }

  void _openQuickLog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const QuickLogScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
