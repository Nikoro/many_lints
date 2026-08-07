// ignore_for_file: unused_element

// avoid_unnecessary_negations
//
// Warns when a negation cancels another negation. The reader has to unwind
// both operators before knowing what is actually being tested.

enum Status { active, inactive }

// ❌ Bad: double negation
bool badDoubleNegation(bool isEnabled) {
  // LINT: this is just `isEnabled`
  return !!isEnabled;
}

// ❌ Bad: negated inequality
bool badNegatedInequality(Status status) {
  // LINT: this is `status == Status.active`
  return !(status != Status.active);
}

// ❌ Bad: parentheses do not change anything
bool badParenthesised(bool flag) {
  // LINT: still a double negation
  return !(!flag);
}

// ✅ Good: state the condition directly
bool goodDirect(bool isEnabled) => isEnabled;

bool goodEquality(Status status) => status == Status.active;

// ✅ Good: a single negation is fine
bool goodSingleNegation(bool flag) => !flag;

// ✅ Good: negated equality is a style choice, not a redundancy
bool goodNegatedEquality(int a, int b) => !(a == b);

// ✅ Good: negating a conjunction is meaningful
bool goodNegatedConjunction(bool a, bool b) => !(a && b);

// ✅ Edge case: negating a property read
bool goodNegatedProperty(List<int> items) => !items.isEmpty;
