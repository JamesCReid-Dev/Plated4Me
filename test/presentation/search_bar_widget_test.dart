/// Widget tests for SearchBarWidget — search bar with clear button.
///
/// P4ME-18 — Full-Text Search.
/// AC-1 (search bar visible), AC-5 (focus + keyboard), AC-6 (clear).
/// P4ME-48 — Cursor jump fix: controller sync gated during active typing.
/// P4ME-49 — Explicit 200ms debounce in UI layer satisfies AC-5 requirement.

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

      // Type a query and wait for 200ms debounce to fire.
      await tester.enterText(find.byType(TextField), 'Sakura');
      await tester.pump(const Duration(milliseconds: 200));

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

    // ------------------------------------------------------------------
    // P4ME-48 — Cursor jump fix: controller sync gated during active typing
    // ------------------------------------------------------------------

    testWidgets('P4ME-48-1 — external provider change syncs to controller when not typing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget)));
      final textField = tester.widget<TextField>(find.byType(TextField));
      final controller = textField.controller!;

      // Initially both are empty.
      expect(controller.text, isEmpty);
      expect(container.read(searchProvider).query, isEmpty);

      // Provider state changes externally (not via user typing).
      container.read(searchProvider.notifier).setQuery('External');
      await tester.pump();

      // Controller should sync to the new provider query.
      expect(controller.text, 'External');
    });

    testWidgets('P4ME-48-2 — controller text does NOT get overwritten during active typing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget)));
      final textField = tester.widget<TextField>(find.byType(TextField));
      final controller = textField.controller!;

      // Type a query — onChanged fires, _isUserTyping becomes true.
      await tester.enterText(find.byType(TextField), 'abc');
      // Pump WITHOUT waiting for debounce — provider has NOT updated yet.
      // The controller text should remain exactly what the user typed.
      expect(controller.text, 'abc');

      // Now trigger an external provider change while _isUserTyping is still true
      // (simulating a rapid build before onChanged's flag resets).
      container.read(searchProvider.notifier).setQuery('external-change');
      await tester.pump();

      // The controller should NOT have been overwritten by the external query.
      // Without the fix, _controller.text would become 'external-change'.
      expect(controller.text, 'abc');
    });

    testWidgets('P4ME-48-3 — after typing stops (debounce fires), values stay in sync', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget)));
      final textField = tester.widget<TextField>(find.byType(TextField));
      final controller = textField.controller!;

      // Type a query and wait for debounce to fire.
      await tester.enterText(find.byType(TextField), 'Sakura');
      await tester.pump(const Duration(milliseconds: 200));

      // Both controller and provider should hold the same value.
      expect(controller.text, 'Sakura');
      expect(container.read(searchProvider).query, 'Sakura');
    });

    testWidgets('P4ME-48-4 — clearQuery() syncs controller to empty when not typing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget)));
      final textField = tester.widget<TextField>(find.byType(TextField));
      final controller = textField.controller!;

      // Type a query and wait for debounce to fire.
      await tester.enterText(find.byType(TextField), 'Sakura');
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.text, 'Sakura');

      // Clear via provider (simulating external clear).
      container.read(searchProvider.notifier).clearQuery();
      await tester.pump();

      // Controller should sync to empty.
      expect(controller.text, isEmpty);
      expect(container.read(searchProvider).query, isEmpty);
    });

    // ------------------------------------------------------------------
    // P4ME-49 — Explicit 200ms debounce in UI layer satisfies AC-5
    // ------------------------------------------------------------------

    testWidgets('P4ME-49-1 — provider does NOT update during typing (debounce active)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget)));

      // Type a query — onChanged fires but debounce timer has not yet fired.
      await tester.enterText(find.byType(TextField), 'Sakura');
      // Pump immediately — no wait for debounce.
      await tester.pump();

      // Provider should NOT have updated yet (debounce prevents immediate update).
      expect(container.read(searchProvider).query, isEmpty);
    });

    testWidgets('P4ME-49-2 — provider updates 200ms after typing stops', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget)));

      // Type a query.
      await tester.enterText(find.byType(TextField), 'Sakura');
      // Wait for debounce to fire.
      await tester.pump(const Duration(milliseconds: 200));

      // Provider should now have the query.
      expect(container.read(searchProvider).query, 'Sakura');
    });

    testWidgets('P4ME-49-3 — rapid keystrokes cancel and restart debounce timer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget)));
      final textField = find.byType(TextField);

      // Type 'S' — timer starts.
      await tester.enterText(textField, 'S');
      await tester.pump(const Duration(milliseconds: 100));
      // Not enough time for debounce — provider should still be empty.
      expect(container.read(searchProvider).query, isEmpty);

      // Type 'Sa' — timer cancelled and restarted.
      await tester.enterText(textField, 'Sa');
      await tester.pump(const Duration(milliseconds: 100));
      // Still not enough time — provider should still be empty.
      expect(container.read(searchProvider).query, isEmpty);

      // Wait another 200ms from last keystroke.
      await tester.pump(const Duration(milliseconds: 200));

      // Only the LAST value ('Sa') should reach the provider.
      expect(container.read(searchProvider).query, 'Sa');
    });

    testWidgets('P4ME-49-4 — whitespace input clears query after debounce fires', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ProviderScope(
            overrides: [searchProvider.overrideWith(() => SearchNotifier())],
            child: const Scaffold(body: SearchBarWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(SearchBarWidget)));

      // First type a real query and let debounce fire.
      await tester.enterText(find.byType(TextField), 'Sakura');
      await tester.pump(const Duration(milliseconds: 200));
      expect(container.read(searchProvider).query, 'Sakura');

      // Now type whitespace — debounced setQuery('   ') trims to empty and clears.
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 200));

      // Whitespace should clear the query after debounce fires (trimmed to empty).
      expect(container.read(searchProvider).query, isEmpty);
    });
  });
}
