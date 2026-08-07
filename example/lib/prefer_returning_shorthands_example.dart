// prefer_returning_shorthands
//
// Suggests returning dot shorthands from an expression function body.
//
// Function and method declarations already have an explicit return type and in
// cases when that type is the same as the returned instance, the instance can be
// simplified to a dot shorthand without reducing readability.

class Currency {
  final String code;

  const Currency(this.code);
  const Currency.symbol(this.code);
}

class ExampleService {
  // === BAD examples ===

  // LINT: Use .new('PLN') instead of Currency('PLN')
  Currency getInstance() => Currency('PLN');

  // LINT: Use .symbol('PLN') instead of Currency.symbol('PLN')
  Currency getNamedInstance() => Currency.symbol('PLN');

  // LINT: Both branches can use shorthands
  Currency getConditional(bool flag) =>
      flag ? Currency('EUR') : Currency.symbol('PLN');

  // LINT: Works with nullable return types too
  Currency? getNullable() => Currency('PLN');

  // === GOOD examples ===

  // GOOD: Using dot shorthand for default constructor
  Currency getInstanceGood() => .new('PLN');

  // GOOD: Using dot shorthand for named constructor
  Currency getNamedInstanceGood() => .symbol('PLN');

  // GOOD: Using shorthands in conditional
  Currency getConditionalGood(bool flag) => flag ? .new('EUR') : .symbol('PLN');

  // === Cases where the lint does NOT trigger ===

  // GOOD: Block function body (not an expression function)
  Currency getWithBlock() {
    return Currency('PLN');
  }

  // GOOD: No explicit return type
  getInstanceInferred() => Currency('PLN');

  // GOOD: Dynamic return type
  dynamic getDynamic() => Currency('PLN');

  // GOOD: Already using shorthand
  Currency getAlreadyShorthand() => .new('PLN');
}

// Example with generics
class GenericClass<T> {
  final T value;

  const GenericClass(this.value);
}

class GenericService {
  // LINT: Generic classes also benefit from shorthands
  GenericClass<String> getGeneric() => GenericClass<String>('PLN');

  // GOOD: Using shorthand
  GenericClass<String> getGenericGood() => .new('PLN');
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
