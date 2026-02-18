// ignore_for_file: unused_local_variable, unused_catch_clause

// avoid_only_rethrow
//
// Warns when a catch clause contains only a rethrow statement.
// Such catch clauses are redundant — they don't handle the exception.

// ❌ Bad: Catch clause only rethrows
void bad() {
  // LINT: Redundant catch clause
  try {
    doSomething();
  } catch (e) {
    rethrow;
  }

  // LINT: Same with typed on clause
  try {
    doSomething();
  } on Exception {
    rethrow;
  }

  // LINT: With stack trace parameter, still redundant
  try {
    doSomething();
  } catch (e, s) {
    rethrow;
  }
}

// ✅ Good: Catch clause has additional logic before rethrow
void good() {
  // Logging before rethrowing is meaningful
  try {
    doSomething();
  } catch (e) {
    print('Error: $e');
    rethrow;
  }

  // Conditional rethrow with handling
  try {
    doSomething();
  } catch (e) {
    if (e is FormatException) {
      handleFormat(e);
      return;
    }
    rethrow;
  }

  // No try-catch needed at all if you're just rethrowing
  doSomething();
}

void doSomething() {}
void handleFormat(Object e) {}
