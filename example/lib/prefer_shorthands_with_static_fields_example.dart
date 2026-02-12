// ignore_for_file: unused_local_variable

/// Example demonstrating the prefer_shorthands_with_static_fields lint rule.
///
/// This rule suggests using dot shorthands with static fields when the type
/// can be inferred from context.

class SomeClass {
  final String value;

  const SomeClass(this.value);

  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void badExamples(SomeClass? e) {
  // ❌ BAD: Using explicit class prefix in switch case
  switch (e) {
    case SomeClass.first: // LINT
      print(e);
  }

  // ❌ BAD: Using explicit class prefix in switch expression
  final v = switch (e) {
    SomeClass.first => 1, // LINT
    _ => 2,
  };

  // ❌ BAD: Using explicit class prefix in variable declaration
  final SomeClass another = SomeClass.first; // LINT

  // ❌ BAD: Using explicit class prefix in comparison
  if (e == SomeClass.first) {} // LINT
}

// ❌ BAD: Using explicit class prefix in default parameter
void badDefaultParameter({SomeClass value = SomeClass.first}) {} // LINT

// ❌ BAD: Using explicit class prefix in return expression
SomeClass badReturnExpression() => SomeClass.first; // LINT

void goodExamples(SomeClass? e) {
  // ✅ GOOD: Using dot shorthand in switch case
  switch (e) {
    case .first:
      print(e);
  }

  // ✅ GOOD: Using dot shorthand in switch expression
  final v = switch (e) {
    .first => 1,
    _ => 2,
  };

  // ✅ GOOD: Using dot shorthand in variable declaration
  final SomeClass another = .first;

  // ✅ GOOD: Using dot shorthand in comparison
  if (e == .first) {}
}

// ✅ GOOD: Using dot shorthand in default parameter
void goodDefaultParameter({SomeClass value = .first}) {}

// ✅ GOOD: Using dot shorthand in return expression
SomeClass goodReturnExpression() => .first;

// ✅ GOOD: Explicit prefix is OK when type cannot be inferred
Object getObject() => SomeClass.first;

// ✅ GOOD: Not applicable when static field type differs from class
class Container {
  static const String staticString = 'test';
}

void useStaticString() {
  final String str = Container.staticString;
}
