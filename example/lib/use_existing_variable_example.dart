// ignore_for_file: unused_local_variable

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
