// Basic Flutter widget smoke test for Plated4Me.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: Plated4MeApp()));
    await tester.pump();

    // The app should render a bottom navigation bar.
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // The bottom navigation bar should have 4 items with expected labels.
    final bottomNav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bottomNav.items, hasLength(4));
    expect(bottomNav.items[0].label, 'Home');
    expect(bottomNav.items[1].label, 'Browse');
    expect(bottomNav.items[2].label, 'Favorites');
    expect(bottomNav.items[3].label, 'Profile');

    // The initial page should be the placeholder home page.
    expect(find.text('Home — Coming in Sprint 2+'), findsOneWidget);
  });
}
