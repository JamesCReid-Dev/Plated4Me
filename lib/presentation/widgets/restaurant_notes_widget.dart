/// Restaurant notes display widget.
///
/// P4ME-19 — Restaurant General Notes.
/// Displays restaurant-level general notes with empty state placeholder.
///
/// AC-5: Notes displayed in Restaurant Detail View.
/// AC-6: Empty state shows placeholder "Add notes about this restaurant".
import 'package:flutter/material.dart';
import 'package:plated4me/domain/entities/entities.dart';

/// Displays a restaurant's general notes with empty-state handling.
///
/// When [restaurant.notes] is null or empty, shows a muted placeholder
/// prompting the user to add notes. When notes exist, displays them in
/// a scrollable body.
class RestaurantNotesDisplayWidget extends StatelessWidget {
  /// The restaurant whose notes to display.
  final Restaurant restaurant;

  /// Creates a restaurant notes display widget.
  const RestaurantNotesDisplayWidget({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final notes = restaurant.notes;
    final isEmpty = notes == null || notes.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section label.
        Text(
          'General Notes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Notes content or placeholder.
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Add notes about this restaurant',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(notes),
              ),
            ),
          ),
      ],
    );
  }
}
