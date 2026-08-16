// ignore_for_file: unused_local_variable

// double_literal_format
//
// Detects double literals written with a missing leading zero, a redundant
// leading zero, or a redundant trailing zero.

// ❌ Bad: spellings that carry no extra information
void badExamples() {
  // LINT: no leading zero — `.5` reads as a member access until the digit
  const opacity = .5;

  // LINT: a redundant trailing zero
  const scale = 0.50;

  // LINT: a redundant leading zero, a typo under any style
  const ratio = 00.5;

  // LINT: the trailing zero is redundant in the mantissa too
  const distance = 1.50e10;
}

// ✅ Good: one leading zero, no redundant trailing zeros
void goodExamples() {
  const opacity = 0.5;
  const scale = 0.5;
  const ratio = 0.5;
  const distance = 1.5e10;
}

// Edge cases where the lint intentionally does NOT trigger
void edgeCases() {
  // A single trailing zero is significant: `1.` is invalid and `1` is an int.
  const padding = 16.0;
  const origin = 0.0;

  // Integer literals are out of scope.
  const count = 500;

  // Digit separators belong to avoid_inconsistent_digit_separators, which
  // owns the question of where the underscores go.
  const budget = 1_000.50;

  // An exponent with no fraction is already minimal.
  const large = 5e3;
}
