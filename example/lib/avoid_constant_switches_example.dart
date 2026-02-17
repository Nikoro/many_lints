// ignore_for_file: unused_local_variable

// avoid_constant_switches
//
// Warns when a switch statement or expression evaluates a constant expression.
// The result is always the same branch, which usually indicates a typo or bug.

const _another = 10;

abstract final class Config {
  static const value = '1';
}

// ❌ Bad: Switch on a constant — always takes the same branch
void bad() {
  // LINT: Switching on a static const field
  switch (Config.value) {
    case '1':
      print('always');
    case '2':
      print('never');
  }

  // LINT: Switching on a top-level const
  switch (_another) {
    case 10:
      print('always');
    default:
      print('never');
  }

  // LINT: Switch expression on an integer literal
  final x = switch (42) {
    42 => 'yes',
    _ => 'no',
  };
}

// ✅ Good: Switch on a variable or parameter
void good(int another) {
  // Parameter — fine
  switch (another) {
    case 10:
      print('maybe');
    default:
      print('maybe');
  }

  // Switch expression on parameter — fine
  final x = switch (another) {
    10 => 'ten',
    _ => 'other',
  };

  // Method call result — fine
  switch (another.toString()) {
    case '10':
      print('maybe');
  }
}
