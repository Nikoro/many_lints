// ignore_for_file: unused_local_variable

// avoid_misused_test_matchers
//
// Warns when test matchers are used with incompatible actual value types
// in expect() calls. Misused matchers can cause tests to always pass
// (hiding bugs) or always fail (redundant checks).

// NOTE: This rule detects expect() calls by method name, so it works
// with any package that provides an expect() function and matchers
// named isNull, isEmpty, isList, isMap, hasLength, etc.

void expect(dynamic actual, dynamic matcher) {}

const isNull = 1;
const isNotNull = 2;
const isEmpty = 3;
const isNotEmpty = 4;
const isList = 5;
const isMap = 6;
const isZero = 7;
const isNaN = 8;
const isPositive = 9;
const isNegative = 10;
const isTrue = 11;
const isFalse = 12;

int hasLength(dynamic expected) => 0;

// ❌ Bad: Matchers used with incompatible types
void bad() {
  const someNumber = 1;
  const someString = '1';

  // LINT: String is not a List
  expect(someString, isList);

  // LINT: Set is not a List
  expect({1}, isList);

  // LINT: int has no isEmpty property
  expect(someNumber, isEmpty);

  // LINT: int cannot be null (non-nullable type)
  expect(someNumber, isNull);

  // LINT: int is always not-null (redundant check)
  expect(someNumber, isNotNull);

  // LINT: int has no length property
  expect(someNumber, hasLength(1));

  // LINT: String is not a num
  expect(someString, isZero);

  // LINT: int is not a bool
  expect(someNumber, isTrue);

  // LINT: String is not a Map
  expect(someString, isMap);

  // LINT: String has no isEmpty (wait, String does have isEmpty)
  // This would NOT lint — String has isEmpty.

  // LINT: bool is not a num
  expect(true, isNegative);

  // LINT: int is not a bool
  expect(42, isFalse);
}

// ✅ Good: Matchers used with compatible types
void good() {
  const someNumber = 1;
  const someList = [1, 2, 3];
  const someString = 'hello';
  int? nullableValue;

  // Correct type matchers
  expect(someList, isList);
  expect(<String, int>{}, isMap);

  // Correct nullability matchers
  expect(nullableValue, isNull);
  expect(nullableValue, isNotNull);

  // Correct emptiness matchers
  expect(someList, isEmpty);
  expect(someString, isEmpty);
  expect(<String, int>{}, isNotEmpty);

  // Correct length matchers
  expect(someList, hasLength(3));
  expect(someString, hasLength(5));

  // Correct numeric matchers
  expect(someNumber, isZero);
  expect(0.0, isNaN);
  expect(5, isPositive);
  expect(-1, isNegative);

  // Correct boolean matchers
  expect(true, isTrue);
  expect(false, isFalse);
}
