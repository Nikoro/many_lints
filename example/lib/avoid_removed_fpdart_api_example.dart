// ignore_for_file: unused_element, unused_local_variable, undefined_identifier
// ignore_for_file: undefined_function, undefined_class

// avoid_removed_fpdart_api
//
// These names were removed in fpdart 1.0.0, so they do not compile against a
// 1.x fpdart. The rule exists for the message: "undefined name Tuple2" says
// something is wrong, "use a Dart record" says what to do.

import 'package:fpdart/fpdart.dart';

bool _isEven(int n) => n % 2 == 0;

// ❌ Bad: removed in 1.0.0 — Dart records replaced it
Option<int> badTuple() {
  // LINT: use a Dart record, (a, b)
  final pair = Tuple2(1, 'a');
  return Option.of(1);
}

// ❌ Bad: the Predicate class became extensions on functions
Option<int> badPredicate() {
  // LINT: use the function extensions
  final p = Predicate;
  return Option.of(1);
}

// ✅ Good: a Dart record
(int, String) goodRecord() => (1, 'a');

// ✅ Good: the function extensions that replaced Predicate
bool Function(int) goodNegate() => _isEven.negate;

// ✅ Good: current 1.x API throughout
Option<int> goodCurrent(String input) => input.toIntOption;

// Note: `bind` and `concat` still exist in 1.x but changed meaning since 0.x,
// so they are not reported by default. Add them via `additional_removed` when
// migrating a 0.x codebase.
