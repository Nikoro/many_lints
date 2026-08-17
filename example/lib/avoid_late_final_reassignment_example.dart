// ignore_for_file: unused_element

// avoid_late_final_reassignment
//
// Warns when a `late final` field is assigned twice on one path, which throws
// a LateInitializationError at run time.

// ❌ Bad: the second write always throws
class BadSession {
  late final String token;

  void start(String value) {
    token = value;
    // LINT: `token` is already assigned on this path
    token = value.trim();
  }
}

// ✅ Good: assigned once
class GoodSession {
  late final String token;

  void start(String value) {
    token = value.trim();
  }
}

// ✅ Good: opposite branches are how a `late final` is meant to be set
class GoodBranchedSession {
  late final String token;

  void start(bool isGuest) {
    if (isGuest) {
      token = 'guest';
    } else {
      token = 'user';
    }
  }
}

// ✅ Edge case: without `final`, the field is meant to change.
class GoodMutable {
  late String token;

  void start() {
    token = 'first';
    token = 'second';
  }
}
// ignore_for_file: many_lints/prefer_conditional_expressions
