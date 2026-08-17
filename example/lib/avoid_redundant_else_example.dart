// ignore_for_file: unused_element, unused_local_variable

// avoid_redundant_else
//
// Warns when an else follows an if branch that always exits. Control can
// never reach the else from that branch, so it only adds indentation.

// ❌ Bad: else after a return
String badAfterReturn(int value) {
  if (value < 0) {
    return 'negative';
    // LINT: this else is redundant
  } else {
    return 'non-negative';
  }
}

// ❌ Bad: else after a throw
String badAfterThrow(int? value) {
  if (value == null) {
    throw ArgumentError('value required');
    // LINT: same problem
  } else {
    return '$value';
  }
}

// ❌ Bad: else after a continue
void badAfterContinue(List<int> items) {
  for (final item in items) {
    if (item.isEven) {
      continue;
      // LINT: redundant
    } else {
      print(item);
    }
  }
}

// ✅ Good: guard clause, flat main path
String goodGuardClause(int value) {
  if (value < 0) {
    return 'negative';
  }
  return 'non-negative';
}

// ✅ Good: the then branch does not exit, so else is meaningful
void goodBothBranchesRun(bool flag) {
  if (flag) {
    print('yes');
  } else {
    print('no');
  }
}

// ✅ Good: else-if chains read as one decision and are never reported
int goodElseIfChain(int value) {
  if (value < 0) {
    return -1;
  } else if (value > 0) {
    return 1;
  }
  return 0;
}

// ✅ Edge case: the return is not the last statement, so the branch can
// fall through to the else
int edgeCaseFallthrough(bool flag) {
  if (flag) {
    if (flag) return 1;
    print('fallthrough');
  } else {
    return 2;
  }
  return 3;
}
// ignore_for_file: many_lints/prefer_conditional_expressions
