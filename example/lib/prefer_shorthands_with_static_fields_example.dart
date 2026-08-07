// ignore_for_file: unused_local_variable

/// Example demonstrating the prefer_shorthands_with_static_fields lint rule.
///
/// This rule suggests using dot shorthands with static fields when the type
/// can be inferred from context.

class Currency {
  final String code;

  const Currency(this.code);

  static const zloty = Currency('PLN');
  static const euro = Currency('EUR');
}

void badExamples(Currency? e) {
  // ❌ BAD: Using explicit class prefix in switch case
  switch (e) {
    case Currency.zloty: // LINT
      print(e);
  }

  // ❌ BAD: Using explicit class prefix in switch expression
  final v = switch (e) {
    Currency.zloty => 1, // LINT
    _ => 2,
  };

  // ❌ BAD: Using explicit class prefix in variable declaration
  final Currency another = Currency.zloty; // LINT

  // ❌ BAD: Using explicit class prefix in comparison
  if (e == Currency.zloty) {} // LINT
}

// ❌ BAD: Using explicit class prefix in default parameter
void badDefaultParameter({Currency value = Currency.zloty}) {} // LINT

// ❌ BAD: Using explicit class prefix in return expression
Currency badReturnExpression() => Currency.zloty; // LINT

void goodExamples(Currency? e) {
  // ✅ GOOD: Using dot shorthand in switch case
  switch (e) {
    case .zloty:
      print(e);
  }

  // ✅ GOOD: Using dot shorthand in switch expression
  final v = switch (e) {
    .zloty => 1,
    _ => 2,
  };

  // ✅ GOOD: Using dot shorthand in variable declaration
  final Currency another = .zloty;

  // ✅ GOOD: Using dot shorthand in comparison
  if (e == .zloty) {}
}

// ✅ GOOD: Using dot shorthand in default parameter
void goodDefaultParameter({Currency value = .zloty}) {}

// ✅ GOOD: Using dot shorthand in return expression
Currency goodReturnExpression() => .zloty;

// ✅ GOOD: Explicit prefix is OK when type cannot be inferred
Object getObject() => Currency.zloty;

// ✅ GOOD: Not applicable when static field type differs from class
class Container {
  static const String staticString = 'test';
}

void useStaticString() {
  final String str = Container.staticString;
}
