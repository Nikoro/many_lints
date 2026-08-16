// ignore_for_file: unused_local_variable, unused_element
// ignore_for_file: many_lints/prefer_boolean_prefixes

// no_magic_number
//
// Detects a numeric literal used without a name to explain it.
//
//   no_magic_number:
//     allowed: [-1, 0, 1, 2]
//     ignored_invocations: [EdgeInsets, Gap, Duration]
//     ignore_tests: true

// ❌ Bad
bool tooManyRetries(int retries) {
  // LINT: 3 states a policy the reader cannot check and the next person
  // cannot find.
  return retries > 3;
}

// ✅ Good
const maxRetries = 3;

bool tooManyRetriesNamed(int retries) => retries > maxRetries;

// Edge case: -1, 0, 1 and 2 are always allowed. They are the vocabulary of
// indexing, counting and halving, and naming them makes code worse.
int firstOrSentinel(List<int> xs) => xs.isEmpty ? -1 : xs.length ~/ 2;

// Edge case: a literal that INITIALISES a declaration is already named — this
// is the shape the rule asks people to move towards, so reporting it would be
// circular. The walk sees through arithmetic, so each of the three literals
// below is exempt too.
const maximumStoredBytes = 100 * 1024 * 1024;

void withDefault({int timeout = 30}) {}

// Edge case: measurements are ignored by default. A spacing grid was the
// single biggest source of noise on a real Flutter app — `spacing8` is a worse
// name than `8`, and extracting it moves the number away from the layout it
// describes. Clear `ignored_invocations` if you disagree.
class Insets {
  const Insets.only({this.top = 0, this.left = 0});

  final int top;
  final int left;
}

final padding = const Insets.only(top: 12, left: 24);
