// ignore_for_file: unused_element

// no_equal_switch_case
//
// Warns when two branches of a switch produce identical bodies, where sharing
// the patterns would say the same thing once.

// ❌ Bad: the same outcome written twice
String badLabel(int code) => switch (code) {
  // LINT: `2` below has this body too
  1 => 'ok',
  2 => 'ok',
  _ => 'error',
};

// ✅ Good: the patterns share one body
String goodLabel(int code) => switch (code) {
  1 || 2 => 'ok',
  _ => 'error',
};

// ✅ Edge case: a guarded case cannot be merged — each `when` belongs to its
// own pattern.
String goodGuarded(int value) => switch (value) {
  int() when value > 10 => 'extreme',
  int() when value < -10 => 'extreme',
  _ => 'normal',
};

// ✅ Edge case: the catch-all has to stay last, so it cannot be folded into an
// earlier pattern even when it repeats a body.
int goodCatchAll(int month) => switch (month) {
  1 || 3 || 5 || 7 || 8 || 10 || 12 => 31,
  4 || 6 || 9 || 11 => 30,
  2 => 29,
  _ => 31,
};

// ✅ Edge case: consecutive empty cases are a fallthrough, not a duplicate.
void goodFallthrough(int code) {
  switch (code) {
    case 1:
    case 2:
      print('low');
      break;
  }
}
