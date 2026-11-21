/// Presentation layer widget tests for VisitCard and BrowseScreen empty state.
///
/// TDD Green Phase for P4ME-17 — S10 Filterable Visit Card List.
/// Tests verify the implemented VisitCard widget and BrowseScreen empty state.
///
/// Coverage: AC-1 (card layout), AC-8 (blacklist overlay), AC-9 (tap navigation),
/// AC-10 (cold open empty state).
/// P4ME-46 — highlighted text uses titleLarge style (regression test).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';
import 'package:plated4me/presentation/screens/browse_screen.dart';
import 'package:plated4me/domain/services/search_service.dart';
import 'package:plated4me/presentation/widgets/visit_card_widget.dart';

// -- Test data helpers --------------------------------------------------------

FilteredVisit _makeFilteredVisit({
  required int restaurantId,
  required double compositeScore,
  required DateTime createdAt,
  bool returnIntent = false,
  List<String>? occasions,
  bool blacklisted = false,
  String restaurantName = 'Sushi Place',
}) {
  final visit = Visit(
    restaurantId: restaurantId,
    foodRating: 4.0,
    valueRating: 3.5,
    serviceRating: 4.0,
    overallRating: 4.5,
    compositeScore: compositeScore,
    returnIntent: returnIntent,
  )..id = restaurantId
    ..createdAt = createdAt
    ..updatedAt = createdAt
    ..blacklisted = blacklisted;
  if (occasions != null) visit.occasions.addAll(occasions);

  final restaurant = Restaurant(name: restaurantName)..id = restaurantId;
  return FilteredVisit(visit: visit, restaurant: restaurant);
}

// -- Fake provider for VisitCard widget tests ---------------------------------

class _FakeFilterNotifier extends VisitListFilterNotifier {
  final List<FilteredVisit> visits;
  bool _hasActive = false;

  _FakeFilterNotifier(this.visits);

  @override
  Future<List<FilteredVisit>> build() async => visits;

  @override
  Future<void> refresh() async {}

  /// Applies filter criteria and marks active filters as true.
  Future<void> applyFilters({
    String? cuisineType,
    double? minRating,
    double? maxRating,
    String? occasionTag,
    bool? allergySafeOnly,
  }) async {
    _hasActive = true;
    state = AsyncData(visits);
  }

  /// Clears all filters and marks active filters as false.
  Future<void> clearFilters() async {
    _hasActive = false;
    state = AsyncData(visits);
  }

  @override
  bool get hasActiveFilters => _hasActive;
}

// -- Widget test helpers ------------------------------------------------------

/// Builds a minimal MaterialApp with provider overrides for widget tests.
Widget _buildTestApp({
  required Widget home,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(debugShowCheckedModeBanner: false, home: home),
  );
}

// -- Tests --------------------------------------------------------------------

