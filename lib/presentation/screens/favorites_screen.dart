/// Favorites screen — displays high-rated visits (composite score >= 4.0).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';

const _favoritesThreshold = 4.0;

/// Favorites screen showing high-rated [Visit] records filtered by composite score.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorView(
          message: 'Failed to load favorites',
          onRetry: () => ref.read(visitsDataProvider.notifier).refresh(),
        ),
        data: (visits) {
          final favorites = visits
              .where((v) => v.compositeScore >= _favoritesThreshold && v.overallRating > 0)
              .toList()
            ..sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visits with a composite score of $_favoritesThreshold or higher will appear here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(visitsDataProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final visit = favorites[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink.shade200,
                    child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                  ),
                  title: Text('Visit #${visit.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (visit.generalNotes != null && visit.generalNotes!.isNotEmpty)
                        Text(visit.generalNotes!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        'Food ${visit.foodRating.toStringAsFixed(1)} · Value ${visit.valueRating.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${visit.compositeScore.toStringAsFixed(1)} / 5.0',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.pink.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (visit.returnIntent)
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    ],
                  ),
                );
              },
            ),
          );
        },
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
