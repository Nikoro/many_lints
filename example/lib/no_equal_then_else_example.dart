// ignore_for_file: unused_element, unused_local_variable, avoid_print

// no_equal_then_else
//
// Warns when both branches of an if/else or a conditional expression are
// identical. If both branches do the same thing, the condition decides
// nothing — usually one branch was meant to differ.

// ❌ Bad: both blocks are the same
void badBlocks(bool flag) {
  // LINT: the condition changes nothing
  if (flag) {
    print('same');
  } else {
    print('same');
  }
}

// ❌ Bad: a block and a bare statement still match
void badMixedForms(bool flag) {
  // LINT: `{ f(); }` and `f();` are the same branch
  if (flag) {
    print('same');
  } else {
    print('same');
  }
}

// ❌ Bad: the conditional-expression form
int badConditional(bool flag) {
  // LINT: both arms produce the same value
  return flag ? 1 : 1;
}

// ✅ Good: the branches genuinely differ
void goodBranches(bool flag) {
  if (flag) {
    print('yes');
  } else {
    print('no');
  }
}

// ✅ Good: no else branch to compare against
void goodNoElse(bool flag) {
  if (flag) {
    print('yes');
  }
}

// ✅ Good: a conditional with distinct arms
int goodConditional(bool flag) => flag ? 1 : 2;

// ✅ Edge case: an else-if chain is a different shape
void elseIfChain(int value) {
  if (value == 1) {
    print('one');
  } else if (value == 2) {
    print('one');
  }
}

// ✅ Edge case: two empty branches are usually work in progress
void emptyBranches(bool flag) {
  if (flag) {
  } else {}
}
