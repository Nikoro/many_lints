// ignore_for_file: unused_local_variable

// avoid_inconsistent_digit_separators
//
// Detects numeric literals whose `_` separators split them into irregularly
// sized groups.

// ❌ Bad: groups the eye cannot count
void badExamples() {
  // LINT: groups of 2-2-3, which reads as a different convention entirely
  const population = 10_00_000;

  // LINT: the leading group is longer than the rest
  const bytes = 1000_000;

  // LINT: a hex literal grouped by threes rather than by half-words
  const mask = 0xFF_FFF_FFF;
}

// ✅ Good: one group size, used consistently
void goodExamples() {
  const population = 1_000_000;
  const bytes = 1_000_000;
  const mask = 0xFFFF_FFFF;
}

// Edge cases where the lint intentionally does NOT trigger
void edgeCases() {
  // A short leading group is correct — it is what is left over.
  const account = 12_345_678;

  // Whether to use separators at all is a different question.
  const plain = 1000000;

  // A single group cannot be inconsistent with anything.
  const thousand = 1_000;

  // Only the integer part is grouped here, and it is regular.
  const price = 1_000.5;
}
