/// Widget tests for SearchBarWidget — search bar with clear button.
///
/// P4ME-18 — Full-Text Search.
/// AC-1 (search bar visible), AC-5 (focus + keyboard), AC-6 (clear).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/application/providers/search_provider.dart';
import 'package:plated4me/presentation/widgets/search_bar_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchBarWidget', () {
    testWidgets('AC-1 — renders search text field with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      // TextField should be present.
      expect(find.byType(TextField), findsOneWidget);
      // Search icon prefix.
      expect(find.byIcon(Icons.search), findsOneWidget);
      // Clear button should NOT appear when query is empty.
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('AC-6 — clear button appears and clears query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      // Type a query.
      await tester.enterText(find.byType(TextField), 'Sakura');
      await tester.pump(); // trigger onChanged → setQuery

      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button.
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      final state = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget))).read(searchProvider);
      expect(state.query, isEmpty);
      expect(state.searchResults, isNull);
    });

    testWidgets('AC-5 — TextField autofocus shows keyboard', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      // TextField should have autofocus enabled.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
    });
  });
}
