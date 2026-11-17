/// Profile screen — displays and manages user preferences with onboarding gate.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';

/// Profile screen showing [UserPreferences] and onboarding status.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorView(
          message: 'Failed to load preferences',
          onRetry: () =>
              ref.read(userPreferencesDataProvider.notifier).refresh(),
        ),
        data: (prefs) {
          return ListView(
            children: [
              // Onboarding status card
              _OnboardingCard(
                prefs: prefs,
                onComplete: () {
                  ref
                      .read(userPreferencesDataProvider.notifier)
                      .completeOnboarding();
                },
              ),

              const Divider(height: 32),

              // Rating scale setting
              ListTile(
                leading: const Icon(Icons.star_border),
                title: const Text('Rating Scale'),
                subtitle: Text('${prefs.ratingScale}-point scale'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: prefs.ratingScale > 3
                          ? () => _updateRatingScale(ref, prefs.ratingScale - 1)
                          : null,
                    ),
                    Text(
                      '${prefs.ratingScale}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: prefs.ratingScale < 10
                          ? () => _updateRatingScale(ref, prefs.ratingScale + 1)
                          : null,
                    ),
                  ],
                ),
              ),

              // Cuisine preferences
              if (prefs.cuisinePreferences.isNotEmpty) ...[
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.local_dining),
                  title: const Text('Cuisine Preferences'),
                  subtitle: Text(prefs.cuisinePreferences.join(', ')),
                ),
              ],

              // Default occasions
              if (prefs.defaultOccasions.isNotEmpty) ...[
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.celebration),
                  title: const Text('Default Occasions'),
                  subtitle: Text(prefs.defaultOccasions.join(', ')),
                ),
              ],

              // Account info (static for now)
              const Divider(height: 32),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Account'),
                subtitle: Text('Privacy-first · All data stored locally'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateRatingScale(WidgetRef ref, int newScale) {
    final prefsAsync = ref.read(userPreferencesDataProvider);
    if (prefsAsync.hasValue) {
      final updated = prefsAsync.requireValue.copyWith(ratingScale: newScale);
      ref.read(userPreferencesDataProvider.notifier).savePreferences(updated);
    }
  }
}

/// Card showing onboarding status with completion button.
class _OnboardingCard extends StatelessWidget {
  final dynamic prefs;
  final VoidCallback onComplete;
  const _OnboardingCard({required this.prefs, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isComplete = prefs.onboardingComplete;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isComplete ? Icons.check_circle : Icons.help_outline,
              color: isComplete ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete ? 'Onboarding Complete' : 'Setup Required',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isComplete
                        ? 'You\'re all set! Start logging visits.'
                        : 'Configure your allergies and preferences.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (!isComplete)
              FilledButton.tonal(
                onPressed: onComplete,
                child: const Text('Setup'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable error view with retry button.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
