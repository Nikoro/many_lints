// ignore_for_file: avoid_print
// ignore_for_file: many_lints/prefer_early_return
// ignore_for_file: many_lints/avoid_unmodified_loop_condition
// ignore_for_file: many_lints/prefer_type_over_var

// avoid_deep_nesting
//
// Detects control flow nested more deeply than the configured budget.
// An else-if chain is a sibling branch, not another level.

// ❌ Bad: five levels, and the innermost line's precondition cannot be stated
void badExample(List<List<int>> rows, bool enabled) {
  if (enabled) {
    for (final row in rows) {
      for (final cell in row) {
        if (cell > 0) {
          // LINT: nested 5 levels deep, over the limit of 4
          while (cell > 1) {
            print(cell);
          }
        }
      }
    }
  }
}

// ✅ Good: a guard and an extracted method remove two whole levels
void goodExample(List<List<int>> rows, bool enabled) {
  if (!enabled) return;

  for (final row in rows) {
    _processRow(row);
  }
}

void _processRow(List<int> row) {
  for (final cell in row) {
    if (cell <= 0) continue;
    print(cell);
  }
}

// Edge cases where the lint intentionally does NOT trigger
String elseIfChainIsFlat(int n) {
  // An else-if chain reads flat, so a long dispatch is not deep nesting.
  if (n == 1) {
    return 'one';
  } else if (n == 2) {
    return 'two';
  } else if (n == 3) {
    return 'three';
  } else if (n == 4) {
    return 'four';
  } else if (n == 5) {
    return 'five';
  }
  return 'many';
}

void nestedFunctionStartsOver(List<int> xs, bool flag) {
  if (flag) {
    for (final _ in xs) {
      // The callback's body is not reached through the enclosing nest.
      xs.forEach((e) {
        if (e > 0) {
          for (final digit in e.toString().split('')) {
            print(digit);
          }
        }
      });
    }
  }
}
