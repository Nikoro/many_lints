// ignore_for_file: avoid_print

// prefer_conditional_expressions
//
// Detects an if/else that only assigns or returns two values. Only exactly
// rewritable shapes are reported.

// ❌ Bad: six lines to choose between two strings
String badReturn(bool active) {
  // LINT: this if/else only chooses between two values
  if (active) {
    return 'On';
  } else {
    return 'Off';
  }
}

void badAssign(bool active) {
  String label;
  // LINT: this if/else only chooses between two values
  if (active) {
    label = 'On';
  } else {
    label = 'Off';
  }
  print(label);
}

// ✅ Good: the choice and both outcomes on one line
String goodReturn(bool active) => active ? 'On' : 'Off';

void goodAssign(bool active) {
  final label = active ? 'On' : 'Off';
  print(label);
}

// Edge cases where the lint intentionally does NOT trigger
void edgeCases(bool active, int n) {
  var a = '';
  var b = '';

  // Different targets are not a choice between two values.
  if (active) {
    a = 'On';
  } else {
    b = 'Off';
  }

  // A branch doing more than assigning cannot collapse.
  if (active) {
    print('x');
    a = 'On';
  } else {
    a = 'Off';
  }

  var count = 0;
  // Different operators are not a two-way choice either.
  if (active) {
    count = 1;
  } else {
    count += 2;
  }

  print('$a$b$count$n');
}
