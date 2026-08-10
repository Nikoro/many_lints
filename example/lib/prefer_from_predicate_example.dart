// ignore_for_file: unused_element, unused_local_variable

// prefer_from_predicate
//
// `Option.fromPredicate(value, test)` says what the conditional means: this
// value, if it passes this test. The conditional also names the value twice,
// and a version that tests one variable but wraps another still compiles.

import 'package:fpdart/fpdart.dart';

// ❌ Bad: a predicate written the long way
// LINT: use Option.fromPredicate
Option<int> badAge(int age) => age > 18 ? Option.of(age) : Option<int>.none();

// ❌ Bad: same shape with a method-call condition
// LINT: use Option.fromPredicate
Option<String> badName(String name) =>
    name.isNotEmpty ? Option.of(name) : Option<String>.none();

// ✅ Good: the predicate reads as a test on the value
Option<int> goodAge(int age) => Option.fromPredicate(age, (a) => a > 18);

// ✅ Good: Either when the rejected case carries a failure
Either<String, int> goodEither(int age) =>
    Either.fromPredicate(age, (a) => a > 18, (a) => 'too young: $a');

// ✅ Good: a null test belongs to prefer_from_nullable, whose fix is better
// suited to that shape
Option<String> goodNullTest(String? name) =>
    name != null ? Option.of(name) : Option<String>.none();

// ✅ Good: two clauses read fine as a conditional, so this is not reported by
// default. Raise `max_condition_complexity` to flag it too.
Option<int> goodComplexCondition(int age) =>
    age > 18 && age < 65 ? Option.of(age) : Option<int>.none();

// ✅ Good: the condition tests something else entirely, so this is not a
// predicate on the wrapped value
Option<int> goodUnrelatedCondition(int age, bool enabled) =>
    enabled ? Option.of(age) : Option<int>.none();
