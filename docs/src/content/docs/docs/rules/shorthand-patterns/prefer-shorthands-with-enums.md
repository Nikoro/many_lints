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

Flags explicit enum prefixes (e.g., `MyEnum.first`) when the enum type can be inferred from context and a dot shorthand (`.first`) would suffice. This applies to switch cases, switch expressions, variable declarations with explicit types, comparisons, default parameter values, and return expressions.

## Why use this rule

When the expected enum type is already known from context, repeating the enum name adds noise without adding clarity. Dot shorthands are shorter, reduce visual clutter in switch statements and widget trees, and are the idiomatic Dart style in type-inferred positions.

**See also:** [Dart language - Enums](https://dart.dev/language/enums)

## Don't

```dart
enum MyEnum { first, second }

void example(MyEnum? e) {
  switch (e) {
    case MyEnum.first:
      print(e);
  }

  final v = switch (e) {
    MyEnum.first => 1,
    _ => 2,
  };

  final MyEnum another = MyEnum.first;

  if (e == MyEnum.first) {}
}

void fn({MyEnum value = MyEnum.first}) {}

MyEnum getEnum() => MyEnum.first;
```

## Do

```dart
enum MyEnum { first, second }

void example(MyEnum? e) {
  switch (e) {
    case .first:
      print(e);
  }

  final v = switch (e) {
    .first => 1,
    _ => 2,
  };

  final MyEnum another = .first;

  if (e == .first) {}
}

void fn({MyEnum value = .first}) {}

MyEnum getEnum() => .first;

// Explicit prefix is fine when type cannot be inferred:
Object getObject() => MyEnum.first;

// Collection in an untyped position — no context type, so no lint:
expect(rankings, equals([MyEnum.first]));

// An explicit type argument does provide context:
takes(<MyEnum>[.first]);
```

## Collection literals need a real context type

A dot shorthand is only legal where the compiler has a **downward** context
type. Inside a collection literal that sits in a `dynamic` or `Object?`
position, there is none — the analyzer infers the literal's type upward from
the elements themselves:

```dart
// Not reported: `equals(Object? expected)` gives the list no context type.
expect(rankings, equals([MyEnum.first]));

// Writing `.ligex` here would fail to compile:
//   error: A dot shorthand can't be used where there is no context type.
//          (dot_shorthand_missing_context)
```

The rule reports inside a collection only when the element type comes from a
genuine context — a typed variable, a typed parameter, or an explicit type
argument:

```dart
final List<MyEnum> list = [.first];      // reported
takes(items: [.first]);                  // reported (typed named argument)
takes(<MyEnum>[.first]);                 // reported (explicit type argument)

final Map<MyEnum, String> m = {.first: 'a'};  // key half has context
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_shorthands_with_enums: false
```
