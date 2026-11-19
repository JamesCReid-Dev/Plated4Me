/// Visit Card widget for displaying visit history in the Browse screen.
///
/// Shows restaurant name, date, composite score bar, and return intent pill.
/// When blacklisted, displays a 40% ink-disabled grey overlay with dimmed text.
/// Tapping navigates to Visit Detail View.
///
/// P4ME-17 — S10 Filterable Visit Card List.
/// Covers AC-1 (card layout), AC-8 (blacklist overlay), AC-9 (tap navigation).

import 'package:flutter/material.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';

/// A card displaying a single visit's key information.
///
/// Used in the BrowseScreen's visit list. Shows restaurant name, date,
/// composite score bar, and return intent pill per DESIGN.md Visit Card spec.
class VisitCard extends StatelessWidget {
  /// The joined visit + restaurant data to display.
  final FilteredVisit filteredVisit;

  /// Callback invoked when the card is tapped.
  ///
  /// If null, a default navigation to Visit Detail View is used.
  final VoidCallback? onTap;

  const VisitCard({
    super.key,
    required this.filteredVisit,
    this.onTap,
  });

  /// Returns the accent color for the score bar based on composite score.
  static Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Formats the date as a relative string ("2 days ago") or formatted date.
  static String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 14) return '1 week ago';

    // For older dates, use a formatted string.
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
                // Row: restaurant name + return intent pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name.length > 40
                            ? '${restaurant.name.substring(0, 40)}...'
                            : restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        key: const Key('restaurant_name'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AC-1: Return intent pill (top-right)
                    _ReturnIntentPill(visit.returnIntent),
                  ],
                ),
                const SizedBox(height: 4),

                // Date caption
                Text(
                  _formatDate(visit.createdAt, context),
                  key: const Key('visit_date'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),

                const SizedBox(height: 8),

                // AC-1: Composite score bar at bottom of card
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
          // AC-8: Blacklist overlay (40% ink-disabled grey)
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

  /// Navigates to Visit Detail View for this visit.
  void _navigateToDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VisitDetailView(),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Small pill showing return intent (checkmark or X icon).
///
/// AC-1: Green checkmark if true, red X if false. 16x16 size.
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
///
/// P4ME-17 AC-9: Tap card navigates to Visit Detail View.
/// Full implementation will be in a later story.
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
