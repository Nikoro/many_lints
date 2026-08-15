// ignore_for_file: unused_element

// no_equal_conditions
//
// Warns when an if/else-if chain repeats a condition, making the later branch
// unreachable.

// ❌ Bad: the second test can never be reached
String badChain(int value) {
  if (value > 0) {
    return 'positive';
    // LINT: `value > 0` was already taken by the branch above
  } else if (value > 0) {
    return 'still positive';
  }
  return 'other';
}

// ✅ Good: each branch tests something different
String goodChain(int value) {
  if (value > 0) {
    return 'positive';
  } else if (value < 0) {
    return 'negative';
  }
  return 'zero';
}

// ✅ Edge case: two independent `if`s are not a chain. The first may have
// changed the state the second reads.
void goodSeparateChains(int value) {
  if (value > 0) {
    _record(value);
  }
  if (value > 0) {
    _report(value);
  }
}

void _record(int value) {}
void _report(int value) {}
