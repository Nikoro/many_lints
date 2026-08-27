---
title: prefer_shorthands_with_enums
description: "Use dot shorthands instead of explicit enum prefixes."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_shorthands_with_enums
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Shorthand Patterns</span>

This rule flags `LogLevel.debug` in a position where the expected type is already `LogLevel`, because `.debug` says the same thing. The quick fix removes the prefix.

It fires wherever the context supplies the type: switch cases and switch expression patterns, typed variable declarations, `==` comparisons, default parameter values, typed named arguments, returns from a function with a declared return type, and elements of a collection that has a real element type.

**See also:** [Dart language — dot shorthands](https://dart.dev/language/dot-shorthands)

## Don't

```dart
enum LogLevel { debug, warning, error }

void configure({LogLevel threshold = LogLevel.warning}) {}   // LINT

LogLevel defaultLevel() => LogLevel.debug;                    // LINT

String label(LogLevel level) {
  final LogLevel fallback = LogLevel.warning;                 // LINT

  if (level == LogLevel.debug) {                              // LINT
    return 'verbose';
  }

  return switch (level) {
    LogLevel.warning => 'warn',                               // LINT
    _ => 'other',
  };
}
```

## Do

```dart
void configure({LogLevel threshold = .warning}) {}

LogLevel defaultLevel() => .debug;

String label(LogLevel level) {
  final LogLevel fallback = .warning;

  if (level == .debug) {
    return 'verbose';
  }

  return switch (level) {
    .warning => 'warn',
    _ => 'other',
  };
}
```

## Named arguments and collections

A named argument with a declared enum type, and a collection whose element type is known, both give the compiler a context type:

```dart
enum LogLevel { debug, warning, error }

void setLevels({required List<LogLevel> levels}) {}

// Don't
void configure() {
  final List<LogLevel> verbose = [LogLevel.debug, LogLevel.warning];
  setLevels(levels: [LogLevel.error]);

  final Map<String, LogLevel> routes = {'api': LogLevel.warning};
}

// Do
void configure() {
  final List<LogLevel> verbose = [.debug, .warning];
  setLevels(levels: [.error]);

  final Map<String, LogLevel> routes = {'api': .warning};
}
```

## Known limitations

A dot shorthand is only legal where the compiler has a **downward** context
type. Where there is none, writing `.debug` fails to compile with
`dot_shorthand_missing_context` — so the rule stays quiet:

**An untyped destination.** `Object asObject() => LogLevel.debug;` and a `dynamic` or `Object?` parameter give the expression nothing to resolve against.

**A collection in an untyped position.** In `expect(rankings, equals([LogLevel.debug]))`, `equals` takes `Object?`, so the list's element type is inferred upward from the elements themselves — there is no context. Give the literal an explicit type argument (`equals(<LogLevel>[.debug])`) and it is reported.

**A type argument solved from the argument.** In `Box(items: const [LogLevel.debug])` the analyzer infers `T` *from* the element. The type displays as `List<LogLevel>`, but it is upward inference and the shorthand would not compile. `Box<LogLevel>(items: const [.debug])` pins the type argument and is reported.

**Only the half that matches.** In `Map<LogLevel, Object>`, the key position has a context type and the value position does not: `{LogLevel.first: LogLevel.second}` reports the key only.

**Plain assignment to an already-declared variable.** `value = LogLevel.debug;` after `LogLevel value;` is not reported.

**Access through an import prefix.** `logging.LogLevel.debug` is skipped, since the leading name is the library prefix rather than the enum.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_shorthands_with_enums: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_shorthands_with_enums: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_nested_shorthands`](/many_lints/docs/rules/shorthand-patterns/avoid-nested-shorthands/) — Avoid nesting a dot shorthand inside another dot shorthand invocation.
- [`prefer_returning_shorthands`](/many_lints/docs/rules/shorthand-patterns/prefer-returning-shorthands/) — Use dot shorthand constructors in expression function return values.
- [`prefer_shorthands_with_constructors`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-constructors/) — Use dot shorthand constructors for common Flutter classes.
- [`prefer_shorthands_with_static_fields`](/many_lints/docs/rules/shorthand-patterns/prefer-shorthands-with-static-fields/) — Use dot shorthands instead of explicit class prefixes for static fields.
