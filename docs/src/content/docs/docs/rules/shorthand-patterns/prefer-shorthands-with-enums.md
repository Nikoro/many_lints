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

Flags explicit enum prefixes (e.g., `LogLevel.debug`) when the enum type can be inferred from context and a dot shorthand (`.debug`) would suffice. This applies to switch cases, switch expressions, variable declarations with explicit types, comparisons, default parameter values, and return expressions.

## Why use this rule

When the expected enum type is already known from context, repeating the enum name adds noise without adding clarity. Dot shorthands are shorter, reduce visual clutter in switch statements and widget trees, and are the idiomatic Dart style in type-inferred positions.

**See also:** [Dart language - Enums](https://dart.dev/language/enums)

## Don't

```dart
enum LogLevel { debug, warning }

void example(LogLevel? e) {
  switch (e) {
    case LogLevel.debug:
      print(e);
  }

  final v = switch (e) {
    LogLevel.debug => 1,
    _ => 2,
  };

  final LogLevel defaultLevel = LogLevel.debug;

  if (e == LogLevel.debug) {}
}

void fn({LogLevel value = LogLevel.debug}) {}

LogLevel levelForBad() => LogLevel.debug;
```

## Do

```dart
enum LogLevel { debug, warning }

void example(LogLevel? e) {
  switch (e) {
    case .debug:
      print(e);
  }

  final v = switch (e) {
    .debug => 1,
    _ => 2,
  };

  final LogLevel defaultLevel = .debug;

  if (e == .debug) {}
}

void fn({LogLevel value = .debug}) {}

LogLevel levelForBad() => .debug;

// Explicit prefix is fine when type cannot be inferred:
Object asObject() => LogLevel.debug;

// Collection in an untyped position — no context type, so no lint:
expect(rankings, equals([LogLevel.debug]));

// An explicit type argument does provide context:
takes(<LogLevel>[.debug]);
```

## Collection literals need a real context type

A dot shorthand is only legal where the compiler has a **downward** context
type. Inside a collection literal that sits in a `dynamic` or `Object?`
position, there is none — the analyzer infers the literal's type upward from
the elements themselves:

```dart
// Not reported: `equals(Object? expected)` gives the list no context type.
expect(rankings, equals([LogLevel.debug]));

// Writing `.ligex` here would fail to compile:
//   error: A dot shorthand can't be used where there is no context type.
//          (dot_shorthand_missing_context)
```

The rule reports inside a collection only when the element type comes from a
genuine context — a typed variable, a typed parameter, or an explicit type
argument:

```dart
final List<LogLevel> list = [.debug];      // reported
takes(items: [.debug]);                  // reported (typed named argument)
takes(<LogLevel>[.debug]);                 // reported (explicit type argument)

final Map<LogLevel, String> m = {.debug: 'a'};  // key half has context
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_shorthands_with_enums: false
```
