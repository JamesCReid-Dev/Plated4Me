/// Quick Log screen — full-screen modal for rapid visit logging with ratings.
///
/// P4ME-15 (S07): Four weighted sliders, real-time composite score, return intent toggle,
/// and save button. All ratings use the user's chosen scale from preferences.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/application/providers/visit_rating_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Read the current scale from preferences.
    final prefs = ref.read(userPreferencesDataProvider);
    prefs.whenData(
      (p) => setState(() => _scale = p.ratingScale),
    );
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

  void _handleSave() {
    // TODO: Save visit to repository (next story iteration).
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
