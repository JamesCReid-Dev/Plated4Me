// Basic Flutter widget smoke test for Plated4Me.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plated4me/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: Plated4MeApp()));
    await tester.pump();

    // The app should render a bottom navigation bar with 4 items.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(BottomNavigationBarItem), findsNWidgets(4));
  });
}
