/// Quick Log screen — full-screen modal for rapid visit logging with ratings.
///
/// P4ME-15 (S07): Four weighted sliders, real-time composite score, return intent toggle,
/// and save button. All ratings use the user's chosen scale from preferences.
/// P4ME-16 (S08): Five optional accordion sections for meal details, line items,
/// journal entries, allergy-safe foods, and restaurant notes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/allergy_safe_food_provider.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/quick_log_form_provider.dart';
import 'package:plated4me/application/providers/visit_rating_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';

// -- Rating definitions --------------------------------------------------------

/// A single rating slider definition with label and weight.
class _RatingDef {
  final String label;
  final double weight;
  final String Function(int, int) semanticLabelFn;

  const _RatingDef({
    required this.label,
    required this.weight,
    required this.semanticLabelFn,
  });
}

/// Rating slider definitions for the Quick Log screen.
final List<_RatingDef> _ratingDefs = [
      const _RatingDef(
        label: 'Food Quality',
        weight: 0.40,
        semanticLabelFn: _foodSemanticLabel,
      ),
      const _RatingDef(
        label: 'Value',
        weight: 0.30,
        semanticLabelFn: _valueSemanticLabel,
      ),
      const _RatingDef(
        label: 'Service',
        weight: 0.15,
        semanticLabelFn: _serviceSemanticLabel,
      ),
      const _RatingDef(
        label: 'Overall',
        weight: 0.15,
        semanticLabelFn: _overallSemanticLabel,
      ),
    ];

String _foodSemanticLabel(int v, int s) => 'Food Quality, $v out of $s';
String _valueSemanticLabel(int v, int s) => 'Value, $v out of $s';
String _serviceSemanticLabel(int v, int s) => 'Service, $v out of $s';
String _overallSemanticLabel(int v, int s) => 'Overall, $v out of $s';

// -- Screen --------------------------------------------------------------------

/// Quick Log screen with four rating sliders and save button.
class QuickLogScreen extends ConsumerStatefulWidget {
  const QuickLogScreen({super.key});

