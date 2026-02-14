// ignore_for_file: unused_local_variable

// avoid_commented_out_code
//
// Warns when commented-out code is found. Use version control to
// track old code instead of keeping it in comments.

// Bad: Commented-out function definition
class BadExamples {
  // LINT: This looks like commented-out code
  // void apply(String value) {
  //   print(value);
  // }

  // LINT: Commented-out variable declaration
  // final x = 42;

  // LINT: Commented-out import statement
  // import 'dart:async';

  void another() {}
}

// Good: Regular descriptive comments
class GoodExamples {
  // This method handles the main processing logic
  // and delegates to the appropriate handler

  // Temporarily disabled, enable in 1.0
  void another() {}
}
