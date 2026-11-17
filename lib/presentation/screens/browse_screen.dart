/// Browse screen — displays and manages the restaurant catalog.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/domain/entities/entities.dart';

/// Browse screen showing all [Restaurant] records with add/delete support.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Restaurants')),
      body: restaurantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorView(
          message: 'Failed to load restaurants',
          onRetry: () => ref.read(restaurantDataProvider.notifier).refresh(),
        ),
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return const Center(child: _EmptyState());
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(restaurantDataProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: restaurants.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade200,
                    child: Text(
                      restaurant.name.isNotEmpty
                          ? restaurant.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(restaurant.name),
                  subtitle:
                      restaurant.address != null &&
                          restaurant.address!.isNotEmpty
                      ? Text(restaurant.address!)
                      : const Text('No address recorded'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete "${restaurant.name}"',
                    onPressed: () =>
                        _showDeleteConfirm(context, ref, restaurant),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRestaurantDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Restaurant'),
      ),
    );
  }

  void _showAddRestaurantDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Restaurant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                hintText: 'e.g. Joe\'s Pizza',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                hintText: 'e.g. 123 Main St',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              ref
                  .read(restaurantDataProvider.notifier)
                  .saveRestaurant(
                    Restaurant(
                      name: name,
                      address: addressCtrl.text.trim().isEmpty
                          ? null
                          : addressCtrl.text.trim(),
                    ),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    Restaurant restaurant,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content: Text('Are you sure you want to delete "${restaurant.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () {
              ref
                  .read(restaurantDataProvider.notifier)
                  .deleteRestaurant(restaurant.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no restaurants exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.restaurant, size: 64, color: Colors.grey),
      SizedBox(height: 16),
      Text('No restaurants yet', style: TextStyle(fontSize: 18)),
      SizedBox(height: 8),
      Text(
        'Tap + to add your first restaurant!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    ],
  );
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
