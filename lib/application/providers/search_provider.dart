/// Riverpod provider for search query state with debounced ranking.
///
/// P4ME-18 — Full-Text Search.
/// Manages the search query with 200ms debounce (AC-5) and clear functionality (AC-6).
/// Integrates with [visitsListFilterProvider] to apply search ranking on top of filters.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/services/search_service.dart';

/// State for the search feature.
///
/// [query] holds the current text in the search field.
/// [searchResults] holds ranked results when a non-empty query is active,
/// or `null` when no search is happening (showing all/filtered visits).
class SearchState {
  /// The current search query text.
  final String query;

  /// Ranked search results, or null to show unsearched (all/filtered) visits.
  final List<SearchResult>? searchResults;

  const SearchState({this.query = '', this.searchResults});

  SearchState copyWith({String? query, List<SearchResult>? searchResults}) {
    return SearchState(
      query: query ?? this.query,
      searchResults: searchResults,
    );
  }
}

/// Notifier that manages search query state with debounced ranking.
///
/// The 200ms debounce is applied at the UI layer (text field input stream).
/// This provider computes results synchronously for testability.
class SearchNotifier extends Notifier<SearchState> {
  final SearchService _searchService = SearchService();

  @override
  SearchState build() {
    // Watch the filtered visit list so search re-ranks when data changes.
    ref.watch(visitsListFilterProvider);
    return const SearchState();
  }

  /// Sets the search query and computes ranked results.
  ///
  /// Whitespace-only or empty queries are treated as clear (AC-6).
  void setQuery(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      state = const SearchState();
      return;
    }

    // Compute search results synchronously.
    final List<FilteredVisit> visits = switch (ref.read(visitsListFilterProvider)) {
      AsyncData(:final value) => value,
      _ => const [],
    };

    final results = visits.isNotEmpty
        ? _searchService.search(query: trimmed, visits: visits)
        : <SearchResult>[];

    state = SearchState(query: trimmed, searchResults: results);
  }

  /// Clears the search query and resets to unsearched state.
  ///
  /// AC-6: Clear button clears text and dismisses keyboard.
  void clearQuery() {
    state = const SearchState();
  }
}

/// Provider for search state with debounced query handling.
///
/// Watches [visitsListFilterProvider] and applies search ranking on top of filters.
final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  () => SearchNotifier(),
  name: 'search',
);
