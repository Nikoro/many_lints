// ignore_for_file: unused_local_variable

// prefer_contains
//
// Warns when using .indexOf() compared to -1 instead of .contains().
// Using .contains() directly expresses the intent of checking for presence.

// ❌ Bad: Using .indexOf() compared to -1
void bad() {
  final list = [1, 2, 3];

  // LINT: Use .contains() instead of .indexOf() == -1
  final notFound = list.indexOf(1) == -1;

  // LINT: Use .contains() instead of .indexOf() != -1
  final found = list.indexOf(1) != -1;

  // LINT: Also reversed comparisons
  final reversed = -1 == list.indexOf(1);

  // LINT: Works on strings too
  final s = 'hello';
  final hasA = s.indexOf('a') != -1;
}

// ✅ Good: Using .contains()
void good() {
  final list = [1, 2, 3];

  final notFound = !list.contains(1);
  final found = list.contains(1);

  // Comparing to specific index positions is fine
  final isFirst = list.indexOf(1) == 0;
  final isThird = list.indexOf(1) == 2;

  // Using indexOf for its return value is fine
  final idx = list.indexOf(1);
}
