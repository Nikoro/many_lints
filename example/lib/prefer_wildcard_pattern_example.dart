// ignore_for_file: unused_local_variable, dead_code, unreachable_switch_case

// prefer_wildcard_pattern
//
// Warns when `Object()` is used as a pattern instead of the wildcard `_`.
// The wildcard pattern is clearer and more idiomatic for matching any value.

// ❌ Bad: Using Object() as a catch-all pattern
class BadExamples {
  String switchExpression(Object object) {
    return switch (object) {
      int() => 'int',
      // LINT: Use _ instead of Object()
      Object() => 'other',
    };
  }

  void switchStatement(Object object) {
    switch (object) {
      case int():
        break;
      // LINT: Use _ instead of Object()
      case Object():
        break;
    }
  }

  void ifCase(Object object) {
    // LINT: Use _ instead of Object()
    if (object case Object()) {}
  }
}

// ✅ Good: Using the wildcard pattern _
class GoodExamples {
  String switchExpression(Object object) {
    return switch (object) {
      int() => 'int',
      _ => 'other',
    };
  }

  void switchStatement(Object object) {
    switch (object) {
      case int():
        break;
      case _:
        break;
    }
  }

  // Object() with field destructuring is fine — it extracts values
  String objectPatternWithFields(Object object) {
    return switch (object) {
      int() => 'int',
      Object(hashCode: final h) => 'hash: $h',
      _ => 'other',
    };
  }
}
