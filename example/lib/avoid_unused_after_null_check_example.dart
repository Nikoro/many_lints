// ignore_for_file: unused_element, unused_local_variable, avoid_print
// The nested if demonstrates that deeper usage still counts as a use.
// ignore_for_file: many_lints/avoid_collapsible_if

// avoid_unused_after_null_check
//
// Warns when a variable is null-checked but never used in the branch that
// check guards. The guard looks like safety while the branch operates on a
// different variable entirely.

// ❌ Bad: `a` is checked, `b` is used
void badWrongVariable(String? a, String b) {
  // LINT: the check guards nothing the branch actually uses
  if (a != null) {
    print(b);
  }
}

// ❌ Bad: the inverted form guards the else branch
void badInverted(String? a, String b) {
  // LINT: the else branch is where `a` is known non-null
  if (a == null) {
    print('missing');
  } else {
    print(b);
  }
}

// ❌ Bad: null on the left reads the same way
void badNullOnLeft(String? a, String b) {
  // LINT: `null != a` is still a check on `a`
  if (null != a) {
    print(b);
  }
}

// ✅ Good: the checked variable is the one used
void goodUsed(String? a) {
  if (a != null) {
    print(a);
  }
}

// ✅ Good: the inverted form using the right variable
void goodInverted(String? a) {
  if (a == null) {
    print('missing');
  } else {
    print(a);
  }
}

// ✅ Good: usage nested deeper in the branch still counts
void goodNested(String? a, bool flag) {
  if (a != null) {
    if (flag) {
      print(a);
    }
  }
}

// ✅ Edge case: a field can be reached without naming it directly
class Holder {
  String? value;

  void f(String other) {
    if (value != null) {
      print(other);
    }
  }
}

// ✅ Edge case: `== null` with no else has no guarded branch to check
void noElseBranch(String? a) {
  if (a == null) {
    print('missing');
  }
}
