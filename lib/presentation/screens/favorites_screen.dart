/// Favorites screen — displays favorite restaurants computed from visit history.
///
/// A restaurant qualifies as a favorite when ALL three conditions are met:
/// - ≥2 non-blacklisted visits logged
/// - Average composite score ≥80% of scale max (4.0 on 5-point scale)
/// - ≥1 visit with returnIntent=true
///
/// Manual pin/unpin overrides always respected (AC-3).
/// Favorites are computed on-demand from Visit history, NOT stored separately (AC-2).
///
/// P4ME-20 — S13 Favorites Collection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/favorites_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';

/// Favorites screen showing favorite [Restaurant] records computed from visit history.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? _EmptyState()
          : RefreshIndicator(
              onRefresh: () async => ref.read(favoritesProvider.notifier).refresh(),
              child: ListView.separated(
                itemCount: favorites.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final restaurant = favorites[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink.shade200,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(restaurant.name),
                    subtitle: restaurant.address != null
                        ? Text(
                            restaurant.address!,
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : null,
                    trailing: IconButton(
                      icon: Icon(
                        restaurant.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                      ),
                      tooltip: restaurant.isPinned ? 'Unpin' : 'Pin',
                      onPressed: () => ref.read(favoritesProvider.notifier).togglePin(restaurant.id),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// AC-6: Empty favorites state — informational, not actionable.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Favorites appear here when you have 2+ great visits with a return intent.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
}
