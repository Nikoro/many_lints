// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_shorthands_with_enums

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

// ❌ Bad: negating a boolean literal
// LINT: !true is just false
bool badNegatedLiteral() => !true;

// ❌ Bad: negations on both sides of a comparison cancel out
// LINT: drop both negations
bool badNegationsAroundEquality(bool a, bool b) => !a == !b;

// ❌ Bad: same for inequality
// LINT: drop both negations
bool badNegationsAroundInequality(bool a, bool b) => !a != !b;

// ✅ Good: the comparison without either negation
bool goodComparison(bool a, bool b) => a == b;

// ✅ Good: a single negation changes the result, so it stays
bool goodSingleNegationInComparison(bool a, bool b) => !a == b;
// ignore_for_file: many_lints/prefer_boolean_prefixes
