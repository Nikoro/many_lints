// prefer_returning_shorthands
//
// Suggests returning dot shorthands from an expression function body.
//
// Function and method declarations already have an explicit return type and in
// cases when that type is the same as the returned instance, the instance can be
// simplified to a dot shorthand without reducing readability.

class SomeClass {
  final String value;

  const SomeClass(this.value);
  const SomeClass.named(this.value);
}

class ExampleService {
  // === BAD examples ===

  // LINT: Use .new('val') instead of SomeClass('val')
  SomeClass getInstance() => SomeClass('val');

  // LINT: Use .named('val') instead of SomeClass.named('val')
  SomeClass getNamedInstance() => SomeClass.named('val');

  // LINT: Both branches can use shorthands
  SomeClass getConditional(bool flag) =>
      flag ? SomeClass('value') : SomeClass.named('val');

  // LINT: Works with nullable return types too
  SomeClass? getNullable() => SomeClass('val');

  // === GOOD examples ===

  // GOOD: Using dot shorthand for default constructor
  SomeClass getInstanceGood() => .new('val');

  // GOOD: Using dot shorthand for named constructor
  SomeClass getNamedInstanceGood() => .named('val');

  // GOOD: Using shorthands in conditional
  SomeClass getConditionalGood(bool flag) =>
      flag ? .new('value') : .named('val');

  // === Cases where the lint does NOT trigger ===

  // GOOD: Block function body (not an expression function)
  SomeClass getWithBlock() {
    return SomeClass('val');
  }

  // GOOD: No explicit return type
  getInstance() => SomeClass('val');

  // GOOD: Dynamic return type
  dynamic getDynamic() => SomeClass('val');

  // GOOD: Already using shorthand
  SomeClass getAlreadyShorthand() => .new('val');
}

// Example with generics
class GenericClass<T> {
  final T value;

  const GenericClass(this.value);
}

class GenericService {
  // LINT: Generic classes also benefit from shorthands
  GenericClass<String> getGeneric() => GenericClass<String>('val');

  // GOOD: Using shorthand
  GenericClass<String> getGenericGood() => .new('val');
}

// Example showing the benefits
class ConfigFactory {
  // Without shorthands (verbose)
  Config getDefaultConfigBad() => Config.development('localhost', 3000);
  Config getProductionConfigBad() => Config.production('api.example.com', 443);

  // With shorthands (concise and readable)
  Config getDefaultConfigGood() => .development('localhost', 3000);
  Config getProductionConfigGood() => .production('api.example.com', 443);
}

class Config {
  final String host;
  final int port;

  const Config.development(this.host, this.port);
  const Config.production(this.host, this.port);
}
