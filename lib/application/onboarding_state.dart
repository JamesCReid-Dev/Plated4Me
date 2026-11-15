/// Onboarding state manager — tracks multi-step flow, selections, and defaults (AC-1 through AC-6).
///
/// This class holds transient onboarding state across the 4 screens and provides
/// methods for navigation, selection management, skip-with-defaults, and building
/// final [UserPreferences] when the user completes.
import 'package:plated4me/domain/entities/entities.dart';

/// Manages the state of the multi-step onboarding flow.
class OnboardingState {
  /// The current screen index (0 = allergies, 1 = cuisine, 2 = rating, 3 = occasions).
  int currentScreen;

  /// Allergens selected by the user.
  final List<Allergen> selectedAllergens;

  /// Cuisine preferences selected by the user.
  final List<String> cuisinePreferences;

  /// Chosen rating scale (5 or 10), null if skipped.
  int? ratingScaleChoice;

  /// Selected default occasions.
  final List<String> selectedOccasions;

  /// Total number of onboarding screens.
  static const totalScreens = 4;

  /// The 20 preset cuisine options (AC-2).
  static const presetCuisines = [
    'Japanese', 'Mexican', 'Italian', 'Chinese', 'Thai',
    'Indian', 'American', 'Mediterranean', 'French', 'Korean',
    'Vietnamese', 'Greek', 'Turkish', 'Ethiopian', 'Brazilian',
    'Lebanese', 'Spanish', 'German', 'Swedish', 'Indonesian',
  ];

  /// Valid rating scale options (AC-3).
  static const validRatingScales = [5, 10];

  /// Pre-populated default occasions (AC-4).
  static const defaultOccasions = [
    'Date Night', 'Family Dinner', 'Business Lunch',
    'Quick Bite', 'Celebration', 'Trying Something New',
  ];

  /// Creates the initial onboarding state.
  factory OnboardingState.initial() => OnboardingState();

  /// Creates the initial onboarding state.
  OnboardingState({
    this.currentScreen = 0,
    List<Allergen>? selectedAllergens,
    List<String>? cuisinePreferences,
    this.ratingScaleChoice,
    List<String>? selectedOccasions,
  })  : selectedAllergens = selectedAllergens ?? [],
        cuisinePreferences = cuisinePreferences ?? [],
        selectedOccasions = selectedOccasions ?? [];

  // -- Screen navigation -------------------------------------------------------

  /// Advance to the next screen; no-op at the last screen.
  void nextScreen() {
    if (currentScreen < totalScreens - 1) {
      currentScreen++;
    }
  }

  /// Go back to the previous screen; no-op at screen 0.
  void previousScreen() {
    if (currentScreen > 0) {
      currentScreen--;
    }
  }

  // -- Allergen management (AC-1) ----------------------------------------------

  /// Adds or replaces an allergen with the given [name] and [severity].
  void addAllergen(String name, AllergenSeverity severity) {
    final existingIndex = selectedAllergens.indexWhere((a) => a.name == name);
    if (existingIndex >= 0) {
      selectedAllergens[existingIndex] = Allergen(name: name, severity: severity.value);
    } else {
      selectedAllergens.add(Allergen(name: name, severity: severity.value));
    }
  }

  /// Removes an allergen by [name].
  void removeAllergen(String name) {
    selectedAllergens.removeWhere((a) => a.name == name);
  }

  // -- Cuisine preferences (AC-2) ----------------------------------------------

  /// Adds a cuisine preference if not already present.
  void addCuisinePreference(String cuisine) {
    if (!cuisinePreferences.contains(cuisine)) {
      cuisinePreferences.add(cuisine);
    }
  }

  /// Removes a cuisine preference.
  void removeCuisinePreference(String cuisine) {
    cuisinePreferences.remove(cuisine);
  }

  // -- Rating scale (AC-3) -----------------------------------------------------

  /// Sets the chosen rating scale; must be 5 or 10.
  void setRatingScale(int scale) {
    if (validRatingScales.contains(scale)) {
      ratingScaleChoice = scale;
    }
  }

  // -- Default occasions (AC-4) ------------------------------------------------

  /// Adds an occasion by name.
  void addOccasion(String occasion) {
    if (!selectedOccasions.contains(occasion)) {
      selectedOccasions.add(occasion);
    }
  }

  /// Removes an occasion by name.
  void removeOccasion(String occasion) {
    selectedOccasions.remove(occasion);
  }

  /// Adds a custom occasion (not in the pre-populated list).
  void addCustomOccasion(String occasion) {
    addOccasion(occasion);
  }

  // -- Skip with defaults (AC-6) -----------------------------------------------

  /// Applies default values for screen [index] when skipped.
  void skipScreen(int index) {
    switch (index) {
      case 0:
        // Allergies — skip means no allergies (empty list, already the default)
        break;
      case 1:
        // Cuisine — skip means no preferences (already empty by default)
        break;
      case 2:
        // Rating scale — skip defaults to 5-star
        ratingScaleChoice = null; // buildPreferences will use 5 as fallback
        break;
      case 3:
        // Occasions — skip means all pre-populated occasions are available
        selectedOccasions.clear();
        selectedOccasions.addAll(defaultOccasions);
        break;
    }
  }

  // -- Build final preferences -------------------------------------------------

  /// Builds [UserPreferences] from the current onboarding state.
  ///
  /// Skipped sections use sensible defaults:
  /// - Allergies: empty list
  /// - Cuisine: empty list (user can add later)
  /// - Rating scale: 5 if not chosen
  /// - Occasions: all pre-populated if none selected
  UserPreferences buildPreferences() {
    final prefs = UserPreferences(
      allergies: List.unmodifiable(selectedAllergens),
      cuisinePreferences: List.unmodifiable(cuisinePreferences),
      ratingScale: ratingScaleChoice ?? 5,
      defaultOccasions: selectedOccasions.isEmpty
          ? List.unmodifiable(defaultOccasions)
          : List.unmodifiable(selectedOccasions),
      onboardingComplete: true,
    );
    return prefs;
  }
}
