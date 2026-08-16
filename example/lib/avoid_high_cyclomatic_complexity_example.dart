// ignore_for_file: unused_local_variable, avoid_print
// ignore_for_file: many_lints/avoid_complex_conditions
// ignore_for_file: many_lints/prefer_early_return
// ignore_for_file: many_lints/prefer_type_over_var
// ignore_for_file: many_lints/member_ordering
// ignore_for_file: many_lints/avoid_long_parameter_list
// ignore_for_file: many_lints/prefer_shorthands_with_enums
// ignore_for_file: many_lints/prefer_returning_shorthands

// avoid_high_cyclomatic_complexity
//
// Detects a function with more independent paths through it than the
// configured budget. Every branch, loop, catch, &&, ||, ?: and ?? adds one.

enum Status { draft, review, published, archived }

// ❌ Bad: eleven decisions interleaved in one function
class BadExamples {
  // LINT: a cyclomatic complexity of 12, over the limit of 10
  String describe(int n, bool flag, String? label) {
    if (n < 0) return 'negative';
    if (n == 0) return 'zero';
    if (n > 100 && flag) return 'large and flagged';
    if (n > 100 || flag) return 'large or flagged';
    if (label != null && label.isNotEmpty) return label;

    for (var i = 0; i < n; i++) {
      if (i % 2 == 0) print(i);
    }

    try {
      print(n);
    } on FormatException {
      return 'bad format';
    }

    return label ?? 'unknown';
  }
}

// ✅ Good: each decision lives in a function that names it
class GoodExamples {
  String describe(int n, bool flag, String? label) {
    if (_isSpecialCase(n)) return _specialCase(n);

    return label ?? 'unknown';
  }

  bool _isSpecialCase(int n) => n <= 0 || n > 100;

  String _specialCase(int n) => n <= 0 ? 'small' : 'large';
}

// Edge cases where the lint intentionally does NOT trigger
class EdgeCases {
  final int a, b, c, d, e, f, g, h, i, j, k, l;

  const EdgeCases(
    this.a,
    this.b,
    this.c,
    this.d,
    this.e,
    this.f,
    this.g,
    this.h,
    this.i,
    this.j,
    this.k,
    this.l,
  );

  // An exhaustive switch over an enum is one decision, not four: the compiler
  // proves every case is handled, so they are not paths a reader must check.
  String label(Status status) => switch (status) {
    Status.draft => 'Draft',
    Status.review => 'In review',
    Status.published => 'Published',
    Status.archived => 'Archived',
  };

  // `==` is one `&&` per field by construction, and cannot be split.
  @override
  bool operator ==(Object other) =>
      other is EdgeCases &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.d == d &&
      other.e == e &&
      other.f == f &&
      other.g == g &&
      other.h == h &&
      other.i == i &&
      other.j == j &&
      other.k == k &&
      other.l == l;

  @override
  int get hashCode => Object.hashAll([a, b, c, d, e, f, g, h, i, j, k, l]);

  // `copyWith` is one `??` per parameter, for the same reason.
  EdgeCases copyWith({
    int? a,
    int? b,
    int? c,
    int? d,
    int? e,
    int? f,
    int? g,
    int? h,
    int? i,
    int? j,
    int? k,
    int? l,
  }) => EdgeCases(
    a ?? this.a,
    b ?? this.b,
    c ?? this.c,
    d ?? this.d,
    e ?? this.e,
    f ?? this.f,
    g ?? this.g,
    h ?? this.h,
    i ?? this.i,
    j ?? this.j,
    k ?? this.k,
    l ?? this.l,
  );
}
