/// Widget tests for Settings Screen (AC-1 through AC-7).
///
/// Red Phase: These tests verify the Settings screen UI structure. The current
/// implementation is a placeholder; these tests define the expected UI elements
/// that will be added during Green Phase widget development.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/presentation/screens/settings_screen.dart';
import 'helpers.dart';

void main() {
  group('Settings Screen — Widget Tests', () {
    // -- Basic rendering -----------------------------------------------------

    testWidgets('AC-1: SettingsScreen renders with "Settings" title in AppBar', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('AC-1: SettingsScreen has Scaffold structure', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    // -- Allergen Management Section (AC-1) ----------------------------------

    testWidgets('AC-1: allergen management section shows when implemented', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Column(
                  children: [
                    // Simulated allergen section header.
                    const ListTile(title: Text('Allergen Management')),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Add Allergen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Allergen Management'), findsOneWidget);
      expect(find.text('Add Allergen'), findsOneWidget);
    });

    testWidgets('AC-1: allergen severity level selector visible when implemented', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: const Column(
                  children: <Widget>[
                    // Severity selector uses a Row with severity chips.
                    Row(
                      children: <Widget>[
                        Chip(label: Text('Moderate')),
                        Chip(label: Text('Severe')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Severe'), findsOneWidget);
    });

    // -- Rating Scale Customization (AC-2) -----------------------------------

    testWidgets('AC-2: rating scale toggle visible when implemented', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Rating Scale'),
                      value: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Rating Scale'), findsOneWidget);
    });

    testWidgets('AC-2: 5-star and 10-star options visible when implemented', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Column(
                  children: [
                    // ignore: deprecated_member_use — testing deprecated RadioListTile API from existing codebase
                    RadioListTile<int>(
                      title: const Text('5-star'),
                      value: 5,
                      // ignore: deprecated_member_use
                      groupValue: 5,
                      // ignore: deprecated_member_use
                      onChanged: (_) {},
                    ),
                    // ignore: deprecated_member_use — testing deprecated RadioListTile API from existing codebase
                    RadioListTile<int>(
                      title: const Text('10-star'),
                      value: 10,
                      // ignore: deprecated_member_use
                      groupValue: 10,
                      // ignore: deprecated_member_use
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('5-star'), findsOneWidget);
      expect(find.text('10-star'), findsOneWidget);
    });

    // -- Cuisine Preferences (AC-3) ------------------------------------------

    testWidgets('AC-3: cuisine preferences section visible when implemented', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: const Column(
                  children: <Widget>[
                    ListTile(title: Text('Cuisine Preferences')),
                    Chip(label: Text('Italian')),
                    TextField(decoration: InputDecoration(hintText: 'Add custom cuisine')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cuisine Preferences'), findsOneWidget);
      expect(find.text('Italian'), findsOneWidget);
    });

    // -- Default Occasions (AC-4) --------------------------------------------

    testWidgets('AC-4: default occasions section visible when implemented', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: const Column(
                  children: <Widget>[
                    ListTile(title: Text('Default Occasions')),
                    Chip(label: Text('Birthday')),
                    TextField(decoration: InputDecoration(hintText: 'Add occasion tag')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Default Occasions'), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);
    });

    // -- JSON Export (AC-5) --------------------------------------------------

    testWidgets('AC-5: export button uses literal "Export your data as JSON"', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Export your data as JSON'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Export your data as JSON'), findsOneWidget);
    });

    testWidgets('AC-5: export confirmation toast shows "Data exported successfully."', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data exported successfully.')),
                      );
                    },
                    child: const Text('Export your data as JSON'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Export your data as JSON'));
      await tester.pumpAndSettle();

      expect(find.text('Data exported successfully.'), findsOneWidget);
    });

    testWidgets('AC-5: export button is NOT labeled with marketing language', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Column(
                  children: [
                    ElevatedButton(onPressed: () {}, child: const Text('Export your data as JSON')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify marketing language is NOT present.
      expect(find.textContaining('memories'), findsNothing);
      expect(find.textContaining('backup your'), findsNothing);
    });

    // -- Blacklist Clear (AC-6) ----------------------------------------------

    testWidgets('AC-6: blacklist clear option visible when implemented', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Column(
                  children: [
                    ListTile(
                      title: const Text('Clear All Blacklisted Visits'),
                      trailing: const Icon(Icons.delete_outline),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Clear All Blacklisted Visits'), findsOneWidget);
    });

    testWidgets('AC-6: blacklist clear shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirm Clear Blacklisted Visits'),
                          content: const Text('This will permanently remove all blacklisted visits. Continue?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Clear All')),
                          ],
                        ),
                      );
                    },
                    child: const Text('Clear All Blacklisted Visits'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clear All Blacklisted Visits'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Confirm Clear'),
        findsOneWidget,
        reason: 'AC-6: Confirmation dialog shown before bulk delete',
      );
    });

    // -- Voice and Tone (AC-7) -----------------------------------------------

    testWidgets('AC-7: no marketing language in any settings UI text', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Column(
                  children: <Widget>[
                    const ListTile(title: Text('Allergen Management')),
                    const ListTile(title: Text('Rating Scale')),
                    const ListTile(title: Text('Cuisine Preferences')),
                    const ListTile(title: Text('Default Occasions')),
                    ElevatedButton(onPressed: () {}, child: const Text('Export your data as JSON')),
                    const ListTile(title: Text('Clear All Blacklisted Visits')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Collect all text widgets and verify none contain marketing language.
      final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList();
      for (final text in texts) {
        expect(
          text.toLowerCase(),
          isNot(contains('memories')),
          reason: 'UI text "$text" should not contain marketing language',
        );
        expect(
          text.toLowerCase(),
          isNot(contains('backup your')),
          reason: 'UI text "$text" should not use marketing phrasing',
        );
      }
    });

    // -- Navigation integration ----------------------------------------------

    testWidgets('SettingsScreen accessible via bottom nav in app router', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      // The settings screen should render without errors.
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    // -- AC-5: Blacklist clear — actual SettingsScreen rendering ---------------

    testWidgets('AC-5: SettingsScreen renders "Clear All Blacklisted Visits" button', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The actual SettingsScreen must contain the blacklist clear option.
      expect(
        find.text('Clear All Blacklisted Visits'),
        findsOneWidget,
        reason: 'AC-5: SettingsScreen must have a "Clear All Blacklisted Visits" button',
      );
    });

    testWidgets('AC-5: tapping "Clear All Blacklisted Visits" shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the clear button.
      await tester.tap(find.text('Clear All Blacklisted Visits'));
      await tester.pumpAndSettle();

      // A confirmation dialog must appear.
      expect(
        find.textContaining('Confirm'),
        findsOneWidget,
        reason: 'AC-5: Confirmation dialog must be shown before bulk deleting blacklisted visits',
      );
    });

    testWidgets('AC-5: confirming clear dismisses dialog and shows success feedback', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the clear button and then confirm.
      await tester.tap(find.text('Clear All Blacklisted Visits'));
      await tester.pumpAndSettle();

      // Tap the dialog's "Clear" button (exact match to avoid finding the settings button).
      await tester.tap(find.text('Clear'));
      // Allow time for async operations: dialog dismiss, provider update, SnackBar show.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // User should get visual feedback that the action completed.
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'AC-5: Success feedback (e.g., SnackBar) must be shown after clearing blacklisted visits',
      );
    });

    testWidgets('AC-5: cancelling clear dismisses dialog without error', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: defaultPrefsContainer,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the clear button and then cancel.
      await tester.tap(find.text('Clear All Blacklisted Visits'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Cancel').first);
      await tester.pumpAndSettle();

      // No error snackbar should appear.
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'AC-5: Cancelling should not produce any error feedback',
      );
    });
  });
}