  @override
  ConsumerState<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends ConsumerState<QuickLogScreen> {
  /// Current rating scale from user preferences (5 or 10).
  int _scale = 5;

  /// Accordion expanded state: [Meal, LineItems, Journal, AllergySafe, Notes]
  final List<bool> _expanded = [false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    // Read the current scale from preferences.
    final prefs = ref.read(userPreferencesDataProvider);
    prefs.whenData(
      (p) => setState(() => _scale = p.ratingScale),
    );
  }

  void _toggleAccordion(int index) {
    setState(() => _expanded[index] = !_expanded[index]);
  }

  /// Returns a list of tick labels for the given scale.
  List<String> _tickLabels() {
    return List.generate(_scale, (i) => '${i + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitRatingProvider);
    final notifier = ref.read(visitRatingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Log'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // -- Sliders section --------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ..._ratingDefs.map(
                      (def) => _RatingSlider(
                        def: def,
                        value: _sliderValue(def.label, state),
                        scale: _scale,
                        tickLabels: _tickLabels(),
                        onChanged: (value) {
                          switch (def.label) {
                            case 'Food Quality':
                              notifier.setFoodRating(value);
                            case 'Value':
                              notifier.setValueRating(value);
                            case 'Service':
                              notifier.setServiceRating(value);
                            case 'Overall':
                              notifier.setOverallRating(value);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // -- Composite score display (AC-5) ---------------------------------
                    _CompositeScoreDisplay(
                      score: state.compositeScore ?? 0.0,
                      scale: _scale,
                    ),

                    const SizedBox(height: 24),

                    // -- Return intent toggle (AC-6) ------------------------------------
                    _ReturnIntentToggle(
                      value: state.returnIntent,
                      onChanged: notifier.toggleReturnIntent,
                    ),

                    const SizedBox(height: 24),

                    // -- Optional sections accordion (P4ME-16, AC-1) ------------------
                    _OptionalSectionsAccordion(
                      expanded: _expanded,
                      onToggle: _toggleAccordion,
                      form: ref.read(quickLogFormProvider),
                    ),
                  ],
              ),
            ),
          ),

          // -- Save button (AC-7) -----------------------------------------------
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isSaveEnabled ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Visit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the slider value for a given rating label.
  double _sliderValue(String label, VisitRatingState state) {
    switch (label) {
      case 'Food Quality':
        return state.foodRating;
      case 'Value':
        return state.valueRating;
      case 'Service':
        return state.serviceRating;
      case 'Overall':
        return state.overallRating;
      default:
        return 0.0;
    }
  }

  Future<void> _handleSave() async {
    final state = ref.read(visitRatingProvider);
    final form = ref.read(quickLogFormProvider);

    final employeeNameText = form.employeeNameController?.text.trim();
    final restaurantNotesText = form.restaurantNotesController?.text.trim();

    final visit = Visit(
      restaurantId: 0,
      foodRating: state.foodRating,
      valueRating: state.valueRating,
      serviceRating: state.serviceRating,
      overallRating: state.overallRating,
      compositeScore: state.compositeScore ?? 0.0,
      returnIntent: state.returnIntent ?? false,
    )..mealTotal = form.mealTotal
     ..tipPercent = form.tipPercent
     ..employeeName = (employeeNameText == null || employeeNameText.isEmpty)
         ? null
         : employeeNameText
     ..lineItems = List<VisitLineItem>.from(form.lineItems)
     ..journalEntries = List<JournalEntry>.from(form.journalEntries);

    await ref.read(visitsDataProvider.notifier).saveVisit(visit);

    // Persist restaurant notes to the Restaurant entity (P4ME-50 fix).
    if (restaurantNotesText != null && restaurantNotesText.isNotEmpty) {
      final repo = ref.read(restaurantRepositoryProvider);
      final restaurants = await repo.getAllRestaurants();
      if (restaurants.isNotEmpty) {
        final restaurant = restaurants.first;
        restaurant.notes = restaurantNotesText;
        await repo.saveRestaurant(restaurant);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

// -- Slider widget -------------------------------------------------------------

/// A single rating slider with label, tick marks, and semantic labels.
class _RatingSlider extends StatelessWidget {
  final _RatingDef def;
  final double value;
  final int scale;
  final List<String> tickLabels;
  final ValueChanged<double> onChanged;

  const _RatingSlider({
    required this.def,
    required this.value,
    required this.scale,
    required this.tickLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with weight indicator.
          Text(
            '${def.label} (${((def.weight * 100).toInt())}%)',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 4),

          // Slider — supports drag and tap (AC-3, AC-4).
          Slider(
            value: value,
            min: 0,
            max: scale.toDouble(),
            divisions: scale,
            label: value.toInt().toString(),
            onChanged: onChanged,
            semanticFormatterCallback: (v) =>
                def.semanticLabelFn(v.round(), scale),
          ),

          // Tick marks below track.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tickLabels.map((label) {
              return SizedBox(
                width: 24,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),

          // Current value display.
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${value.toInt()}/$scale',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Composite score display (AC-5) --------------------------------------------

/// Displays the weighted composite score in large headline format.
class _CompositeScoreDisplay extends StatelessWidget {
  final double score;
  final int scale;

  const _CompositeScoreDisplay({required this.score, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Composite Score',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${score.toStringAsFixed(1)}/$scale',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: score >= 3.5 ? Colors.green : Colors.orange,
                ),
          ),
        ],
      ),
    );
  }
}

// -- Return intent toggle (AC-6) -----------------------------------------------

/// Pill-style return intent toggle with green check / red X indicators.
class _ReturnIntentToggle extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool> onChanged;

  const _ReturnIntentToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Would you come back?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Yes pill.
              InkWell(
                onTap: () => onChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: value == true ? Colors.green : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: value == true ? Colors.white : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Yes',
                        style: TextStyle(
                          color: value == true ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // No pill.
              InkWell(
                onTap: () => onChanged(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: value == false ? Colors.red : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 18,
                        color: value == false ? Colors.white : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'No',
                        style: TextStyle(
                          color: value == false ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -- Optional sections accordion (P4ME-16, AC-1, AC-4) -------------------------

/// Five independently expandable/collapsible accordion sections.
class _OptionalSectionsAccordion extends StatelessWidget {
  final List<bool> expanded;
  final ValueChanged<int> onToggle;
  final QuickLogFormData form;

  const _OptionalSectionsAccordion({
    required this.expanded,
    required this.onToggle,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 0: Meal total + tip + employee name + note
        _AccordionSection(
          title: 'Meal Details',
          isExpanded: expanded[0],
          onToggle: () => onToggle(0),
          child: _MealDetailsSection(form: form),
        ),

        const SizedBox(height: 8),

        // Section 1: Visit line items
        _AccordionSection(
          title: 'Line Items',
          isExpanded: expanded[1],
          onToggle: () => onToggle(1),
          child: _LineItemsSection(form: form, notifier: null),
        ),

        const SizedBox(height: 8),

        // Section 2: Food journal
        _AccordionSection(
          title: 'Food Journal',
          isExpanded: expanded[2],
          onToggle: () => onToggle(2),
          child: _JournalEntriesSection(form: form, notifier: null),
        ),

        const SizedBox(height: 8),

        // Section 3: Allergy-safe foods
        _AccordionSection(
          title: 'Allergy-Safe Foods',
          isExpanded: expanded[3],
          onToggle: () => onToggle(3),
          child: const _AllergySafeFoodsSection(),
        ),

        const SizedBox(height: 8),

        // Section 4: Restaurant notes
        _AccordionSection(
          title: 'Restaurant Notes',
          isExpanded: expanded[4],
          onToggle: () => onToggle(4),
          child: _RestaurantNotesSection(form: form),
        ),
      ],
    );
  }
}

/// A single accordion section with surface-overlay background, no elevation.
class _AccordionSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _AccordionSection({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

// -- Section 0: Meal details

/// Meal total, tip percentage, and employee/server name fields.
class _MealDetailsSection extends StatelessWidget {
  final QuickLogFormData form;

  const _MealDetailsSection({required this.form});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: form.mealTotalController ?? TextEditingController(),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Meal Total (\$)',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: '0.00',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: form.tipPercentController ?? TextEditingController(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tip (%)',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: '0',
            suffixText: '%',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: form.employeeNameController ?? TextEditingController(),
          decoration: const InputDecoration(
            labelText: 'Employee / Server Name',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: 'e.g. Alex',
          ),
        ),
      ],
    );
  }
}

// -- Section 1: Visit line items -----------------------------------------------

/// Dish name + optional price with "Add another" button.
class _LineItemsSection extends StatelessWidget {
  final QuickLogFormData form;
  final QuickLogFormNotifier? notifier;

  const _LineItemsSection({required this.form, required this.notifier});

  @override
  Widget build(BuildContext context) {
    // Always show at least one empty entry so input fields are visible.
    final items = form.lineItems.isEmpty ? [VisitLineItem(dishName: '')] : form.lineItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.dishName,
                    decoration: const InputDecoration(
                      labelText: 'Dish Name',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: item.price?.toStringAsFixed(2),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      hintText: '0.00',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: notifier != null
                      ? () => notifier!.removeLineItem(form.lineItems.indexOf(item))
                      : null,
                ),
              ],
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: notifier != null
              ? () {
                  final empty = VisitLineItem(dishName: '');
                  notifier!.addLineItem(empty.dishName, null);
                }
              : null,
          icon: const Icon(Icons.add),
          label: const Text('Add Another'),
        ),
      ],
    );
  }
}

// -- Section 2: Food journal entries -------------------------------------------

/// Dish name + impressions with "Add another" button.
class _JournalEntriesSection extends StatelessWidget {
  final QuickLogFormData form;
  final QuickLogFormNotifier? notifier;

  const _JournalEntriesSection({required this.form, required this.notifier});

  @override
  Widget build(BuildContext context) {
    // Always show at least one empty entry so input fields are visible.
    final entries = form.journalEntries.isEmpty ? [JournalEntry(dishName: '', impressions: '')] : form.journalEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: entry.dishName,
                  decoration: const InputDecoration(
                    labelText: 'Dish Name',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: entry.impressions,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Impressions',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'Describe your experience...',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: notifier != null
                        ? () => notifier!.removeJournalEntry(
                            form.journalEntries.indexOf(entry),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: notifier != null
              ? () {
                  final empty = JournalEntry(dishName: '', impressions: '');
                  notifier!.addJournalEntry(empty.dishName, empty.impressions);
                }
              : null,
          icon: const Icon(Icons.add),
          label: const Text('Add Another'),
        ),
      ],
    );
  }
}

// -- Section 3: Allergy-safe foods ---------------------------------------------

/// Add/remove from per-restaurant safe food list.
class _AllergySafeFoodsSection extends ConsumerWidget {
  const _AllergySafeFoodsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeFoods = ref.watch(allergySafeFoodsProvider);

    return safeFoods.when(
      loading: () => const Center(child: SizedBox(height: 40)),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Error loading safe foods: $e'),
      ),
      data: (foods) {
        if (foods.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No allergy-safe foods saved yet. Add them from the restaurant detail view.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: foods.map((food) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(food.itemName)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.orange),
                      onPressed: () async {
                        await ref.read(allergySafeFoodsProvider.notifier)
                            .removeSafeFood(food.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// -- Section 4: Restaurant notes -----------------------------------------------

/// Pre-populated if restaurant exists; editable.
class _RestaurantNotesSection extends StatelessWidget {
  final QuickLogFormData form;

  const _RestaurantNotesSection({required this.form});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: form.restaurantNotesController ?? TextEditingController(),
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Restaurant Notes',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintText: 'e.g. Great ambiance, noisy during lunch rush...',
      ),
    );
  }
}
