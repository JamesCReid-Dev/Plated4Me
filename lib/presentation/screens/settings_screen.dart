/// Settings screen — user preferences and app configuration.
/// P4ME-25: Replaces ProfileScreen as the third bottom nav tab.
/// P4ME-21 AC-5: Bulk clear blacklisted visits.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';

/// Settings screen — user preferences and app configuration.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AC-5: Clear all blacklisted visits button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showClearBlacklistDialog(context, ref),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear All Blacklisted Visits'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows confirmation dialog before bulk-clearing blacklisted visits (AC-5).
  void _showClearBlacklistDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to clear all blacklisted visits? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(visitsDataProvider.notifier).clearAllBlacklistedVisits();
                // Show SnackBar after dialog is fully dismissed.
                await Future.delayed(Duration.zero);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All blacklisted visits have been cleared')),
                );
              } catch (_) {
                // Ignore — context may no longer be valid if user navigated away.
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
