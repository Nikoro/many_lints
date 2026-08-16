// ignore_for_file: unused_local_variable, unused_field, avoid_print

// prefer_correct_identifier_length
//
// Detects an identifier outside the configured length bounds. The
// conventional short names are exempt out of the box.

int compute() => 1;

void badExamples() {
  // LINT: 'q' is 1 character, outside the range 2-40
  final q = compute();

  // LINT: too long — this is a sentence, not a name
  final theCompletelyUnnecessarilyVerboseResultHolder = compute();
}

void goodExamples() {
  final quota = compute();
  final result = compute();
}

// Edge cases where the lint intentionally does NOT trigger
void edgeCases() {
  // Loop counters and coordinates are conventional.
  for (var i = 0; i < 3; i++) {
    print(i);
  }

  // The `e` of a catch clause is too.
  try {
    print(1);
  } catch (e) {
    print(e);
  }
}

class Model {
  // A private name's underscore is a modifier, not part of its length.
  final int _id = 0;
}
