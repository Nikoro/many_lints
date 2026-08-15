// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_type_over_var
// ignore_for_file: many_lints/avoid_redundant_else

// avoid_unnecessary_continue
//
// Warns when a `continue` is the last statement of a loop body, where control
// reaches the next iteration whether it is there or not.

// ❌ Bad: nothing follows the `continue`
void badTrailingContinue(List<int> values) {
  for (final value in values) {
    _record(value);
    // LINT: the loop continues here anyway
    continue;
  }
}

// ❌ Bad: the only statement in the body
void badOnlyStatement(List<int> values) {
  for (final _ in values) {
    // LINT: an empty body says the same thing
    continue;
  }
}

// ❌ Bad: at the end of a `while`
void badInWhile(int count) {
  var remaining = count;
  while (remaining > 0) {
    remaining--;
    // LINT: last statement in the body
    continue;
  }
}

// ✅ Good: the `continue` guards the statements below it
void goodGuardingContinue(List<int> values) {
  for (final value in values) {
    if (value < 0) continue;
    _record(value);
  }
}

// ✅ Good: no `continue` at all
void goodPlainLoop(List<int> values) {
  for (final value in values) {
    _record(value);
  }
}

// ✅ Edge case: a labelled `continue` targets the outer loop, so it is doing
// real work even as the last statement of the inner one.
void goodLabelledContinue(List<List<int>> rows) {
  outer:
  for (final row in rows) {
    for (final value in row) {
      if (value < 0) continue outer;
      _record(value);
    }
  }
}

// ✅ Edge case: ending a `then` branch skips the `else`.
void goodContinueSkippingElse(List<int> values) {
  for (final value in values) {
    if (value < 0) {
      continue;
    } else {
      _record(value);
    }
  }
}

void _record(int value) {}
