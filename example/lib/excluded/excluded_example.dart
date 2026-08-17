// ignore_for_file: unused_catch_clause, unused_catch_stack

// Per-rule `exclude` demo.
//
// This file sits in `lib/excluded/`, which `many_lints.yaml` excludes for the
// `avoid_only_rethrow` rule:
//
//     rules:
//       avoid_only_rethrow:
//         exclude:
//           - lib/excluded/**
//
// The code below is the same redundant catch clause that
// `../avoid_only_rethrow_example.dart` reports three times — but here the rule
// is silent, because this path is excluded.
//
// Note what is *not* silenced: `avoid_commented_out_code` still reports the
// commented-out statement at the bottom. `exclude` is per rule, not per file,
// so every other rule keeps running here.

void bad() {
  // No lint: `avoid_only_rethrow` is excluded for this path.
  try {
    doSomething();
  } catch (e) {
    rethrow;
  }

  // No lint here either, for the same reason.
  try {
    doSomething();
  } on Exception {
    rethrow;
  }
}

class StillLinted {
  // LINT: avoid_commented_out_code still fires in this file.
  // final retries = 3;

  void another() {}
}

void doSomething() {}
// ignore_for_file: many_lints/avoid_commented_out_code
