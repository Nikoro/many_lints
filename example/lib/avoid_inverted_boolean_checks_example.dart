// ignore_for_file: unused_element

// avoid_inverted_boolean_checks
//
// Warns when an integer comparison is negated instead of using the
// opposite operator.

// ❌ Bad: negated comparisons
bool badGreaterThan(int count, int limit) {
  // LINT: this is `count <= limit`
  return !(count > limit);
}

bool badLessThan(int a, int b) {
  // LINT: this is `a >= b`
  return !(a < b);
}

bool badGreaterOrEqual(int a, int b) {
  // LINT: this is `a < b`
  return !(a >= b);
}

// ✅ Good: use the opposite operator directly
bool goodDirect(int count, int limit) => count <= limit;

// ✅ Edge case: doubles are never reported, because NaN breaks the
// equivalence — !(nan > 1) is true while nan <= 1 is false
bool goodDoubles(double a, double b) => !(a > b);

// ✅ Edge case: a user-defined type may define > and <= independently, so
// the opposite operator is not guaranteed to be the negation
class _Version {
  bool operator >(_Version other) => true;
  bool operator <=(_Version other) => true;
}

bool goodCustomType(_Version a, _Version b) => !(a > b);

// ✅ Good: equality is handled by avoid_unnecessary_negations
bool goodEquality(int a, int b) => !(a == b);
