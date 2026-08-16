/// Shared machinery for the ordering rules — `arguments_ordering`,
/// `enum_constants_ordering`, `map_keys_ordering` and their siblings.
///
/// Each of those rules reduces to the same question: given a list of names in
/// source order, is it sorted the way the project asked for? Keeping the
/// comparison here means the seven rules differ only in how they *find* the
/// names, and that a fix to the sort applies to all of them at once.
library;

/// How a list of names should be sorted.
enum OrderingMode {
  /// Case-insensitive alphabetical, which is what a reader scanning for a name
  /// expects. Case-sensitive sorting puts every capitalised name in a block
  /// before the lowercase ones, which reads as two lists rather than one.
  alphabetical,

  /// Alphabetical, but comparing the raw strings, so `Z` precedes `a`.
  alphabeticalCaseSensitive,

  /// Longest name last. Purely visual, but it is a real house style for
  /// argument lists and enum bodies.
  byLength;

  static OrderingMode parse(String? value) => switch (value) {
    'alphabetical_case_sensitive' => alphabeticalCaseSensitive,
    'by_length' => byLength,
    // An unrecognised value falls back rather than throwing, for the same
    // reason every other malformed option does: a plugin cannot report a
    // diagnostic against a YAML file.
    _ => alphabetical,
  };

  int compare(String a, String b) => switch (this) {
    alphabetical => a.toLowerCase().compareTo(b.toLowerCase()),
    alphabeticalCaseSensitive => a.compareTo(b),
    // Ties fall back to alphabetical so the order is total: without it, two
    // names of equal length would compare as "already sorted" in either
    // arrangement and the rule could never converge.
    byLength =>
      a.length != b.length
          ? a.length.compareTo(b.length)
          : a.toLowerCase().compareTo(b.toLowerCase()),
  };
}

/// The first entry in [names] that appears before an entry it should follow,
/// or `null` when the list is already ordered.
///
/// Returns the *first* out-of-order entry rather than every one, because a
/// single misplaced name makes every later name look wrong too — reporting
/// them all would turn one edit into a wall of diagnostics.
int? firstUnorderedIndex(List<String> names, OrderingMode mode) {
  for (var i = 1; i < names.length; i++) {
    if (mode.compare(names[i - 1], names[i]) > 0) return i;
  }

  return null;
}
