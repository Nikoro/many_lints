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

Flags explicit class prefixes on static field accesses (e.g., `SomeClass.first`) when the type can be inferred from context and a dot shorthand (`.first`) would suffice. This applies to switch cases, switch expressions, typed variable declarations, comparisons, default parameters, and return expressions.

## Why use this rule

When the expected type is already known from context, repeating the class name on a static field access adds visual noise. Dot shorthands are more concise and keep the focus on the value rather than the type. This rule skips enums, which are handled separately by `prefer_shorthands_with_enums`.

## Don't

```dart
class SomeClass {
  final String value;
  const SomeClass(this.value);
  static const first = SomeClass('first');
  static const second = SomeClass('second');
}

void example(SomeClass? e) {
  switch (e) {
    case SomeClass.first:
      print(e);
  }

  final SomeClass another = SomeClass.first;
  if (e == SomeClass.first) {}
}

void fn({SomeClass value = SomeClass.first}) {}

SomeClass getResult() => SomeClass.first;
```

## Do

```dart
void example(SomeClass? e) {
  switch (e) {
    case .first:
      print(e);
  }

  final SomeClass another = .first;
  if (e == .first) {}
}

void fn({SomeClass value = .first}) {}

SomeClass getResult() => .first;

// Explicit prefix is fine when type cannot be inferred:
Object getObject() => SomeClass.first;
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_shorthands_with_static_fields: false
```
