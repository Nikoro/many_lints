enum OrderingMode {
  alphabetical,

  alphabeticalCaseSensitive,

  byLength;

  static OrderingMode parse(String? value) => switch (value) {
    'alphabetical_case_sensitive' => alphabeticalCaseSensitive,
    'by_length' => byLength,
    // Edge case: plugins cannot report on YAML files, so an unknown value falls back
    _ => alphabetical,
  };

  int compare(String a, String b) => switch (this) {
    alphabetical => a.toLowerCase().compareTo(b.toLowerCase()),
    alphabeticalCaseSensitive => a.compareTo(b),
    // Edge case: without the alphabetical tie-break, equal lengths would never converge
    byLength =>
      a.length != b.length
          ? a.length.compareTo(b.length)
          : a.toLowerCase().compareTo(b.toLowerCase()),
  };
}

int? firstUnorderedIndex(List<String> names, OrderingMode mode) {
  for (var i = 1; i < names.length; i++) {
    if (mode.compare(names[i - 1], names[i]) > 0) return i;
  }

  return null;
}
