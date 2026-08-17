// ignore_for_file: unused_element, unused_local_variable

// avoid_collapsible_if
//
// Warns when an if statement contains nothing but another if, with no else
// on either level. Both conditions are a conjunction written across two
// blocks and can be merged with &&.

class _User {
  const _User(this.isActive);

  final bool isActive;
}

void _sendNotification(_User user) {}

// ❌ Bad: nested ifs that are really one condition
void badNested(_User? user) {
  // LINT: merge with &&
  if (user != null) {
    if (user.isActive) {
      _sendNotification(user);
    }
  }
}

// ❌ Bad: same shape without braces
void badWithoutBraces(bool a, bool b) {
  // LINT: merge with &&
  if (a) if (b) print('both');
}

// ✅ Good: one condition, one level of indentation
void goodMerged(_User? user) {
  if (user != null && user.isActive) {
    _sendNotification(user);
  }
}

// ✅ Good: an else on the outer if makes the nesting meaningful
void goodOuterElse(bool a, bool b) {
  if (a) {
    if (b) {
      print('both');
    }
  } else {
    print('neither');
  }
}

// ✅ Good: an else on the inner if likewise
void goodInnerElse(bool a, bool b) {
  if (a) {
    if (b) {
      print('both');
    } else {
      print('only a');
    }
  }
}

// ✅ Good: another statement in the outer block
void goodExtraStatement(bool a, bool b) {
  if (a) {
    print('a');
    if (b) {
      print('both');
    }
  }
}

// ✅ Edge case: a pattern if cannot be joined with &&
void edgeCasePattern(Object value, bool b) {
  if (value case int _) {
    if (b) {
      print('both');
    }
  }
}
// ignore_for_file: many_lints/prefer_primary_constructors
