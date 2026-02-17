// ignore_for_file: unused_local_variable

// avoid_duplicate_cascades
//
// Warns when a cascade expression has duplicate cascade sections.
// Duplicate cascades are usually the result of a copy-paste error.

class Config {
  String name = '';
  int value = 0;
  void reset() {}
}

// ❌ Bad: Duplicate cascade sections
void bad() {
  // LINT: Same property assigned with same value twice
  final config = Config()
    ..name = 'test'
    ..name = 'test';

  // LINT: Same method called twice
  final config2 = Config()
    ..reset()
    ..reset();

  // LINT: Same index assigned with same value twice
  final list = [1, 2, 3]
    ..[1] = 5
    ..[1] = 5;
}

// ✅ Good: No duplicate cascade sections
void good() {
  // Different properties
  final config = Config()
    ..name = 'test'
    ..value = 42;

  // Same property but different values
  final config2 = Config()
    ..name = 'first'
    ..name = 'second';

  // Different methods
  final list = [1, 2, 3]
    ..[0] = 10
    ..[1] = 20;
}
