// ignore_for_file: unused_local_variable, avoid_print
// ignore_for_file: many_lints/prefer_primary_constructors

// prefer_early_return
//
// Detects a function body that is a single `if` wrapping everything the
// function does, where an inverted guard would remove a level of indentation.

class User {
  const User(this.isValid);

  final bool isValid;
}

void normalize(User user) {}
void persist(User user) {}
void notify(User user) {}

// ❌ Bad: the whole body lives one level in
void badExample(User user) {
  // LINT: the reader holds "we are in the valid case" for the entire body
  if (user.isValid) {
    normalize(user);
    persist(user);
    notify(user);
  }
}

// ✅ Good: the precondition is stated once, the rest is the happy path
void goodExample(User user) {
  if (!user.isValid) return;

  normalize(user);
  persist(user);
  notify(user);
}

// Edge cases where the lint intentionally does NOT trigger
class EdgeCases {
  final Map<String, int> bindings = {};

  // An already-negated condition inverts into a *longer* positive guard, and
  // the negation is what made the precondition obvious.
  void addPackage(String package) {
    if (!bindings.containsKey(package)) {
      bindings[package] = 0;
      print(package);
      print(bindings.length);
    }
  }

  // A statement before the `if` is setup the guard would have to move.
  void withSetup(User user) {
    print('starting');
    if (user.isValid) {
      normalize(user);
      persist(user);
      notify(user);
    }
  }

  // With an `else`, inverting swaps the branches rather than flattening.
  void withElse(User user) {
    if (user.isValid) {
      normalize(user);
      persist(user);
      notify(user);
    } else {
      print('invalid');
    }
  }

  // A pattern `if` binds variables the inverted branch could not see.
  void withPattern(Object o) {
    if (o case final int n) {
      print(n);
      print(n + 1);
      print(n + 2);
    }
  }
}
