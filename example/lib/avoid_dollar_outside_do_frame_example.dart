// ignore_for_file: unused_element, unused_local_variable

// avoid_dollar_outside_do_frame
//
// `$` short-circuits by throwing a marker the `Do` constructor catches. That
// only works inside the block's own frame — from a `map`/`flatMap` callback
// the marker unwinds through machinery that never expects it.

import 'package:fpdart/fpdart.dart';

final _first = Option.of('a');
final _second = Option.of('b');

// ❌ Bad: `$` called from inside a `map` callback
Option<String> badDollarInCallback() => Option.Do(
  // LINT: extract the value in the block itself, then use it in the callback
  ($) => optionOf($(_first)).map((value) => $(_second)).getOrElse(() => ''),
);

// ✅ Good: extract in the block, use the plain value in the callback
Option<String> goodExtractedFirst() => Option.Do(($) {
  final first = $(_first);
  final second = $(_second);
  return '$first$second';
});

// ✅ Good: a callback that does not call `$` at all is fine
Option<String> goodCallbackWithoutDollar() => Option.Do(($) {
  final value = $(_first);
  return optionOf(value).map((v) => v.toUpperCase()).getOrElse(() => '');
});

// ✅ Good: `$` used directly in the block's expression body
Option<String> goodExpressionBody() => Option.Do(($) => $(_first));
