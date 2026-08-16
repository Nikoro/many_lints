// ignore_for_file: many_lints/avoid_long_parameter_list

// parameters_ordering
//
// Detects a function whose NAMED parameters are not in the configured order.
// Positional parameters are never ordered: every call site depends on them.
//
//   parameters_ordering:
//     order: alphabetical

// ❌ Bad: no order, so checking whether a parameter exists means reading all
class BadExample {
  // LINT: the parameter 'name' is out of order
  void configure({
    String? theme,
    required String name,
    int? timeout,
    required String id,
    bool? verbose,
  }) {}
}

// ✅ Good: required first as one group, then optional, each alphabetical
class GoodExample {
  void configure({
    required String id,
    required String name,
    String? theme,
    int? timeout,
    bool? verbose,
  }) {}
}

// Edge cases where the lint intentionally does NOT trigger
class EdgeCases {
  // Positional parameters are ordered by meaning and by their call sites.
  void positional(String zebra, String apple, String mango) {}

  // Below `min_parameters`, the whole signature is read at once.
  void short({String? zebra, String? apple}) {}
}
