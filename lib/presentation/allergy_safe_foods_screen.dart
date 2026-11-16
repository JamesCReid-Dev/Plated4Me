/// Screen for managing allergy-safe foods at a specific restaurant.
///
/// Displays the list of confirmed safe food items and allows adding or removing entries.
///
/// P4ME-14 / S06 — Allergy-Safe Database.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:plated4me/application/providers/allergy_safe_food_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';

/// Screen that shows and manages allergy-safe foods for a given restaurant.
class AllergySafeFoodsScreen extends ConsumerStatefulWidget {
  /// The restaurant ID to scope safe-foods to.
  final int restaurantId;

  const AllergySafeFoodsScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<AllergySafeFoodsScreen> createState() =>
      _AllergySafeFoodsScreenState();
}

class _AllergySafeFoodsScreenState
    extends ConsumerState<AllergySafeFoodsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<AllergySafeFood> get _filteredFoods {
    return ref
            .read(allergySafeFoodsProvider)
            .value
            ?.where((f) => f.restaurantId == widget.restaurantId)
            .toList() ??
        [];
  }

  void _onSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref
        .read(allergySafeFoodsProvider.notifier)
        .addSafeFood(text, widget.restaurantId);
    _controller.clear();
  }

  void _removeFood(Id foodId) {
    ref.read(allergySafeFoodsProvider.notifier).removeSafeFood(foodId);
  }

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(allergySafeFoodsProvider);
    final foods = _filteredFoods;

    return Scaffold(
      appBar: AppBar(title: const Text('Allergy-Safe Foods')),
      body: Column(
        children: [
          // Add food input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add a safe food...',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _onSubmit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.add), onPressed: _onSubmit),
              ],
            ),
          ),
          // Food list
          Expanded(
            child: foodsAsync.when(
              data: (_) {
                if (foods.isEmpty) {
                  return const Center(
                    child: Text(
                      'No allergy-safe foods recorded for this restaurant.',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return ListTile(
                      title: Text(food.itemName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove',
                        onPressed: () => _removeFood(food.id),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
