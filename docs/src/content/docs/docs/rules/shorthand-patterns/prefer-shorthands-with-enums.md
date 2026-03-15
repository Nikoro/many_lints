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
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_shorthands_with_enums: false
```
