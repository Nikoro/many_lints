// ignore_for_file: unused_element
// ignore_for_file: many_lints/prefer_boolean_prefixes

// function_always_returns_same_value
//
// Warns when every return in a function yields the same constant, so the
// branching around them decides nothing.

// ❌ Bad: whatever the caller passes, the answer is 3
// LINT: both returns yield '3'
int badScore(bool isWinner) {
  if (isWinner) return 3;
  return 3;
}

// ✅ Good: the branches differ
int goodScore(bool isWinner) {
  if (isWinner) return 3;
  return 0;
}

// ✅ Edge case: a protocol callback is *supposed* to return the same value on
// every path. `onNotification` must return false to let the notification keep
// bubbling; the method exists for its side effect.
class GoodListener {
  bool onNotification(Object notification) {
    if (notification is String) return false;
    _record();
    return false;
  }

  void _record() {}
}

// ✅ Edge case: the same callback under a descriptive name is recognised by
// its shape — a parameter typed `...Notification` marks it as a listener.
class ScrollNotification {}

class GoodShapedListener {
  bool updateVisibility([ScrollNotification? notification]) {
    if (notification == null) return false;
    _record();
    return false;
  }

  void _record() {}
}
