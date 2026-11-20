/// Visit Card widget for displaying visit history in the Browse screen.
///
/// Shows restaurant name, date, composite score bar, and return intent pill.
/// When blacklisted, displays a 40% ink-disabled grey overlay with dimmed text.
/// Tapping navigates to Visit Detail View.
/// Supports search result highlighting (AC-4).
///
/// P4ME-17 — S10 Filterable Visit Card List.
/// Covers AC-1 (card layout), AC-8 (blacklist overlay), AC-9 (tap navigation).
/// P4ME-18 — Full-Text Search.
/// Covers AC-4 (matching text highlighted in results).

import 'package:flutter/material.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/services/search_service.dart';
import 'package:plated4me/presentation/extensions/highlight_extension.dart';

/// A card displaying a single visit's key information.
class VisitCard extends StatelessWidget {
  final FilteredVisit filteredVisit;
  final VoidCallback? onTap;
  final List<MatchHighlight>? matchHighlights;
  final String? searchQuery;

  const VisitCard({
    super.key,
    required this.filteredVisit,
    this.onTap,
    this.matchHighlights,
    this.searchQuery,
  });

  static Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  static String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 14) return '1 week ago';

    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final visit = filteredVisit.visit;
    final restaurant = filteredVisit.restaurant;
    final isBlacklisted = visit.blacklisted;
    final scoreColor = _scoreColor(visit.compositeScore);

    return GestureDetector(
      onTap: onTap ?? () => _navigateToDetail(context),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RestaurantNameText(
                        name: restaurant.name,
                        matchHighlights: matchHighlights,
                        searchQuery: searchQuery ?? '',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ReturnIntentPill(visit.returnIntent),
                  ],
                ),
                const SizedBox(height: 4),

                Text(
                  _formatDate(visit.createdAt, context),
                  key: const Key('visit_date'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth.clamp(0.0, 300.0);
                      final fillWidth = barWidth * (visit.compositeScore / 100.0);
                      return Stack(
                        children: [
                          Container(
                            height: 3,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: fillWidth,
                            height: 3,
                            decoration: BoxDecoration(
                              color: scoreColor,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isBlacklisted)
            Container(
              key: const Key('blacklist_overlay'),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x66BDBDBD),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VisitDetailView(),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Widget that displays restaurant name with search match highlighting (AC-4).
class _RestaurantNameText extends StatelessWidget {
  final String name;
  final List<MatchHighlight>? matchHighlights;
  final String searchQuery;

  const _RestaurantNameText({
    required this.name,
    this.matchHighlights,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (matchHighlights == null || matchHighlights!.isEmpty) {
      return Text(
        name.length > 40 ? '${name.substring(0, 40)}...' : name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        key: const Key('restaurant_name'),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      );
    }

    final nameHighlight = matchHighlights!.firstWhere(
      (h) => h.field == 'restaurantName',
      orElse: () => const MatchHighlight(field: '', matchedText: '', tier: 0),
    );

    if (nameHighlight.tier == 0 || nameHighlight.matchedText.isEmpty) {
      return Text(
        name.length > 40 ? '${name.substring(0, 40)}...' : name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        key: const Key('restaurant_name'),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      );
    }

    final theme = Theme.of(context);
    final spans = nameHighlight.matchedText.highlightMatches(searchQuery)
        .map((s) => TextSpan(
              text: s.text,
              style: s.isMatch
                  ? theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    )
                  : theme.textTheme.titleLarge,
            ))
        .toList();

    return Text.rich(
      TextSpan(
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      key: const Key('restaurant_name'),
    );
  }
}

/// Small pill showing return intent (checkmark or X icon).
class _ReturnIntentPill extends StatelessWidget {
  final bool shouldReturn;

  const _ReturnIntentPill(this.shouldReturn);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('return_intent_pill'),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: shouldReturn
            ? const Color(0x264CAF50)
            : const Color(0x26F44336),
        shape: BoxShape.circle,
      ),
      child: Icon(
        shouldReturn ? Icons.check : Icons.cancel,
        size: 16,
        color: shouldReturn ? Colors.green : Colors.red,
      ),
    );
  }
}

/// Placeholder Visit Detail View.
class VisitDetailView extends StatelessWidget {
  const VisitDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Details')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Visit Detail View',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Full implementation coming in a future story',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
