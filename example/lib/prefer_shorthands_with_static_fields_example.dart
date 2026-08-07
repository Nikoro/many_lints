// ignore_for_file: unused_local_variable
// ignore_for_file: many_lints/prefer_abstract_final_static_class, many_lints/use_existing_variable

/// Example demonstrating the prefer_shorthands_with_static_fields lint rule.
///
/// This rule suggests using dot shorthands with static fields when the type
/// can be inferred from context.

class Currency {
  final String code;

  const Currency(this.code);

  static const usd = Currency('USD');
  static const eur = Currency('EUR');
}

void badExamples(Currency? e) {
  // ❌ BAD: Using explicit class prefix in switch case
  switch (e) {
    case Currency.usd: // LINT
      print(e);
  }

  // ❌ BAD: Using explicit class prefix in switch expression
  final v = switch (e) {
    Currency.usd => 1, // LINT
    _ => 2,
  };

  // ❌ BAD: Using explicit class prefix in variable declaration
  final Currency another = Currency.usd; // LINT

  // ❌ BAD: Using explicit class prefix in comparison
  if (e == Currency.usd) {} // LINT
}

// ❌ BAD: Using explicit class prefix in default parameter
void badDefaultParameter({Currency value = Currency.usd}) {} // LINT

// ❌ BAD: Using explicit class prefix in return expression
Currency badReturnExpression() => Currency.usd; // LINT

void goodExamples(Currency? e) {
  // ✅ GOOD: Using dot shorthand in switch case
  switch (e) {
    case .usd:
      print(e);
  }

  // ✅ GOOD: Using dot shorthand in switch expression
  final v = switch (e) {
    .usd => 1,
    _ => 2,
  };

  // ✅ GOOD: Using dot shorthand in variable declaration
  final Currency another = .usd;

  // ✅ GOOD: Using dot shorthand in comparison
  if (e == .usd) {}
}

// ✅ GOOD: Using dot shorthand in default parameter
void goodDefaultParameter({Currency value = .usd}) {}

// ✅ GOOD: Using dot shorthand in return expression
Currency goodReturnExpression() => .usd;

// ✅ GOOD: Explicit prefix is OK when type cannot be inferred
Object getObject() => Currency.usd;

// ✅ GOOD: Not applicable when static field type differs from class
class Container {
  static const String staticString = 'test';
}

void useStaticString() {
  final String str = Container.staticString;
}
