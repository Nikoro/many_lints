// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_boolean_prefixes
// ignore_for_file: many_lints/function_always_returns_same_value

// prefer_returning_condition
//
// Warns when an if/return pair returns true and false, where the condition
// can be returned directly.

// ❌ Bad: the condition, spelled out as two branches
bool badEligible(int rating) {
  // LINT: this is `rating > 1200`
  if (rating > 1200) {
    return true;
  }
  return false;
}

// ✅ Good: the condition itself
bool goodEligible(int rating) => rating > 1200;

// ✅ Edge case: both branches returning the same literal is a different
// mistake, reported by function_always_returns_same_value.
bool goodDifferentRule(int rating) {
  if (rating > 1200) return true;
  return true;
}
