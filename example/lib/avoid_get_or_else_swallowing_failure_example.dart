// ignore_for_file: unused_element, unused_local_variable, avoid_print

// avoid_get_or_else_swallowing_failure
//
// `Either.getOrElse` hands its callback the Left value. Ignoring it drops the
// reason the pipeline carried all the way to the boundary — sometimes right,
// but it should look like a decision rather than a shrug.

import 'package:fpdart/fpdart.dart';

// ❌ Bad: the failure is discarded without a word
int badWildcard(Either<String, int> result) =>
    // LINT: use the failure, or fold with match
    result.getOrElse((_) => 0);

// ❌ Bad: named and then ignored is the same discard
int badNamedButUnused(Either<String, int> result) =>
    // LINT: use the failure, or fold with match
    result.getOrElse((failure) => 0);

// ✅ Good: the failure informs the fallback
int goodUsesFailure(Either<String, int> result) =>
    result.getOrElse((failure) => failure.length);

// ✅ Good: folding puts the discard on the page, where a reader sees it
int goodExplicitFold(Either<String, int> result) => result.match((failure) {
  print('load failed: $failure');
  return 0;
}, (value) => value);

// ✅ Good: Option.getOrElse takes no parameter — nothing to discard
int goodOption(Option<int> option) => option.getOrElse(() => 0);
