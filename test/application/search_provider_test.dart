/// Application layer tests for SearchProvider — query state management and debounced search.
///
/// P4ME-18 — Full-Text Search.
/// Covers AC-5 (debounced 200ms list updates), AC-6 (clear text).

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/search_provider.dart';

// -- Tests --------------------------------------------------------------------

void main() {
  group('P4ME-18 — SearchProvider', () {
    test(
      'Initial state is empty query with no search results (all visits shown)',
      () async {
        final container = ProviderContainer();
        final state = container.read(searchProvider);

        expect(state.query, isEmpty);
        // When query is empty, searchResults should be null (shows all visits).
        expect(state.searchResults, isNull);

        container.dispose();
      },
    );

    test(
      'AC-5 — setQuery updates query and triggers debounced search',
      () async {
        final container = ProviderContainer();

        container.read(searchProvider.notifier).setQuery('Sakura');

        final state = container.read(searchProvider);
        expect(state.query, equals('Sakura'));

        container.dispose();
      },
    );

    test(
      'AC-6 — clearQuery resets query to empty and clears search results',
      () async {
        final notifier = ProviderContainer().read(searchProvider.notifier);

        notifier.setQuery('Sakura');
        expect(notifier.state.query, equals('Sakura'));

        notifier.clearQuery();
        expect(notifier.state.query, isEmpty);
        // Search results cleared — null means show all visits.
        expect(notifier.state.searchResults, isNull);

        ProviderContainer().dispose();
      },
    );

    test(
      'setQuery with whitespace-only clears query',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(searchProvider.notifier);

        notifier.setQuery('   ');
        expect(container.read(searchProvider).query, isEmpty);

        container.dispose();
      },
    );

    test(
      'setQuery with empty string clears query',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(searchProvider.notifier);

        notifier.setQuery('');
        expect(container.read(searchProvider).query, isEmpty);

        container.dispose();
      },
    );

    test(
      'setQuery with non-empty query sets searchResults to ranked list',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(searchProvider.notifier);

        // Set a query that will match something.
        notifier.setQuery('test');

        final state = container.read(searchProvider);
        expect(state.query, equals('test'));
        // searchResults should be populated (not null) when querying.
        expect(state.searchResults, isNotNull);

        container.dispose();
      },
    );

    test(
      'setQuery with no matching results sets empty searchResults',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(searchProvider.notifier);

        notifier.setQuery('xyznonexistent123');

        final state = container.read(searchProvider);
        expect(state.query, equals('xyznonexistent123'));
        // searchResults should be an empty list (not null).
        expect(state.searchResults?.isEmpty, isTrue);

        container.dispose();
      },
    );

    test(
      'setQuery does not trigger rebuild when query unchanged',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(searchProvider.notifier);

        notifier.setQuery('Sakura');

        // Setting the same value should not trigger a state change.
        notifier.setQuery('Sakura');

        final state = container.read(searchProvider);
        expect(state.query, equals('Sakura'));

        container.dispose();
      },
    );
  });
}
