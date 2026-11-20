/// Extension on String to split into highlighted and plain spans for search results.
///
/// P4ME-18 — Full-Text Search.
/// AC-4: Matching text highlighted in results.

/// A segment of text that is either highlighted (matched) or plain.
class HighlightedSpan {
  final String text;
  final bool isMatch;

  const HighlightedSpan({required this.text, required this.isMatch});
}

/// Extension on [String] to produce highlighted spans for search matches.
extension HighlightExtension on String {
  /// Splits the string into highlighted and plain spans based on [query].
  List<HighlightedSpan> highlightMatches(String query) {
    if (query.trim().isEmpty) return [HighlightedSpan(text: this, isMatch: false)];

    final lowerText = toLowerCase();
    final lowerQuery = query.trim().toLowerCase();
    final spans = <HighlightedSpan>[];
    var lastIndex = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, lastIndex);
      if (index == -1) break;

      // Plain text before the match.
      if (index > lastIndex) {
        spans.add(HighlightedSpan(text: substring(lastIndex, index), isMatch: false));
      }

      // Highlighted match.
      spans.add(HighlightedSpan(
        text: substring(index, index + lowerQuery.length),
        isMatch: true,
      ));

      lastIndex = index + lowerQuery.length;
    }

    // Remaining plain text after the last match.
    if (lastIndex < length) {
      spans.add(HighlightedSpan(text: substring(lastIndex), isMatch: false));
    }

    // If no matches found, return the whole string as plain.
    if (spans.isEmpty) {
      return [HighlightedSpan(text: this, isMatch: false)];
    }

    return spans;
  }
}
