// ignore_for_file: unused_local_variable, unnecessary_statements

// avoid_constant_conditions
//
// Warns when a binary comparison has constant operands on both sides.
// The result is always the same, which usually indicates a typo or a bug.

const _another = 10;

abstract final class Config {
  static const value = '1';
}

// ❌ Bad: Both sides are constants — condition is always the same
void bad() {
  // LINT: Two integer literals compared
  if (10 == 11) {
    print('unreachable');
  }

  // LINT: Static const field compared to a string literal
  if (Config.value == '1') {
    print('always true');
  } else {
    print('unreachable');
  }

  // LINT: Top-level const compared to a literal
  final result = _another != 10;

  // LINT: Boolean literals compared
  final b = true == false;

  // LINT: Negative number literals
  final c = -1 < -2;
}

// ✅ Good: At least one side is a variable
void good(String value, int count) {
  // Variable compared to literal — fine
  if (value == '1') {
    print('hello');
  }

  // Variable compared to const — fine
  if (count > _another) {
    print('big');
  }

  // Two variables — fine
  final a = count;
  if (a == count) {
    print('same');
  }
}
