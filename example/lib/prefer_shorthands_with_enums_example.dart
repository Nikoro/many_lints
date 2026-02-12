enum MyEnum { first, second }

void exampleFunction(MyEnum? e) {
  // ❌ Bad: Using explicit enum prefix
  switch (e) {
    case MyEnum.first: // LINT
      print(e);
  }

  // ✅ Good: Using dot shorthand
  switch (e) {
    case .first:
      print(e);
  }

  // ❌ Bad: Explicit prefix in switch expression
  final v = switch (e) {
    MyEnum.first => 1, // LINT
    _ => 2,
  };

  // ✅ Good: Dot shorthand in switch expression
  final v2 = switch (e) {
    .first => 1,
    _ => 2,
  };

  // ❌ Bad: Explicit prefix in variable declaration
  final MyEnum another = MyEnum.first; // LINT

  // ✅ Good: Dot shorthand in variable declaration
  final MyEnum another2 = .first;

  // ❌ Bad: Explicit prefix in comparison
  if (e == MyEnum.first) {} // LINT

  // ✅ Good: Dot shorthand in comparison
  if (e == .first) {}
}

// ❌ Bad: Explicit prefix in default parameter
void anotherFunction({MyEnum value = MyEnum.first}) {} // LINT

// ✅ Good: Dot shorthand in default parameter
void anotherFunction2({MyEnum value = .first}) {}

// ❌ Bad: Explicit prefix in return expression
MyEnum getEnum() => MyEnum.first; // LINT

// ✅ Good: Dot shorthand in return expression
MyEnum getEnum2() => .first;

// ✅ Allowed: Full prefix when type is not inferable
Object getObject() => MyEnum.first; // No lint - type is Object, not MyEnum
