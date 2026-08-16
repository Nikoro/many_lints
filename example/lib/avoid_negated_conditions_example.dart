// ignore_for_file: unused_local_variable, avoid_print
// ignore_for_file: many_lints/prefer_primary_constructors

// avoid_negated_conditions
//
// Detects an if/else or conditional expression whose condition is negated, so
// the `else` branch is the positive case.

class User {
  const User(this.isActive);

  final bool isActive;
}

void showDashboard() {}
void showInactiveBanner() {}

// ❌ Bad: the else branch is the positive case
void badExamples(User user, bool isReady) {
  // LINT: the reader holds a negation to know what the else is for
  if (!user.isActive) {
    showInactiveBanner();
  } else {
    showDashboard();
  }

  // LINT: the same inverted shape in a conditional expression
  final label = !isReady ? 'Waiting' : 'Ready';
}

// ✅ Good: each branch states its case directly
void goodExamples(User user, bool isReady) {
  if (user.isActive) {
    showDashboard();
  } else {
    showInactiveBanner();
  }

  final label = isReady ? 'Ready' : 'Waiting';
}

// Edge cases where the lint intentionally does NOT trigger
void edgeCases(User user, String? token, int byPoints, int fallback) {
  // A guard has no else to swap with, and is the clearest form there is.
  if (!user.isActive) return;

  // `!= null` is the null check the language is built around.
  if (token != null) {
    print(token);
  } else {
    print('no token');
  }

  // `!= 0` is the comparator tie-break idiom, not a negation.
  final order = byPoints != 0 ? byPoints : fallback;

  // An else-if chain encodes an ordered sequence of tests.
  if (!user.isActive) {
    print('inactive');
  } else if (token == null) {
    print('anonymous');
  }
}
