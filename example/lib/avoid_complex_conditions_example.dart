// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_boolean_prefixes

// avoid_complex_conditions
//
// Warns when a condition combines more && / || operands than the budget.

// ❌ Bad: four facts and two precedence rules at once
// LINT: combines 4 operands, over the limit of 3
bool badEligible(bool isActive, bool hasPaid, bool isBanned, bool isAdult) =>
    isActive && hasPaid && !isBanned && isAdult;

// ✅ Good: each piece can be read and debugged on its own
bool goodEligible(bool isActive, bool hasPaid, bool isBanned, bool isAdult) {
  final isInGoodStanding = isActive && hasPaid;
  final isPermitted = !isBanned && isAdult;
  return isInGoodStanding && isPermitted;
}

// ✅ Edge case: a hand-written `operator ==` is one `&&` per field by
// construction; splitting it would scatter a check that reads as a unit.
class Point {
  const Point(this.x, this.y, this.z, this.w);

  final int x;
  final int y;
  final int z;
  final int w;

  @override
  bool operator ==(Object other) =>
      other is Point &&
      other.x == x &&
      other.y == y &&
      other.z == z &&
      other.w == w;

  @override
  int get hashCode => 0;
}
