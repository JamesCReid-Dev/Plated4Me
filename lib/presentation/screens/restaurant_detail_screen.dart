/// Restaurant Detail View — comprehensive view of a restaurant with visit history,
/// allergy-safe foods list, and general notes.
///
/// P4ME-22 — S15 Restaurant Detail View.
/// Covers AC-1 (header), AC-2 (allergy-safe foods), AC-3 (general notes),
/// AC-4 (visit history), AC-6 (empty state).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/restaurant_detail_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/widgets/restaurant_notes_widget.dart';

// -- Screen --------------------------------------------------------------------

/// Restaurant Detail Screen — shows name, address, allergy-safe foods, notes, and visit history.
class RestaurantDetailScreen extends ConsumerStatefulWidget {
  /// The restaurant ID to display.
  final int restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(restaurantDetailProvider.notifier).loadDetail(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(restaurantDetailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Details')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Restaurant not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AC-1: Restaurant info header
                _buildHeader(detail.restaurant),

                const SizedBox(height: 24),

                // AC-2: Allergy-safe foods list (expandable)
                _buildAllergySafeFoods(detail.allergySafeFoods),

                const SizedBox(height: 24),

                // P4ME-52 / AC-3: General notes with edit capability
                _buildNotesSection(context, detail.restaurant),

                const SizedBox(height: 24),

                // AC-4 / AC-6: Visit history
                _buildVisitHistory(detail.visits),
              ],
            ),
          );
        },
      ),
    );
  }

  // -- Header (AC-1) -----------------------------------------------------------

  Widget _buildHeader(Restaurant restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AC-1: Name with headline font weight
        Text(
          restaurant.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (restaurant.address != null && restaurant.address!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              restaurant.address!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  // -- Allergy-safe foods (AC-2) -----------------------------------------------

  Widget _buildAllergySafeFoods(List<AllergySafeFood> foods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Allergy-Safe Foods',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (foods.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('No allergy-safe foods recorded.'),
          )
        else
          _ExpandableSafeFoodsList(foods: foods),
      ],
    );
  }
}

// -- Expandable safe foods sub-widget ------------------------------------------

/// Expandable list of allergy-safe foods.
class _ExpandableSafeFoodsList extends StatefulWidget {
  final List<AllergySafeFood> foods;

  const _ExpandableSafeFoodsList({required this.foods});

  @override
  State<_ExpandableSafeFoodsList> createState() =>
      _ExpandableSafeFoodsListState();
}

class _ExpandableSafeFoodsListState extends State<_ExpandableSafeFoodsList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Hide Safe Foods' : 'Show Safe Foods'),
        ),
        if (_expanded)
          ...widget.foods.map(
            (food) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('• ${food.itemName}'),
            ),
          ),
      ],
    );
  }
}

// -- General notes (AC-3 / P4ME-52) -------------------------------------------

/// Notes section with display widget and edit button.
Widget _buildNotesSection(BuildContext context, Restaurant restaurant) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'General Notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _showNotesDialog(context, restaurant),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Notes'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      RestaurantNotesDisplayWidget(restaurant: restaurant),
    ],
  );
}

/// Shows a dialog for editing restaurant notes.
void _showNotesDialog(BuildContext context, Restaurant restaurant) {
  final controller = TextEditingController(text: restaurant.notes ?? '');
  final container = ProviderScope.containerOf(context);

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Edit Notes'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 8,
        decoration: const InputDecoration(
          hintText: 'Add notes about this restaurant',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.multiline,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final notes = controller.text.trim();
            if (notes != restaurant.notes) {
              container.read(restaurantDetailProvider.notifier).updateNotes(notes);
            }
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// -- Visit history (AC-4 / AC-6) ----------------------------------------------

/// Visit history section with empty state.
class _VisitHistorySection extends StatelessWidget {
  final List<Visit> visits;

  const _VisitHistorySection({required this.visits});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visit History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (visits.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('No visits logged yet'),
          )
        else
          ...visits.map(
            (visit) => ListTile(
              title: Text(
                'Composite: ${visit.compositeScore.toStringAsFixed(1)}',
              ),
              subtitle: Text(
                _formatDate(visit.createdAt),
              ),
              trailing: _CompositeScoreBar(score: visit.compositeScore),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

Widget _buildVisitHistory(List<Visit> visits) {
  return _VisitHistorySection(visits: visits);
}

// -- Composite score bar ------------------------------------------------------

/// Small visual indicator of a visit's composite score.
class _CompositeScoreBar extends StatelessWidget {
  final double score;

  const _CompositeScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 4
        ? Colors.green
        : score >= 3
            ? Colors.orange
            : Colors.red;
    return Container(
      width: 60,
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LinearProgressIndicator(
        value: score / 5,
        backgroundColor: Colors.transparent,
        minHeight: 8,
      ),
    );
  }
}
