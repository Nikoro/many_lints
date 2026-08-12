---
title: prefer_shorthands_with_static_fields
description: "Use dot shorthands instead of explicit class prefixes for static fields."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_shorthands_with_static_fields
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Shorthand Patterns</span>

Flags explicit class prefixes on static field accesses (e.g., `Currency.usd`) when the type can be inferred from context and a dot shorthand (`.usd`) would suffice. This applies to switch cases, switch expressions, typed variable declarations, comparisons, default parameters, and return expressions.

## Why use this rule

When the expected type is already known from context, repeating the class name on a static field access adds visual noise. Dot shorthands are more concise and keep the focus on the value rather than the type. This rule skips enums, which are handled separately by `prefer_shorthands_with_enums`.

## Don't

```dart
class Currency {
  final String code;
  const Currency(this.code);
  static const usd = Currency('USD');
  static const eur = Currency('EUR');
}

void example(Currency? e) {
  switch (e) {
    case Currency.usd:
      print(e);
  }

  final Currency another = Currency.usd;
  if (e == Currency.usd) {}
}

void fn({Currency value = Currency.usd}) {}

Currency getResult() => Currency.usd;
```

## Do

```dart
void example(Currency? e) {
  switch (e) {
    case .usd:
      print(e);
  }

  final Currency another = .usd;
  if (e == .usd) {}
}

void fn({Currency value = .first}) {}

Currency getResult() => .usd;

// Explicit prefix is fine when type cannot be inferred:
Object getObject() => Currency.usd;
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_shorthands_with_static_fields: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_shorthands_with_static_fields: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
