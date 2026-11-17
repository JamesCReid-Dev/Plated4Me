/// Riverpod provider for Quick Log optional-section form data.
///
/// Manages text editing controllers, line items, journal entries, and accordion
/// expand state for the five optional sections in QuickLogScreen (AC-1, P4ME-16).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/domain/entities/entities.dart';

// -- Form data model -----------------------------------------------------------

/// Collects all optional-section data from the Quick Log screen.
class QuickLogFormData {
  /// Meal total amount controller (nullable — initialised lazily).
  final TextEditingController? mealTotalController;

  /// Tip percentage controller (nullable — initialised lazily).
  final TextEditingController? tipPercentController;

  /// Employee/server name controller (nullable — initialised lazily).
  final TextEditingController? employeeNameController;

  /// General restaurant notes controller (nullable — initialised lazily).
  final TextEditingController? generalNotesController;

  /// Visit line items (dish name + optional price).
  final List<VisitLineItem> lineItems;

  /// Food journal entries (dish name + impressions).
  final List<JournalEntry> journalEntries;

  /// Expanded state for each accordion section.
  /// Index mapping: 0=Meal, 1=Line Items, 2=Journal, 3=Allergy-safe, 4=Notes.
  final List<bool> expanded;

  /// Creates form data with optional controllers and empty lists.
  QuickLogFormData({
    this.mealTotalController,
    this.tipPercentController,
    this.employeeNameController,
    this.generalNotesController,
    List<VisitLineItem>? lineItems,
    List<JournalEntry>? journalEntries,
    List<bool>? expanded,
  })  : lineItems = lineItems ?? [],
        journalEntries = journalEntries ?? [],
        expanded = expanded ?? [false, false, false, false, false];

  /// Parses meal total from the controller text.
  double? get mealTotal {
    final ctrl = mealTotalController;
    if (ctrl == null) return null;
    final text = ctrl.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Parses tip percent from the controller text.
  double? get tipPercent {
    final ctrl = tipPercentController;
    if (ctrl == null) return null;
    final text = ctrl.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Disposes all text editing controllers.
  void dispose() {
    mealTotalController?.dispose();
    tipPercentController?.dispose();
    employeeNameController?.dispose();
    generalNotesController?.dispose();
  }

  /// Resets all form data to empty state.
  void reset() {
    mealTotalController?.clear();
    tipPercentController?.clear();
    employeeNameController?.clear();
    generalNotesController?.clear();
    lineItems.clear();
    journalEntries.clear();
    for (var i = 0; i < expanded.length; i++) {
      expanded[i] = false;
    }
  }
}

// -- Notifier ------------------------------------------------------------------

/// Manages optional-section form data for QuickLogScreen.
class QuickLogFormNotifier extends StateNotifier<QuickLogFormData> {
  /// Creates a new controller if null, preserving existing ones.
  static TextEditingController _ensureController(TextEditingController? ctrl) {
    return ctrl ?? TextEditingController();
  }

  QuickLogFormNotifier() : super(QuickLogFormData());

  /// Toggles the expanded state of accordion section at [index].
  void toggleAccordion(int index) {
    if (index >= 0 && index < state.expanded.length) {
      final updated = List<bool>.from(state.expanded);
      updated[index] = !updated[index];
      state = QuickLogFormData(
        mealTotalController: _ensureController(state.mealTotalController),
        tipPercentController: _ensureController(state.tipPercentController),
        employeeNameController: _ensureController(state.employeeNameController),
        generalNotesController: _ensureController(state.generalNotesController),
        lineItems: List<VisitLineItem>.from(state.lineItems),
        journalEntries: List<JournalEntry>.from(state.journalEntries),
        expanded: updated,
      );
    }
  }

  /// Adds a line item with the given [dishName] and optional [price].
  void addLineItem(String dishName, double? price) {
    if (dishName.trim().isEmpty) return;
    final item = VisitLineItem(dishName: dishName.trim())..price = price;
    state = QuickLogFormData(
      mealTotalController: _ensureController(state.mealTotalController),
      tipPercentController: _ensureController(state.tipPercentController),
      employeeNameController: _ensureController(state.employeeNameController),
      generalNotesController: _ensureController(state.generalNotesController),
      lineItems: [...state.lineItems, item],
      journalEntries: List<JournalEntry>.from(state.journalEntries),
      expanded: List<bool>.from(state.expanded),
    );
  }

  /// Removes a line item at [index].
  void removeLineItem(int index) {
    if (index < 0 || index >= state.lineItems.length) return;
    final items = List<VisitLineItem>.from(state.lineItems)..removeAt(index);
    state = QuickLogFormData(
      mealTotalController: _ensureController(state.mealTotalController),
      tipPercentController: _ensureController(state.tipPercentController),
      employeeNameController: _ensureController(state.employeeNameController),
      generalNotesController: _ensureController(state.generalNotesController),
      lineItems: items,
      journalEntries: List<JournalEntry>.from(state.journalEntries),
      expanded: List<bool>.from(state.expanded),
    );
  }

  /// Adds a journal entry with the given [dishName] and [impressions].
  void addJournalEntry(String dishName, String impressions) {
    if (dishName.trim().isEmpty) return;
    final entry = JournalEntry(
      dishName: dishName.trim(),
      impressions: impressions.trim(),
    );
    state = QuickLogFormData(
      mealTotalController: _ensureController(state.mealTotalController),
      tipPercentController: _ensureController(state.tipPercentController),
      employeeNameController: _ensureController(state.employeeNameController),
      generalNotesController: _ensureController(state.generalNotesController),
      lineItems: List<VisitLineItem>.from(state.lineItems),
      journalEntries: [...state.journalEntries, entry],
      expanded: List<bool>.from(state.expanded),
    );
  }

  /// Removes a journal entry at [index].
  void removeJournalEntry(int index) {
    if (index < 0 || index >= state.journalEntries.length) return;
    final entries = List<JournalEntry>.from(state.journalEntries)..removeAt(index);
    state = QuickLogFormData(
      mealTotalController: _ensureController(state.mealTotalController),
      tipPercentController: _ensureController(state.tipPercentController),
      employeeNameController: _ensureController(state.employeeNameController),
      generalNotesController: _ensureController(state.generalNotesController),
      lineItems: List<VisitLineItem>.from(state.lineItems),
      journalEntries: entries,
      expanded: List<bool>.from(state.expanded),
    );
  }

  /// Builds a snapshot of the current form data for saving.
  QuickLogFormData snapshot() => QuickLogFormData(
        mealTotalController: TextEditingController(
          text: state.mealTotalController?.text ?? '',
        ),
        tipPercentController: TextEditingController(
          text: state.tipPercentController?.text ?? '',
        ),
        employeeNameController: TextEditingController(
          text: state.employeeNameController?.text ?? '',
        ),
        generalNotesController: TextEditingController(
          text: state.generalNotesController?.text ?? '',
        ),
        lineItems: List<VisitLineItem>.from(state.lineItems),
        journalEntries: List<JournalEntry>.from(state.journalEntries),
      );
}

// -- Provider ------------------------------------------------------------------

/// Provider for quick log optional-section form data.
final StateNotifierProvider<QuickLogFormNotifier, QuickLogFormData>
quickLogFormProvider =
    StateNotifierProvider<QuickLogFormNotifier, QuickLogFormData>(
      (_) => QuickLogFormNotifier(),
      name: 'quickLogForm',
    );
