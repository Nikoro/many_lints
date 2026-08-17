// ignore_for_file: unused_local_variable
// ignore_for_file: many_lints/prefer_type_over_var

// use_existing_variable
//
// Warns when an expression duplicates the initializer of an existing
// final/const variable in the same scope. Helps avoid inconsistencies
// when only one of the repeated expressions is later updated.

// ❌ Bad: Repeating an expression that is already stored in a variable
void badPropertyAccess(String value) {
  final isOdd = value.length.isOdd;
  // LINT: The expression duplicates the initializer of 'isOdd'
  print(value.length.isOdd);
}

// ❌ Bad: Repeating a method call
void badMethodCall(List<int> list) {
  final copy = list.toList();
  // LINT: Use 'copy' instead
  print(list.toList());
}

// ❌ Bad: Multiple duplicates of the same variable
void badMultipleDuplicates(String value) {
  final len = value.length;
  // LINT: Two occurrences that should use 'len'
  print(value.length);
  print(value.length);
}

// ❌ Bad: Duplicate in a second variable initializer
void badSecondVariable(String value) {
  final a = value.length.isOdd;
  // LINT: Should be 'final b = a;'
  final b = value.length.isOdd;
  print(b);
}

// ✅ Good: Using the existing variable
void goodReuse(String value) {
  final isOdd = value.length.isOdd;
  print(isOdd);
}

// ✅ Good: No variable exists for the expression
void goodNoVariable(String value) {
  print(value.length.isOdd);
  print(value.length.isOdd);
}

// ✅ Good: Different expression (isEven vs isOdd)
void goodDifferentExpression(String value) {
  final isOdd = value.length.isOdd;
  print(value.length.isEven);
}

// ✅ Good: Non-final variable — value may have changed
void goodNonFinal(String value) {
  var isOdd = value.length.isOdd;
  print(value.length.isOdd);
  isOdd = false;
}

// ✅ Good: Expression appears before the variable declaration
void goodBeforeDeclaration(String value) {
  print(value.length.isOdd);
  final isOdd = value.length.isOdd;
  print(isOdd);
}

// ✅ Good: Inside a nested function (different execution context)
void goodNestedFunction(String value) {
  final isOdd = value.length.isOdd;
  void inner() {
    print(value.length.isOdd);
  }

  inner();
}

// ✅ Good: Trivial expressions (literals, identifiers) are not flagged
void goodTrivial() {
  final x = 42;
  print(42);
  final y = true;
  print(true);
}

class Database {
  Database(String file);
  Future<void> close() async {}
}

Future<int> fetchValue() async => 42;

// ✅ Good: Re-allocating a resource on purpose. Reusing 'old' would operate on
// a closed connection, so the duplication is not reported.
Future<void> goodReallocation(String file) async {
  final old = Database(file);
  await old.close();
  final upgraded = Database(file);
  print(upgraded);
}

// ✅ Good: Constructor calls allocate a fresh instance each time
void goodRepeatedConstruction() {
  final list = List<int>.filled(10, 0);
  print(List<int>.filled(10, 0));
}

// ✅ Good: Re-running async work is a separate operation
Future<void> goodRepeatedAwait() async {
  final first = await fetchValue();
  final second = await fetchValue();
  print(first + second);
}

// ✅ Good: Cascades build and mutate a distinct object each time
void goodRepeatedCascade() {
  final list = []..add(1);
  print([]..add(1));
}
// ignore_for_file: many_lints/prefer_declaring_const_constructor
// ignore_for_file: many_lints/prefer_moving_to_variable
