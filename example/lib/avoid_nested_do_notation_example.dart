// ignore_for_file: unused_element, unused_local_variable

// avoid_nested_do_notation
//
// Each `Do` establishes its own extraction frame. A failure inside a nested
// block short-circuits only that block, so the outer pipeline carries on with
// a `None`/`Left` as an ordinary value instead of aborting.

import 'package:fpdart/fpdart.dart';

final _first = Option.of('a');
final _second = Option.of('b');

// ❌ Bad: the inner block short-circuits on its own
Option<String> badNested() =>
    // LINT: extract the inner block's steps in the outer block
    Option.Do(($) => $(Option.Do(($) => $(_first))));

// ❌ Bad: three levels, two of them wrong
Option<String> badDeeplyNested() => Option.Do(
  // LINT: extract the inner block's steps in the outer block
  ($) => $(Option.Do(($) => $(Option.Do(($) => $(_first))))),
);

// ✅ Good: one frame, every step extracted in it
Option<String> goodFlat() => Option.Do(($) {
  final first = $(_first);
  final second = $(_second);
  return '$first$second';
});

// ✅ Good: sibling blocks are unrelated to each other
Option<String> goodSiblingA() => Option.Do(($) => $(_first));

Option<String> goodSiblingB() => Option.Do(($) => $(_second));
