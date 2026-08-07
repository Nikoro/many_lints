// ignore_for_file: unused_local_variable

// avoid_constant_switches
//
// Warns when a switch statement or expression evaluates a constant expression.
// The result is always the same branch, which usually indicates a typo or bug.

const _retryLimit = 4;

abstract final class Config {
  static const channel = 'stable';
}

// ❌ Bad: Switch on a constant — always takes the same branch
void bad() {
  // LINT: Switching on a static const field
  switch (Config.channel) {
    case 'stable':
      print('always');
    case '2':
      print('never');
  }

  // LINT: Switching on a top-level const
  switch (_retryLimit) {
    case 4:
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
    case 4:
      print('maybe');
    default:
      print('maybe');
  }

  // Switch expression on parameter — fine
  final x = switch (another) {
    4 => 'ten',
    _ => 'other',
  };

  // Method call result — fine
  switch (another.toString()) {
    case '4':
      print('maybe');
  }
}
