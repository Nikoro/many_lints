// ignore_for_file: unused_field
// ignore_for_file: many_lints/member_ordering

// match_getter_setter_field_names
//
// Detects a getter/setter pair that does not use the same backing field.
// This is the copy-paste bug type checking cannot catch.

// ❌ Bad: the value will not stick, and both members compile
class BadBox {
  int _width = 0;
  int _height = 0;

  int get width => _width;
  // LINT: the getter for 'width' reads '_width' but its setter writes '_height'
  set width(int value) => _height = value;
}

// ✅ Good
class GoodBox {
  int _width = 0;

  int get width => _width;
  set width(int value) => _width = value;
}

// Edge cases where the lint intentionally does NOT trigger
class EdgeCases {
  int _a = 0;
  int _b = 0;

  // A computed getter has no single field to compare against.
  int get total => _a + _b;
  set total(int value) => _a = value;

  // A validating setter does more than assign, so it is not compared.
  int get a => _a;
  set a(int value) {
    if (value < 0) return;
    _b = value;
  }

  // A compound assignment reads the field too, so the asymmetry can be
  // deliberate.
  int get b => _b;
  set b(int value) => _a += value;
}