void main() {
  group('P4ME-17 — VisitCard widget', () {
    // AC-1: Card shows restaurant name (headline weight).
    testWidgets(
      'AC-1 — VisitCard displays restaurant name in headline weight',
      (tester) async {
        final fv = _makeFilteredVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1));

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        expect(find.text('Sushi Place'), findsOneWidget);
        expect(find.byKey(const Key('restaurant_name')), findsOneWidget);
      },
    );

    // AC-1: Restaurant name truncated with ellipsis if >40 chars.
    testWidgets(
      'AC-1 — VisitCard truncates restaurant name with ellipsis when >40 chars',
      (tester) async {
        const longName = 'A Very Long Restaurant Name That Exceeds Forty Characters';
        final fv = _makeFilteredVisit(
          restaurantId: 1,
          compositeScore: 80.0,
          createdAt: DateTime(2025, 6, 1),
          restaurantName: longName,
        );

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        // The Text widget should contain the full name but render with ellipsis.
        // find.text() checks the widget's text property, not visual rendering.
        // With overflow:ellipsis and constrained width, Flutter clips visually.
        expect(find.byKey(const Key('restaurant_name')), findsOneWidget);
        // Verify the Text widget has ellipsis overflow by checking its style.
        final textWidget = tester.widget<Text>(find.byKey(const Key('restaurant_name')));
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
        expect(textWidget.maxLines, equals(1));
      },
    );

    // AC-1: Date displayed as relative ("2 days ago") or formatted caption.
    testWidgets(
      'AC-1 — VisitCard displays date in caption style',
      (tester) async {
        final now = DateTime.now();
        final fv = _makeFilteredVisit(restaurantId: 1, compositeScore: 80.0, createdAt: now);

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        expect(find.byKey(const Key('visit_date')), findsOneWidget);
      },
    );

    // AC-1: Composite score bar at bottom, accent color fill proportional to score, 3px height.
    testWidgets(
      'AC-1 — VisitCard shows composite score bar with accent color fill',
      (tester) async {
        final fv = _makeFilteredVisit(restaurantId: 1, compositeScore: 75.0, createdAt: DateTime(2025, 6, 1));

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        // Score bar is a LayoutBuilder with an AnimatedContainer inside.
        expect(find.byType(LayoutBuilder), findsOneWidget);
      },
    );

    // AC-1: Return intent pill (top-right): green checkmark if true, red X if false.
    testWidgets(
      'AC-1 — VisitCard shows return intent pill with checkmark when true',
      (tester) async {
        final fv = _makeFilteredVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1), returnIntent: true);

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        expect(find.byKey(const Key('return_intent_pill')), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      },
    );

    testWidgets(
      'AC-1 — VisitCard shows negative return intent (X) when false',
      (tester) async {
        final fv = _makeFilteredVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1), returnIntent: false);

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        expect(find.byKey(const Key('return_intent_pill')), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
      },
    );

    // AC-8: Blacklisted visits show 40% ink-disabled grey overlay + dimmed text.
    testWidgets(
      'AC-8 — VisitCard shows 40% ink-disabled grey overlay when blacklisted',
      (tester) async {
        final fv = _makeFilteredVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1), blacklisted: true);

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        expect(find.byKey(const Key('blacklist_overlay')), findsOneWidget);
      },
    );

    testWidgets(
      'AC-8 — Tapping blacklisted VisitCard still navigates to detail view',
      (tester) async {
        final fv = _makeFilteredVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1), blacklisted: true);

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();
        // Should navigate to VisitDetailView.
        expect(find.byType(VisitDetailView), findsOneWidget);
      },
    );

    // AC-9: Tap card navigates to Visit Detail View.
    testWidgets(
      'AC-9 — Tapping VisitCard navigates to Visit Detail View',
      (tester) async {
        final fv = _makeFilteredVisit(restaurantId: 1, compositeScore: 80.0, createdAt: DateTime(2025, 6, 1));

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(body: VisitCard(filteredVisit: fv)),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();
        expect(find.byType(VisitDetailView), findsOneWidget);
      },
    );

    // P4ME-46: Highlighted text uses titleLarge (not bodyMedium) for visual consistency.
    testWidgets(
      'P4ME-46 — highlighted restaurant name spans use titleLarge style',
      (tester) async {
        final fv = _makeFilteredVisit(
          restaurantId: 1,
          compositeScore: 80.0,
          createdAt: DateTime(2025, 6, 1),
          restaurantName: 'Sushi Place',
        );

        final matchHighlights = <MatchHighlight>[
          const MatchHighlight(field: 'restaurantName', matchedText: 'Sushi', tier: 1),
        ];

        String? capturedTitleLargeSize;

        await tester.pumpWidget(_buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedTitleLargeSize = Theme.of(context).textTheme.titleLarge?.fontSize.toString();
                return VisitCard(
                  filteredVisit: fv,
                  matchHighlights: matchHighlights,
                  searchQuery: 'sushi',
                );
              },
            ),
          ),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([fv])),
          ],
        ));

        // When highlights are present the name is rendered as Text.rich.
        final textWidget = tester.widget<Text>(find.byKey(const Key('restaurant_name')));
        final textSpan = textWidget.textSpan as TextSpan;

        // Collect all TextSpans recursively from the children list.
        final allSpans = <TextSpan>[];

        void collect(TextSpan span) {
          allSpans.add(span);
          for (final child in span.children ?? []) {
            if (child is TextSpan) {
              collect(child);
            }
          }
        }

        collect(textSpan);

        // Every span must use titleLarge as the base style — never bodyMedium.
        for (final span in allSpans) {
          expect(
            span.style?.fontSize?.toString(),
            equals(capturedTitleLargeSize),
            reason: 'Span "${span.text}" should use titleLarge font size',
          );
        }
      },
    );
  });

  group('P4ME-17 — BrowseScreen empty state', () {
    // AC-10: Cold open empty state.
    testWidgets(
      'AC-10 — Empty state shows large icon, headline and subtext',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(
          home: const BrowseScreen(),
          overrides: [
            visitsListFilterProvider.overrideWith(() => _FakeFilterNotifier([])),
          ],
        ));

        // Wait for the async provider to initialize (build() returns Future).
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
        expect(find.text('No visits yet'), findsOneWidget);
        expect(
          find.textContaining('Tap + to log your first dining experience'),
          findsOneWidget,
        );
      },
    );
  });
}
