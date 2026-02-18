// ignore_for_file: unused_local_variable

// prefer_test_matchers
//
// Warns when the second argument of expect() or expectLater() is not a
// Matcher subclass. Using raw literals instead of matchers leads to
// less informative failure messages.

// NOTE: This rule checks the static type of the second argument.
// If it does not extend Matcher from package:matcher, a warning is reported.

// Simulated matcher hierarchy for demonstration:
abstract class Matcher {
  const Matcher();
}

class _Equals extends Matcher {
  final Object? expected;
  const _Equals(this.expected);
}

class _HasLength extends Matcher {
  final Object? expected;
  const _HasLength(this.expected);
}

class _IsA<T> extends Matcher {
  const _IsA();
}

class _IsNull extends Matcher {
  const _IsNull();
}

class _IsTrue extends Matcher {
  const _IsTrue();
}

const Matcher isNull = _IsNull();
const Matcher isTrue = _IsTrue();

Matcher equals(Object? expected) => _Equals(expected);
Matcher hasLength(Object? expected) => _HasLength(expected);
_IsA<T> isA<T>() => _IsA<T>();

void expect(dynamic actual, dynamic matcher) {}
void expectLater(dynamic actual, dynamic matcher) {}

// ❌ Bad: Using raw literals instead of matchers
void bad() {
  final array = [1, 2, 3];
  const value = 'hello';

  // LINT: Literal int instead of equals()
  expect(array.length, 1);

  // LINT: Literal string instead of equals()
  expect(value, 'hello');

  // LINT: Literal bool instead of isTrue
  expect(true, true);

  // LINT: Literal list instead of equals()
  expect(array, [1, 2, 3]);

  // LINT: null instead of isNull
  int? maybeNull;
  expect(maybeNull, null);

  // LINT: Also applies to expectLater
  expectLater(array.length, 1);
}

// ✅ Good: Using matchers for better failure messages
void good() {
  final array = [1, 2, 3];
  const value = 'hello';

  // Correct: Use hasLength() for length checks
  expect(array, hasLength(1));

  // Correct: Use equals() for value comparison
  expect(value, equals('hello'));

  // Correct: Use isTrue for boolean assertions
  expect(true, isTrue);

  // Correct: Use equals() for list comparison
  expect(array, equals([1, 2, 3]));

  // Correct: Use isNull for null checks
  int? maybeNull;
  expect(maybeNull, isNull);

  // Correct: Use isA<T>() for type checks
  expect(value, isA<String>());

  // Correct: expectLater with matcher
  expectLater(array, hasLength(3));
}
