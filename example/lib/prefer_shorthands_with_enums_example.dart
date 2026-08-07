// ignore_for_file: many_lints/avoid_missing_enum_constant_in_map, many_lints/use_existing_variable
// ignore_for_file: unused_local_variable
enum LogLevel { debug, warning }

void exampleFunction(LogLevel? e) {
  // ❌ Bad: Using explicit enum prefix
  switch (e) {
    case LogLevel.debug: // LINT
      print(e);
    default:
      break;
  }

  // ✅ Good: Using dot shorthand
  switch (e) {
    case .debug:
      print(e);
    default:
      break;
  }

  // ❌ Bad: Explicit prefix in switch expression
  final v = switch (e) {
    LogLevel.debug => 1, // LINT
    _ => 2,
  };

  // ✅ Good: Dot shorthand in switch expression
  final v2 = switch (e) {
    .debug => 1,
    _ => 2,
  };

  // ❌ Bad: Explicit prefix in variable declaration
  final LogLevel defaultLevel = LogLevel.debug; // LINT

  // ✅ Good: Dot shorthand in variable declaration
  final LogLevel fallbackLevel = .debug;

  // ❌ Bad: Explicit prefix in comparison
  if (e == LogLevel.debug) {} // LINT

  // ✅ Good: Dot shorthand in comparison
  if (e == .debug) {}
}

// ❌ Bad: Explicit prefix in default parameter
void configureBad({LogLevel value = LogLevel.debug}) {} // LINT

// ✅ Good: Dot shorthand in default parameter
void configureGood({LogLevel value = .debug}) {}

// ❌ Bad: Explicit prefix in return expression
LogLevel levelForBad() => LogLevel.debug; // LINT

// ✅ Good: Dot shorthand in return expression
LogLevel levelForGood() => .debug;

// ✅ Allowed: Full prefix when type is not inferable
Object asObject() => LogLevel.debug; // No lint - type is Object, not LogLevel

void takesDynamic(dynamic value) {}
void takesTyped({required List<LogLevel> items}) {}

void collectionExamples() {
  // ✅ Allowed: The list sits in a `dynamic` position, so it has no downward
  // context type. A shorthand here would not compile
  // (dot_shorthand_missing_context).
  takesDynamic([LogLevel.debug]); // No lint

  // ❌ Bad: Explicit type argument provides a real context
  takesDynamic(<LogLevel>[LogLevel.debug]); // LINT

  // ✅ Good: Dot shorthand under an explicit type argument
  takesDynamic(<LogLevel>[.debug]);

  // ❌ Bad: Typed named argument provides context
  takesTyped(items: [LogLevel.debug]); // LINT

  // ✅ Good: Dot shorthand under a typed named argument
  takesTyped(items: [.debug]);

  // ❌ Bad: Map key inherits the key type argument
  final Map<LogLevel, String> m = {LogLevel.debug: 'a'}; // LINT

  // ✅ Good: Dot shorthand in the key position
  final Map<LogLevel, String> m2 = {.debug: 'a'};

  print([m, m2]);
}
