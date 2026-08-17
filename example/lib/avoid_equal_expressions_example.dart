// ignore_for_file: unused_element, unused_local_variable

// avoid_equal_expressions
//
// Warns when both operands of a binary expression are identical. These are
// typos with a constant result: one side was meant to be a different
// variable, field, or index.

class _Point {
  const _Point(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    if (other is! _Point) return false;
    // LINT: `y == y` is always true — `other.y` was meant
    return x == other.x && y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

// ❌ Bad: self-comparison
bool badEquality(int a) {
  // LINT: always true
  return a == a;
}

// ❌ Bad: redundant conjunction
bool badConjunction(bool flag) {
  // LINT: the guard does nothing
  return flag && flag;
}

// ❌ Bad: comparison that cannot vary
bool badComparison(int a) {
  // LINT: always false
  return a < a;
}

// ❌ Bad: arithmetic that is always zero
int badSubtraction(int a) {
  // LINT: always 0
  return a - a;
}

// ✅ Good: distinct operands
bool goodEquality(_Point p, _Point q) => p.x == q.x;

// ✅ Good: `a + a` and `a * a` are ordinary arithmetic
int goodDouble(int a) => a + a;

int goodSquare(int a) => a * a;

// ✅ Edge case: the canonical NaN test
bool goodNanCheck(double value) => value != value;

// ✅ Edge case: method calls may return different values each time
class _Generator {
  int next() => 0;
}

bool goodMethodCalls(_Generator g) => g.next() == g.next();

// ✅ Edge case: different indices
bool goodDifferentIndices(List<int> items) => items[0] == items[1];
// ignore_for_file: many_lints/prefer_boolean_prefixes
// ignore_for_file: many_lints/prefer_getter_over_method
