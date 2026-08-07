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

Flags explicit class prefixes on static field accesses (e.g., `Currency.zloty`) when the type can be inferred from context and a dot shorthand (`.first`) would suffice. This applies to switch cases, switch expressions, typed variable declarations, comparisons, default parameters, and return expressions.

## Why use this rule

When the expected type is already known from context, repeating the class name on a static field access adds visual noise. Dot shorthands are more concise and keep the focus on the value rather than the type. This rule skips enums, which are handled separately by `prefer_shorthands_with_enums`.

## Don't

```dart
class Currency {
  final String code;
  const Currency(this.code);
  static const zloty = Currency('PLN');
  static const euro = Currency('EUR');
}

void example(Currency? e) {
  switch (e) {
    case Currency.zloty:
      print(e);
  }

  final Currency another = Currency.zloty;
  if (e == Currency.zloty) {}
}

void fn({Currency value = Currency.zloty}) {}

Currency getResult() => Currency.zloty;
```

## Do

```dart
void example(Currency? e) {
  switch (e) {
    case .zloty:
      print(e);
  }

  final Currency another = .zloty;
  if (e == .zloty) {}
}

void fn({Currency value = .first}) {}

Currency getResult() => .zloty;

// Explicit prefix is fine when type cannot be inferred:
Object getObject() => Currency.zloty;
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_shorthands_with_static_fields: false
```
