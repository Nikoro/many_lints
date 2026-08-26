// ignore_for_file: unused_element, unused_local_variable

// prefer_do_notation
//
// `Do` is sugar over `flatMap` with identical semantics — same short-circuit,
// same order of effects. The difference is shape: nested callbacks indent one
// level per step, a Do block stays flat however many steps there are.

import 'package:fpdart/fpdart.dart';

final _banana = Option.of('banana');
final _apple = Option.of('apple');
final _pear = Option.of('pear');

// ❌ Bad: three levels deep, and the trailing brackets have to be counted
// LINT: use Do notation
Option<String> badNested() => _banana.flatMap(
  (banana) => _apple.flatMap(
    (apple) => _pear.flatMap((pear) => Option.of('$banana$apple$pear')),
  ),
);

// ✅ Good: flat, and each value is an ordinary local
Option<String> goodDoNotation() => Option.Do(($) {
  final banana = $(_banana);
  final apple = $(_apple);
  final pear = $(_pear);
  return '$banana, $apple, $pear';
});

// ✅ Good: chaining is already flat — only nesting grows sideways
Option<int> _length(String v) => Option.of(v.length);
Option<String> _label(int v) => Option.of('$v');

Option<int> goodChained() =>
    _banana.flatMap(_length).flatMap(_label).flatMap(_length);

// ✅ Good: two levels read fine, so this is not reported by default.
// Set `max_flat_map_depth: 2` to flag it too.
Option<String> goodTwoLevels() => _banana.flatMap(
  (banana) => _apple.flatMap((apple) => Option.of('$banana$apple')),
);
// ignore_for_file: many_lints/prefer_returning_shorthands
