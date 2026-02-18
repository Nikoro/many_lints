// ignore_for_file: unused_local_variable

// use_existing_destructuring
//
// Warns when a property is accessed directly on an object that already has a
// destructuring declaration in the same scope. The property should be added
// to the existing destructuring instead.

class Config {
  final String name;
  final int timeout;
  final bool verbose;

  const Config({
    required this.name,
    required this.timeout,
    required this.verbose,
  });
}

// ❌ Bad: Accessing property directly when destructuring already exists
void badDirectAccess(Config config) {
  final Config(:name) = config;
  // LINT: Use existing destructuring instead of accessing 'timeout' directly
  print(config.timeout);
}

// ❌ Bad: Multiple undeclared property accesses
void badMultipleAccesses(Config config) {
  final Config(:name) = config;
  // LINT: Both accesses should be added to the destructuring
  print(config.timeout);
  print(config.verbose);
}

// ❌ Bad: Record pattern with direct access
void badRecordAccess(({int left, int right}) record) {
  final (:left) = record;
  // LINT: Use existing destructuring for 'right'
  print(record.right);
}

// ✅ Good: All needed properties are destructured
void goodFullDestructuring(Config config) {
  final Config(:name, :timeout) = config;
  print(name);
  print(timeout);
}

// ✅ Good: No destructuring exists (no lint)
void goodNoDestructuring(Config config) {
  print(config.name);
  print(config.timeout);
}

// ✅ Good: Accessing a property that IS already destructured
void goodAlreadyDestructured(Config config) {
  final Config(:name, :timeout) = config;
  print(name);
  print(timeout);
}

// ✅ Good: Different variable than the one being destructured
void goodDifferentVariable(Config a, Config b) {
  final Config(:name) = a;
  print(b.timeout);
}

// ✅ Good: Access appears before the destructuring declaration
void goodBeforeDestructuring(Config config) {
  print(config.timeout);
  final Config(:name) = config;
  print(name);
}
