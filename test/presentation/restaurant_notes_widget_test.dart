/// Presentation layer widget tests for Restaurant Notes display.
///
/// P4ME-19 — Restaurant General Notes.
/// Covers AC-5: Notes displayed in Restaurant Detail View.
/// Covers AC-6: Empty state shows placeholder "Add notes about this restaurant".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/widgets/restaurant_notes_widget.dart';

void main() {
  group('P4ME-19 — RestaurantNotesDisplayWidget', () {
    Widget _buildWidget(String? notes) {
      return MaterialApp(
        home: Scaffold(
          body: RestaurantNotesDisplayWidget(
            restaurant: Restaurant(name: 'Test Restaurant')..notes = notes,
          ),
        ),
      );
    }

    testWidgets(
      'AC-6 — empty state shows placeholder "Add notes about this restaurant"',
      (tester) async {
        await tester.pumpWidget(_buildWidget(null));

        expect(
          find.text('Add notes about this restaurant'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC-6 — empty string also shows placeholder',
      (tester) async {
        await tester.pumpWidget(_buildWidget(''));

        expect(
          find.text('Add notes about this restaurant'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC-5 — displays existing notes content',
      (tester) async {
        await tester.pumpWidget(_buildWidget('Great ambiance and friendly staff'));

        expect(
          find.text('Great ambiance and friendly staff'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC-5 — multi-line notes are displayed',
      (tester) async {
        const multilineNotes = 'First line.\nSecond line.\nThird line.';
        await tester.pumpWidget(_buildWidget(multilineNotes));

        expect(
          find.text(multilineNotes),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC-5 — notes section has a label "General Notes"',
      (tester) async {
        await tester.pumpWidget(_buildWidget('Test notes'));

        expect(
          find.text('General Notes'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC-6 — empty state shows placeholder in muted styling',
      (tester) async {
        await tester.pumpWidget(_buildWidget(null));

        // The placeholder text should be present and visible.
        expect(find.text('Add notes about this restaurant'), findsOneWidget);
        final textWidget = tester.widget<Text>(find.text('Add notes about this restaurant'));
        expect(textWidget.style?.fontStyle, equals(FontStyle.italic));
      },
    );

    testWidgets(
      'AC-5 — long notes are scrollable',
      (tester) async {
        final longNotes = List.generate(100, (i) => 'Line ${i + 1}').join('\n');
        await tester.pumpWidget(_buildWidget(longNotes));

        // Should be able to scroll — the body should contain a SingleChildScrollView or similar.
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      },
    );
  });
}
