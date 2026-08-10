// ignore_for_file: unused_element, unused_local_variable

// avoid_untyped_safe_cast
//
// `safeCast` decides its outcome with `value is R`. With no type arguments and
// no constraining context, `R` infers as `dynamic` — and every value satisfies
// `is dynamic`, so the cast can never fail. fpdart's own docs warn about this.

import 'package:fpdart/fpdart.dart';

// ❌ Bad: always Right, whatever `json` holds — the validation does nothing
void badEither(dynamic json) {
  // LINT: write the target type explicitly
  final result = Either.safeCast(json, (v) => 'not a map');
}

// ❌ Bad: always Some, for the same reason
void badOption(dynamic json) {
  // LINT: write the target type explicitly
  final result = Option.safeCast(json);
}

// ❌ Bad: the strict variant infers just as loosely
void badStrict(dynamic json) {
  // LINT: write the target type explicitly
  final result = Either.safeCastStrict(json, (v) => 'nope');
}

// ✅ Good: the target type is written on the call
void goodExplicit(dynamic json) {
  final result = Either<String, Map<String, dynamic>>.safeCast(
    json,
    (v) => 'not a map',
  );
}

// ✅ Good: same for Option
void goodExplicitOption(dynamic json) {
  final result = Option<int>.safeCast(json);
}

// ✅ Good: the return type constrains inference, so `R` is `int` and the cast
// really can fail — not reported
Either<String, int> goodFromReturnType(dynamic json) =>
    Either.safeCast(json, (v) => 'not an int');

// ✅ Good: a variable's annotation does the same job
void goodFromAnnotation(dynamic json) {
  final Either<String, int> result = Either.safeCast(json, (v) => 'nope');
}
