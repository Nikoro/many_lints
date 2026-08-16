// ignore_for_file: unused_element

// prefer_named_boolean_parameters
//
// Detects a boolean declared as a positional parameter, which is invisible at
// the call site and easy to pass in the wrong order.

// ❌ Bad: setVisible(false, true) is a puzzle
// LINT: the boolean parameters 'visible' and 'animate' are positional
void badSetVisible(bool visible, bool animate) {}

// ✅ Good: the call site says what each boolean means
void goodSetVisible({required bool visible, required bool animate}) {}

void callSites() {
  badSetVisible(false, true);
  goodSetVisible(visible: false, animate: true);
}

// Edge cases where the lint intentionally does NOT trigger

// A lone positional boolean reads acceptably.
void setEnabled(bool enabled) {}

// Non-boolean positionals are not this rule's concern.
void configure(String name, int count) {}

class Base {
  void handle(bool a, bool b) {}
}

class Derived extends Base {
  // An override cannot change the signature it inherits.
  @override
  void handle(bool a, bool b) {}
}
