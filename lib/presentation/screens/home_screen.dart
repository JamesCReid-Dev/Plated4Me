/// Home screen — displays recent visits with composite scores.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/domain/entities/entities.dart';

/// Home screen showing recent [Visit] records with composite scores.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recent Visits')),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorView(
          message: 'Failed to load visits',
          onRetry: () => ref.read(visitsDataProvider.notifier).refresh(),
        ),
        data: (visits) {
          if (visits.isEmpty) {
            return const Center(child: _EmptyState());
          }
          // Show most recent first, limited to 20 for performance.
          final sorted = visits.where((v) => v.overallRating > 0).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final display = sorted.take(20).toList();
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(visitsDataProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: display.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _VisitTile(display[index]),
            ),
          );
        },
      ),
    );
  }
}

/// Tile displaying a single [Visit] with its composite score.
class _VisitTile extends StatelessWidget {
  final Visit visit;
  const _VisitTile(this.visit);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(visit.compositeScore);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scoreColor,
        child: Text(
          visit.compositeScore.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text('Visit #${visit.id}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (visit.generalNotes != null && visit.generalNotes!.isNotEmpty)
            Text(
              visit.generalNotes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            'Food ${visit.foodRating.toStringAsFixed(1)} · Value ${visit.valueRating.toStringAsFixed(1)} · Service ${visit.serviceRating.toStringAsFixed(1)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatDate(visit.createdAt), style: theme.textTheme.bodySmall),
          if (visit.returnIntent)
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}

/// Empty state when no visits exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
      SizedBox(height: 16),
      Text('No visits yet', style: TextStyle(fontSize: 18)),
      SizedBox(height: 8),
      Text(
        'Browse restaurants and log your first visit!',
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
