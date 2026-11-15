/// Onboarding screen — guided first-run setup (P4ME-12).
///
/// Four-screen flow: Allergies → Cuisine Preferences → Rating Scale → Default Occasions.
/// Every screen has a "Skip for now" button that applies sensible defaults (AC-6).
/// Completing writes [UserPreferences] to Isar and navigates to Browse/Home (AC-5).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/onboarding_state.dart';
import 'package:plated4me/application/providers/data_providers.dart';
import 'package:plated4me/domain/entities/entities.dart';

// -- Main onboarding screen ----------------------------------------------------

/// Multi-step onboarding screen with allergies, cuisine, rating, and occasions.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final OnboardingState state;

  @override
  void initState() {
    super.initState();
    state = OnboardingState.initial();
  }

  void _skip() {
    state.skipScreen(state.currentScreen);
    if (state.currentScreen < OnboardingState.totalScreens - 1) {
      state.nextScreen();
    }
  }

  void _next() {
    if (state.currentScreen < OnboardingState.totalScreens - 1) {
      state.nextScreen();
    }
  }

  void _previous() {
    state.previousScreen();
  }

  Future<void> _complete() async {
    final prefs = state.buildPreferences();
    await ref.read(userPreferencesDataProvider.notifier).savePreferences(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (state.currentScreen + 1) / OnboardingState.totalScreens,
              minHeight: 4,
            ),
            Expanded(
              child: _buildCurrentScreen(),
            ),
            // Navigation buttons at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button (always visible)
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Skip for now'),
                  ),
                  Row(
                    children: [
                      if (state.currentScreen > 0)
                        TextButton(
                          onPressed: _previous,
                          child: const Text('Back'),
                        ),
                      ElevatedButton(
                        onPressed: state.currentScreen == OnboardingState.totalScreens - 1
                            ? () async {
                                await _complete();
                                if (mounted) {
                                  // Navigate to home/browse by completing onboarding
                                  await ref
                                      .read(userPreferencesDataProvider.notifier)
                                      .completeOnboarding();
                                  // Pop the onboarding route to reach navigation shell
                                  Navigator.of(context).pop();
                                }
                              }
                            : _next,
                        child: Text(
                          state.currentScreen == OnboardingState.totalScreens - 1
                              ? 'Done'
                              : 'Next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (state.currentScreen) {
      case 0:
        return _AllergiesScreen(state: state);
      case 1:
        return _CuisineScreen(state: state);
      case 2:
        return _RatingScaleScreen(state: state);
      case 3:
        return _OccasionsScreen(state: state);
      default:
        return const SizedBox.shrink();
    }
  }
}

// -- Screen 1: Allergies (AC-1) -----------------------------------------------

class _AllergiesScreen extends StatefulWidget {
  final OnboardingState state;
  const _AllergiesScreen({required this.state});

  @override
  State<_AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<_AllergiesScreen> {
  final TextEditingController _controller = TextEditingController();
  AllergenSeverity _selectedSeverity = AllergenSeverity.moderate;

  void _addAllergen() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.state.addAllergen(name, _selectedSeverity);
      _controller.clear();
      setState(() {});
    }
  }

  void _removeAllergen(String name) {
    widget.state.removeAllergen(name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Do you have any food allergies?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add allergens and select severity level.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Severity selection
          const Text('Severity:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<AllergenSeverity>(
                  title: const Text('Moderate'),
                  value: AllergenSeverity.moderate,
                  groupValue: _selectedSeverity,
                  onChanged: (v) => setState(() => _selectedSeverity = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<AllergenSeverity>(
                  title: const Text('Severe'),
                  value: AllergenSeverity.severe,
                  groupValue: _selectedSeverity,
                  onChanged: (v) => setState(() => _selectedSeverity = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Add allergen input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Peanuts, Shellfish',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) => _addAllergen(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addAllergen, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),

          // Added allergens as chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.state.selectedAllergens.map((allergen) {
              return Chip(
                label: Text(allergen.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeAllergen(allergen.name),
                avatar: CircleAvatar(
                  backgroundColor: allergen.severity == AllergenSeverity.severe.value
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
                  child: Text(
                    allergen.severity == AllergenSeverity.severe.value ? 'S' : 'M',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// -- Screen 2: Cuisine Preferences (AC-2) --------------------------------------

class _CuisineScreen extends StatefulWidget {
  final OnboardingState state;
  const _CuisineScreen({required this.state});

  @override
  State<_CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<_CuisineScreen> {
  bool _showCustom = false;
  final TextEditingController _customController = TextEditingController();

  void _toggleCuisine(String cuisine) {
    if (widget.state.cuisinePreferences.contains(cuisine)) {
      widget.state.removeCuisinePreference(cuisine);
    } else {
      widget.state.addCuisinePreference(cuisine);
    }
    setState(() {});
  }

  void _addCustomCuisine() {
    final custom = _customController.text.trim();
    if (custom.isNotEmpty) {
      widget.state.addCuisinePreference(custom);
      _customController.clear();
      setState(() => _showCustom = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are your cuisine preferences?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the cuisines you enjoy.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Preset cuisine chips (20 options)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OnboardingState.presetCuisines.map((cuisine) {
              final isSelected = widget.state.cuisinePreferences.contains(cuisine);
              return FilterChip(
                label: Text(cuisine),
                selected: isSelected,
                onSelected: (_) => _toggleCuisine(cuisine),
                backgroundColor: Colors.white,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Custom cuisine entry
          if (_showCustom)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customController,
                    decoration: const InputDecoration(
                      hintText: 'Enter custom cuisine',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addCustomCuisine(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCustomCuisine,
                  child: const Text('Add'),
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: () => setState(() => _showCustom = true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Custom'),
            ),

          const Spacer(),

          // Selected cuisines summary
          if (widget.state.cuisinePreferences.isNotEmpty) ...[
            const Divider(),
            const Text(
              'Selected:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.state.cuisinePreferences.map((c) {
                return Chip(
                  label: Text(c),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _toggleCuisine(c),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}

// -- Screen 3: Rating Scale (AC-3) ---------------------------------------------

class _RatingScaleScreen extends StatefulWidget {
  final OnboardingState state;
  const _RatingScaleScreen({required this.state});

  @override
  State<_RatingScaleScreen> createState() => _RatingScaleScreenState();
}

class _RatingScaleScreenState extends State<_RatingScaleScreen> {
  int? _selectedScale;

  @override
  void initState() {
    super.initState();
    _selectedScale = widget.state.ratingScaleChoice;
  }

  void _selectScale(int scale) {
    setState(() => _selectedScale = scale);
    widget.state.setRatingScale(scale);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How would you like to rate restaurants?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your preferred rating scale.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Two large tappable cards
          Expanded(
            child: ListView(
              children: [
                _RatingScaleCard(
                  title: '5-Star Rating',
                  subtitle: '★★★★★',
                  description: 'Rate from 1 to 5 stars',
                  isSelected: _selectedScale == 5,
                  onTap: () => _selectScale(5),
                ),
                const SizedBox(height: 16),
                _RatingScaleCard(
                  title: '10-Star Rating',
                  subtitle: '⭐ × 10',
                  description: 'Rate from 1 to 10 stars',
                  isSelected: _selectedScale == 10,
                  onTap: () => _selectScale(10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A large tappable card for rating scale selection (AC-3).
class _RatingScaleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingScaleCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Star display
              if (title.contains('5'))
                const StarRating(rating: 5, size: 32)
              else
                const Text('⭐ × 10', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Star rating widget — displays filled and empty stars.
class StarRating extends StatelessWidget {
  /// Number of stars to display.
  final int rating;

  /// Size of each star icon.
  final double size;

  /// Color of filled stars.
  final Color? color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rating,
        (index) => Icon(
          Icons.star,
          size: size,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// -- Screen 4: Default Occasions (AC-4) ----------------------------------------

class _OccasionsScreen extends StatefulWidget {
  final OnboardingState state;
  const _OccasionsScreen({required this.state});

  @override
  State<_OccasionsScreen> createState() => _OccasionsScreenState();
}

class _OccasionsScreenState extends State<_OccasionsScreen> {
  bool _showCustom = false;
  final TextEditingController _customController = TextEditingController();

  void _toggleOccasion(String occasion) {
    if (widget.state.selectedOccasions.contains(occasion)) {
      widget.state.removeOccasion(occasion);
    } else {
      widget.state.addOccasion(occasion);
    }
    setState(() {});
  }

  void _addCustomOccasion() {
    final custom = _customController.text.trim();
    if (custom.isNotEmpty) {
      widget.state.addCustomOccasion(custom);
      _customController.clear();
      setState(() => _showCustom = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are your default occasions?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the occasions you dine out for. These will be pre-selected on each visit.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Pre-populated occasion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OnboardingState.defaultOccasions.map((occasion) {
              final isSelected = widget.state.selectedOccasions.contains(occasion);
              return FilterChip(
                label: Text(occasion),
                selected: isSelected,
                onSelected: (_) => _toggleOccasion(occasion),
                backgroundColor: Colors.white,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Custom occasion entry
          if (_showCustom)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Brunch with Friends',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addCustomOccasion(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCustomOccasion,
                  child: const Text('Add'),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.add, size: 18),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(() => _showCustom = true),
                  child: const Text('Add custom occasion'),
                ),
              ],
            ),

          const Spacer(),

          // Selected occasions summary
          if (widget.state.selectedOccasions.isNotEmpty) ...[
            const Divider(),
            const Text(
              'Selected:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.state.selectedOccasions.map((o) {
                return Chip(
                  label: Text(o),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _toggleOccasion(o),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}
