/// Utilities for computing string distance metrics.
///
/// These functions help measure similarity between strings, useful for
/// suggesting corrections or finding similar identifiers.
library;

/// Computes the Levenshtein edit distance between two strings.
///
/// The Levenshtein distance is the minimum number of single-character edits
/// (insertions, deletions, or substitutions) required to change one string
/// into another.
///
/// Returns:
/// - `0` if the strings are identical
/// - The length of the non-empty string if one string is empty
/// - The minimum number of edits needed otherwise
///
/// Example:
/// ```dart
/// computeEditDistance('kitten', 'sitting') // returns 3
/// computeEditDistance('hello', 'hello')    // returns 0
/// computeEditDistance('', 'abc')           // returns 3
/// ```
int computeEditDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List.generate(b.length + 1, (i) => i);
  var current = List.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [
        previous[j] + 1, // deletion
        current[j - 1] + 1, // insertion
        previous[j - 1] + cost, // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
    final temp = previous;
    previous = current;
    current = temp;
  }

  return previous[b.length];
}
