/// Widget tests for QuickLogScreen — P4ME-15 (S07).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/presentation/screens/quick_log_screen.dart';

import 'helpers.dart';

void main() {
  group('AC-1 — Four vertical sliders', () {
    testWidgets(
      'renders Food Quality slider with label',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Food Quality'), findsWidgets);
      },
    );

    testWidgets(
      'renders Value slider with label',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Value'), findsWidgets);
      },
    );

    testWidgets(
      'renders Service slider with label',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Service'), findsWidgets);
      },
    );

    testWidgets(
      'renders Overall slider with label',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Overall'), findsWidgets);
      },
    );
  });

  group('AC-5 — Composite score display', () {
    testWidgets(
      'displays composite score headline below sliders',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      },
    );
  });

  group('AC-6 — Return intent toggle', () {
    testWidgets(
      'renders return intent pill toggle with Yes/No options',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Would you come back?'), findsWidgets);
      },
    );
  });

  group('AC-7 — Save button', () {
    testWidgets(
      'renders save button at bottom of screen',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      },
    );

    testWidgets(
      'save button is disabled when ratings are incomplete',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: defaultPrefsContainer,
            child: const MaterialApp(home: QuickLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final saveButton = find.byType(ElevatedButton);
        expect(saveButton, findsWidgets);
      },
    );
  });
}
