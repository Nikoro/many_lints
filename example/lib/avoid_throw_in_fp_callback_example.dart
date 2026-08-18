// ignore_for_file: unused_element, unused_local_variable
// These examples throw bare `Exception` incidentally, to keep the focus on the
// rule this file demonstrates.
// ignore_for_file: many_lints/prefer_typed_exceptions

// avoid_throw_in_fp_callback
//
// fpdart carries failure in the value — the `Left` of an `Either`, the `None`
// of an `Option`. A `throw` inside a callback leaves that channel, so a caller
// that folds every failure still crashes.

import 'package:fpdart/fpdart.dart';

final _option = Option.of('test');

// ❌ Bad: the exception escapes the pipeline entirely
Option<String> badThrowInDo() => Option.Do(($) {
  if ($(_option) == 'test') {
    // LINT: return a failure in the error channel instead
    throw Exception('Error');
  }
  return 'success';
});

// ❌ Bad: same inside a `map` callback
Option<int> badThrowInMap(Option<int> value) => value.map((v) {
  if (v < 0) {
    // LINT: return a failure in the error channel instead
    throw Exception('negative');
  }
  return v;
});

// ✅ Good: the failure travels in the value, so the caller's fold sees it
Option<String> goodShortCircuit() => Option.Do(($) {
  final value = $(_option);
  return $(value == 'test' ? Option<String>.none() : Option.of('success'));
});

// ✅ Good: map a thrown error into the left channel once, at the boundary
TaskEither<String, int> goodTryCatch(Future<int> Function() load) =>
    TaskEither.tryCatch(load, (error, stackTrace) => error.toString());

// ✅ Good: an unreachable branch is a programmer error, not a domain outcome,
// so these are allowed by default
Option<int> goodUnimplemented(Option<int> value) =>
    value.map((v) => throw UnimplementedError());

// ✅ Good: a throw in an Iterable.map callback is ordinary Dart
List<int> goodPlainDart(List<int> values) => values.map((v) {
  if (v < 0) throw Exception('negative');
  return v;
}).toList();
// ignore_for_file: many_lints/prefer_for_loop_in_children
// ignore_for_file: many_lints/prefer_returning_shorthands
