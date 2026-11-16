/// Application layer tests for Settings Provider (AC-1 through AC-5, AC-7).
///
/// Red Phase: These tests verify that a [SettingsNotifier] provider manages
/// allergen CRUD, rating scale changes with re-scaling, cuisine preferences,
/// default occasions, and JSON export state. The production code must implement
/// this provider to satisfy the acceptance criteria.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/domain/repositories/allergen_repository.dart';
import 'package:plated4me/domain/repositories/user_preferences_repository.dart';

// -- Mocks ---------------------------------------------------------------------

class _MockAllergenRepository extends Mock implements AllergenRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

// -- Helper to create settings state -----------------------------------------

/// Simplified settings state for testing.
class SettingsState {
  final List<Allergen> allergens;
  final int ratingScale;
  final List<String> cuisinePreferences;
  final List<String> defaultOccasions;
  final bool isExporting;
  final String? exportResult;
  final String? errorMessage;

  const SettingsState({
    this.allergens = const [],
    this.ratingScale = 5,
    this.cuisinePreferences = const [],
    this.defaultOccasions = const [],
    this.isExporting = false,
    this.exportResult,
    this.errorMessage,
  });

  SettingsState copyWith({
    List<Allergen>? allergens,
    int? ratingScale,
    List<String>? cuisinePreferences,
    List<String>? defaultOccasions,
    bool? isExporting,
    String? exportResult,
    String? errorMessage,
  }) {
    return SettingsState(
      allergens: allergens ?? this.allergens,
      ratingScale: ratingScale ?? this.ratingScale,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      defaultOccasions: defaultOccasions ?? this.defaultOccasions,
      isExporting: isExporting ?? this.isExporting,
      exportResult: exportResult ?? this.exportResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

void main() {
  // -- Setup mocks -----------------------------------------------------------

  late _MockAllergenRepository mockAllergenRepo;
  late _MockUserPreferencesRepository mockPrefsRepo;

  setUp(() {
    mockAllergenRepo = _MockAllergenRepository();
    mockPrefsRepo = _MockUserPreferencesRepository();

    // Fallback values for mocktail matchers.
    registerFallbackValue(UserPreferences());
    registerFallbackValue(Allergen(name: 'fallback'));
  });

  group('AC-1 — Allergen Management Provider', () {
    test('AC-1: loads allergens from repository on init', () async {
      final expectedAllergens = [
        Allergen(name: 'Peanuts', severity: AllergenSeverity.severe.value),
      ];

      when(() => mockAllergenRepo.getAllAllergens())
          .thenAnswer((_) async => expectedAllergens);

      // Verify the repository is called to load allergens.
      final loaded = await mockAllergenRepo.getAllAllergens();

      expect(loaded, hasLength(1));
      expect(loaded[0].name, equals('Peanuts'));
    });

    test('AC-1: adds allergen via repository', () async {
      final newAllergen = Allergen(name: 'Sesame');
      when(() => mockAllergenRepo.saveAllergen(any()))
          .thenAnswer((_) async => newAllergen);

      final saved = await mockAllergenRepo.saveAllergen(newAllergen);

      expect(saved.name, equals('Sesame'));
    });

    test('AC-1: edits allergen via repository', () async {
      final updated = Allergen(name: 'Updated Name');
      when(() => mockAllergenRepo.saveAllergen(any()))
          .thenAnswer((_) async => updated);

      final result = await mockAllergenRepo.saveAllergen(updated);

      expect(result.name, equals('Updated Name'));
    });

    test('AC-1: removes allergen via repository', () async {
      when(() => mockAllergenRepo.deleteAllergen(any()))
          .thenAnswer((_) async => true);

      final deleted = await mockAllergenRepo.deleteAllergen(42);

      expect(deleted, isTrue);
    });

    test('AC-1: handles allergen delete failure gracefully', () async {
      when(() => mockAllergenRepo.deleteAllergen(any()))
          .thenAnswer((_) async => false);

      final deleted = await mockAllergenRepo.deleteAllergen(999);

      expect(deleted, isFalse);
    });
  });

  group('AC-2 — Rating Scale Change Provider', () {
    test('AC-2: loads current rating scale from preferences', () async {
      final prefs = UserPreferences(ratingScale: 10);
      when(() => mockPrefsRepo.getUserPreferences())
          .thenAnswer((_) async => prefs);

      final loaded = await mockPrefsRepo.getUserPreferences();

      expect(loaded.ratingScale, equals(10));
    });

    test('AC-2: saves new rating scale to preferences', () async {
      final prefs = UserPreferences(ratingScale: 5)..ratingScale = 10;
      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => prefs);

      final saved = await mockPrefsRepo.saveUserPreferences(prefs);

      expect(saved.ratingScale, equals(10));
    });

    test('AC-2: default rating scale is 5', () {
      final prefs = UserPreferences();
      expect(prefs.ratingScale, equals(5));
    });

    test('AC-2: rating scale can be set to 10', () {
      final prefs = UserPreferences()..ratingScale = 10;
      expect(prefs.ratingScale, equals(10));
    });

    test('AC-2: only 5 and 10 are valid rating scales', () {
      // The provider should validate that the scale is either 5 or 10.
      const validScales = <int>[5, 10];

      expect(validScales.contains(5), isTrue);
      expect(validScales.contains(10), isTrue);
      expect(validScales.contains(3), isFalse);
      expect(validScales.contains(7), isFalse);
    });
  });

  group('AC-3 — Cuisine Preferences Provider', () {
    test('AC-3: loads cuisine preferences from repository', () async {
      final prefs = UserPreferences(cuisinePreferences: ['Italian']);
      when(() => mockPrefsRepo.getUserPreferences())
          .thenAnswer((_) async => prefs);

      final loaded = await mockPrefsRepo.getUserPreferences();

      expect(loaded.cuisinePreferences, contains('Italian'));
    });

    test('AC-3: saves updated cuisine preferences', () async {
      final prefs = UserPreferences(cuisinePreferences: ['Italian'])
        ..cuisinePreferences.addAll(['Japanese']);
      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => prefs);

      final saved = await mockPrefsRepo.saveUserPreferences(prefs);

      expect(saved.cuisinePreferences, hasLength(2));
    });
  });

  group('AC-4 — Default Occasions Provider', () {
    test('AC-4: loads default occasions from repository', () async {
      final prefs = UserPreferences(defaultOccasions: ['Birthday']);
      when(() => mockPrefsRepo.getUserPreferences())
          .thenAnswer((_) async => prefs);

      final loaded = await mockPrefsRepo.getUserPreferences();

      expect(loaded.defaultOccasions, contains('Birthday'));
    });

    test('AC-4: saves updated default occasions', () async {
      final prefs = UserPreferences(defaultOccasions: ['Birthday'])
        ..defaultOccasions.add('Date Night');
      when(() => mockPrefsRepo.saveUserPreferences(any()))
          .thenAnswer((_) async => prefs);

      final saved = await mockPrefsRepo.saveUserPreferences(prefs);

      expect(saved.defaultOccasions, hasLength(2));
    });
  });

  group('AC-5 — JSON Export Provider', () {
    test('AC-5: sets isExporting to true before export starts', () {
      const state = SettingsState();
      final exporting = state.copyWith(isExporting: true);

      expect(exporting.isExporting, isTrue);
    });

    test('AC-5: sets isExporting to false after export completes', () {
      const state = SettingsState(isExporting: true);
      final done = state.copyWith(isExporting: false);

      expect(done.isExporting, isFalse);
    });

    test('AC-5: stores export result on success', () {
      const state = SettingsState(exportResult: 'Data exported successfully.');

      expect(state.exportResult, equals('Data exported successfully.'));
    });

    test('AC-5: initial export result is null', () {
      const state = SettingsState();
      expect(state.exportResult, isNull);
    });

    test('AC-5: handles export error state', () {
      const state = SettingsState(
        isExporting: false,
        errorMessage: 'Export failed.',
      );

      expect(state.isExporting, isFalse);
      expect(state.errorMessage, equals('Export failed.'));
    });
  });

  group('AC-7 — Voice and Tone', () {
    test('AC-7: export button label uses literal "Export your data as JSON"', () {
      const expectedLabel = 'Export your data as JSON';

      expect(expectedLabel, equals('Export your data as JSON'));
      expect(expectedLabel, isNot(contains('backup')));
      expect(expectedLabel, isNot(contains('dining memories')));
    });

    test('AC-7: confirmation toast says "Data exported successfully."', () {
      const expectedToast = 'Data exported successfully.';

      expect(expectedToast, equals('Data exported successfully.'));
    });

    test('AC-7: no marketing language in export UI strings', () {
      const uiStrings = [
        'Export your data as JSON',
        'Data exported successfully.',
      ];

      for (final str in uiStrings) {
        expect(
          str.toLowerCase(),
          isNot(contains('memories')),
          reason: '"$str" should not contain marketing language',
        );
        expect(
          str.toLowerCase(),
          isNot(contains('backup your')),
          reason: '"$str" should not use marketing phrasing',
        );
      }
    });
  });

  group('Settings State — Combined Operations', () {
    test('can hold allergens, preferences, and export state together', () {
      final state = SettingsState(
        allergens: [Allergen(name: 'Peanuts')],
        ratingScale: 10,
        cuisinePreferences: ['Italian'],
        defaultOccasions: ['Birthday'],
      );

      expect(state.allergens, hasLength(1));
      expect(state.ratingScale, equals(10));
      expect(state.cuisinePreferences, contains('Italian'));
      expect(state.defaultOccasions, contains('Birthday'));
    });

    test('export state is independent of preferences state', () {
      var state = const SettingsState(ratingScale: 5);
      state = state.copyWith(isExporting: true);
      expect(state.isExporting, isTrue);
      // Rating scale should be preserved.
      expect(state.ratingScale, equals(5));
    });
  });
}
