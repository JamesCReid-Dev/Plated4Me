/// Search service implementing the 9-tier relevance ranking model (AD-9).
///
/// P4ME-18 — Full-Text Search.
/// Ranks [FilteredVisit] results by tier priority, then by creation date descending.
///
/// TIER MODEL:
///   1. Restaurant name exact match
///   2. Restaurant name partial match
///   3. Address match
///   4. Journal entry dish name match
///   5. Journal entry impressions match
///   6. Voice transcript match (not yet implemented — no field)
///   7. Employee name match
///   8. Occasion tag match
///   9. General notes match

import 'package:plated4me/application/providers/visit_list_filter_provider.dart';
import 'package:plated4me/domain/entities/entities.dart';

/// A text match found during search, with the matching field and highlighted content.
class MatchHighlight {
  /// The field category where the match was found (e.g., "restaurantName", "dishName").
  final String field;

  /// The matched text snippet from the source field.
  final String matchedText;

  /// The tier level (1–9) of this match.
  final int tier;

  const MatchHighlight({required this.field, required this.matchedText, required this.tier});
}

/// A single ranked search result with its relevance tier and match highlights.
class SearchResult {
  /// The filtered visit containing the matched data.
  final FilteredVisit visit;

  /// Convenience access to the associated restaurant.
  Restaurant get restaurant => visit.restaurant;

  /// Best (lowest number) tier among all matches for this visit.
  final int bestTier;

  /// All text matches found across all tiers, sorted by tier then field order.
  final List<MatchHighlight> matchHighlights;

  const SearchResult({required this.visit, required this.bestTier, required this.matchHighlights});
}

/// Service that ranks [FilteredVisit] results using the 9-tier relevance model (AD-9).
///
/// Performs case-insensitive substring matching across all searchable fields.
/// Returns visits sorted by tier priority (best first), then by creation date descending within the same tier.
class SearchService {
  /// Searches a list of [FilteredVisit] objects and returns ranked results.
  ///
  /// Implements the 9-tier relevance model:
  ///   Tier 1 — Restaurant name exact match
  ///   Tier 2 — Restaurant name partial match
  ///   Tier 3 — Address match
  ///   Tier 4 — Journal entry dish name match
  ///   Tier 5 — Journal entry impressions match
  ///   Tier 7 — Employee name match
  ///   Tier 8 — Occasion tag match
  ///   Tier 9 — General notes match
  ///
  /// Returns an empty list for empty/whitespace queries or when no matches are found.
  /// Search latency target: <200ms for full local dataset (NFR-6).
  List<SearchResult> search({
    required String query,
    required List<FilteredVisit> visits,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Split into tokens for multi-word queries (OR logic across tokens).
    final tokens = trimmed.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return [];

    final results = <SearchResult>[];

    for (final fv in visits) {
      final highlights = <MatchHighlight>[];
      var bestTier = 10; // Higher = worse, start beyond all tiers.

      for (final token in tokens) {
        // Tier 1: Restaurant name exact match
        if (_caseInsensitiveEquals(fv.restaurant.name, token)) {
          highlights.add(MatchHighlight(field: 'restaurantName', matchedText: fv.restaurant.name, tier: 1));
          bestTier = _updateBest(bestTier, 1);
        }
        // Tier 2: Restaurant name partial match
        else if (fv.restaurant.name.toLowerCase().contains(token)) {
          highlights.add(MatchHighlight(field: 'restaurantName', matchedText: _extractMatch(fv.restaurant.name, token), tier: 2));
          bestTier = _updateBest(bestTier, 2);
        }

        // Tier 3: Address match
        if (fv.restaurant.address != null && fv.restaurant.address!.toLowerCase().contains(token)) {
          highlights.add(MatchHighlight(field: 'address', matchedText: _extractMatch(fv.restaurant.address!, token), tier: 3));
          bestTier = _updateBest(bestTier, 3);
        }

        // Tier 4: Journal entry dish name match
        for (final entry in fv.visit.journalEntries) {
          final dishLower = entry.dishName.toLowerCase();
          if (dishLower.contains(token)) {
            highlights.add(MatchHighlight(field: 'dishName', matchedText: _extractMatch(entry.dishName, token), tier: 4));
            bestTier = _updateBest(bestTier, 4);
          }
        }

        // Tier 5: Journal entry impressions match
        for (final entry in fv.visit.journalEntries) {
          final impLower = entry.impressions.toLowerCase();
          if (impLower.contains(token)) {
            highlights.add(MatchHighlight(field: 'impressions', matchedText: _extractMatch(entry.impressions, token), tier: 5));
            bestTier = _updateBest(bestTier, 5);
          }
        }

        // Tier 7: Employee name match
        if (fv.visit.employeeName != null && fv.visit.employeeName!.toLowerCase().contains(token)) {
          highlights.add(MatchHighlight(field: 'employeeName', matchedText: _extractMatch(fv.visit.employeeName!, token), tier: 7));
          bestTier = _updateBest(bestTier, 7);
        }

        // Tier 8: Occasion tag match
        for (final occasion in fv.visit.occasions) {
          if (occasion.toLowerCase().contains(token)) {
            highlights.add(MatchHighlight(field: 'occasion', matchedText: _extractMatch(occasion, token), tier: 8));
            bestTier = _updateBest(bestTier, 8);
          }
        }

        // Tier 9: General notes match
        if (fv.visit.generalNotes != null && fv.visit.generalNotes!.toLowerCase().contains(token)) {
          highlights.add(MatchHighlight(field: 'generalNotes', matchedText: _extractMatch(fv.visit.generalNotes!, token), tier: 9));
          bestTier = _updateBest(bestTier, 9);
        }
      }

      if (highlights.isNotEmpty) {
        results.add(SearchResult(visit: fv, bestTier: bestTier, matchHighlights: highlights));
      }
    }

    // Sort by tier (best first), then by createdAt descending within same tier.
    results.sort((a, b) {
      final tierDiff = a.bestTier.compareTo(b.bestTier);
      if (tierDiff != 0) return tierDiff;
      final visitA = a.visit.visit;
      final visitB = b.visit.visit;
      return visitB.createdAt.compareTo(visitA.createdAt);
    });

    return results;
  }

  /// Case-insensitive equality check.
  bool _caseInsensitiveEquals(String a, String b) {
    return a.toLowerCase() == b.toLowerCase();
  }

  /// Returns the better (lower number) of two tier values.
  int _updateBest(int currentBest, int newTier) => newTier < currentBest ? newTier : currentBest;

  /// Extracts the matching substring from [text] for the given [lowerQuery].
  String _extractMatch(String text, String lowerQuery) {
    final lowerText = text.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);
    if (index == -1) return text;
    // Return the matched portion with surrounding context (up to 20 chars total).
    final start = index.clamp(0, text.length - 1);
    final end = (index + lowerQuery.length).clamp(0, text.length);
    var matched = text.substring(start, end);
    // Add ellipsis if truncated.
    if (start > 0) matched = '...$matched';
    if (end < text.length) matched = '$matched...';
    return matched;
  }
}
