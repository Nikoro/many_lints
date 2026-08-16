// ignore_for_file: unused_field

// prefer_correct_setter_parameter_name
//
// Detects a setter whose parameter does not use the configured name. The name
// appears nowhere but the body, so all it communicates is the convention.

// ❌ Bad
class BadBox {
  int _width = 0;

  // LINT: the setter parameter 'newValue' should be named 'value'
  set width(int newValue) => _width = newValue;
}

// ✅ Good
class GoodBox {
  int _width = 0;

  set width(int value) => _width = value;
}

// Edge case: an override inherits its parameter name with the signature.
abstract class Base {
  set width(int value);
}

class Derived implements Base {
  int _width = 0;

  @override
  set width(int newValue) => _width = newValue;
}
