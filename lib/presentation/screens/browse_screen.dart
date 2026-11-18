/// Browse screen — displays a filterable list of [Visit] cards.
///
/// Shows visit history with restaurant name, date, composite score bar,
/// and return intent pill. Filter icon opens bottom sheet with filter options.
/// Empty state shown when no visits exist.
///
/// P4ME-17 — S10 Filterable Visit Card List.
/// Covers AC-2 (default sort), AC-3 (filter sheet), AC-5 (apply filters),
/// AC-6 (clear all), AC-7 (active filter badge), AC-10 (empty state).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/widgets/visit_card_widget.dart';

/// Browse screen showing all [Visit] records as filterable cards.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsListFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit History'),
        actions: [
          // AC-3, AC-7: Filter icon with active badge
          _FilterIcon(ref),
        ],
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Failed to load visits: $e'),
        ),
        data: (visits) {
          if (visits.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(visitsListFilterProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: visits.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final fv = visits[index];
                return VisitCard(
                  filteredVisit: fv,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// AC-3, AC-7: Filter icon in AppBar with active filter badge.
class _FilterIcon extends ConsumerWidget {
  final WidgetRef ref;

  const _FilterIcon(this.ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider state to trigger rebuilds.
    ref.watch(visitsListFilterProvider);
    final notifier = ref.read(visitsListFilterProvider.notifier);
    final hasActive = notifier.hasActiveFilters;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter visits',
          onPressed: () => _showFilterSheet(context, ref),
        ),
        if (hasActive)
          Positioned(
            right: 14,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(visitsListFilterProvider.notifier);

    // Track filter state within the sheet.
    String? selectedCuisine;
    double? minRating;
    double? maxRating;
    String? selectedOccasion;
    bool allergySafeOnly = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Filter Visits',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // AC-6: Clear all filters.
                      notifier.clearAllFilters();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // AC-4: Filter options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cuisine type filter
                  const _FilterSectionTitle('Cuisine Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Italian', 'Japanese', 'Chinese', 'Mexican', 'American']
                        .map((c) => FilterChip(
                              label: Text(c),
                              selected: selectedCuisine == c,
                              onSelected: (v) {
                                if (v) {
                                  selectedCuisine = c;
                                  maxRating = null;
                                  selectedOccasion = null;
                                  allergySafeOnly = false;
                                } else {
                                  selectedCuisine = null;
                                }
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Rating range filter
                  const _FilterSectionTitle('Minimum Rating'),
                  Slider(
                    value: minRating ?? 0,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '${minRating?.toInt() ?? 0}',
                    onChanged: (v) {
                      minRating = v;
                      if (v > 0) maxRating = null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Occasion tag filter
                  const _FilterSectionTitle('Occasion'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Date Night', 'Business Lunch', 'Quick Bite', 'Celebration']
                        .map((o) => FilterChip(
                              label: Text(o),
                              selected: selectedOccasion == o,
                              onSelected: (v) {
                                if (v) {
                                  selectedOccasion = o;
                                  selectedCuisine = null;
                                  minRating = null;
                                  allergySafeOnly = false;
                                } else {
                                  selectedOccasion = null;
                                }
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Allergy-safe filter
                  SwitchListTile(
                    title: const Text('Allergy-Safe Only'),
                    value: allergySafeOnly,
                    onChanged: (v) => allergySafeOnly = v,
                  ),

                  const SizedBox(height: 16),

                  // Apply button — AC-5: updates list in one frame
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.icon(
                      onPressed: () {
                        notifier.setFilterCriteria(
                          cuisineType: selectedCuisine,
                          minRating: (minRating != null && minRating! > 0)
                              ? minRating
                              : null,
                          maxRating: maxRating,
                          occasionTag: selectedOccasion,
                          allergySafeOnly: allergySafeOnly,
                        );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AC-10: Cold open empty state.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No visits yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + to log your first dining experience',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Section title for filter options.
class _FilterSectionTitle extends StatelessWidget {
  final String text;
  const _FilterSectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}
