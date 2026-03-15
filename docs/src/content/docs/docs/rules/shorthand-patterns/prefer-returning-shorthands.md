---
title: prefer_returning_shorthands
description: "Use dot shorthand constructors in expression function return values."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_returning_shorthands
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Shorthand Patterns</span>

Flags expression function bodies that return an instance whose type matches the declared return type. Since the return type is already explicit, the class name in the constructor call is redundant and can be replaced with a dot shorthand (e.g., `.new()` or `.named()`).

## Why use this rule

When a function already declares its return type, repeating the class name in the returned constructor call adds visual noise without extra information. Dot shorthands reduce this redundancy, making arrow functions more concise. This also applies to both branches of conditional expressions.

**See also:** [Dart language - Arrow syntax](https://dart.dev/language/functions#arrow-syntax)

## Don't

```dart
class SomeClass {
  final String value;
  const SomeClass(this.value);
  const SomeClass.named(this.value);
}

SomeClass getInstance() => SomeClass('val');

SomeClass getNamedInstance() => SomeClass.named('val');

SomeClass getConditional(bool flag) =>
    flag ? SomeClass('value') : SomeClass.named('val');

SomeClass? getNullable() => SomeClass('val');
```

## Do

```dart
SomeClass getInstance() => .new('val');

SomeClass getNamedInstance() => .named('val');

SomeClass getConditional(bool flag) =>
    flag ? .new('value') : .named('val');

// Block function bodies are not flagged:
SomeClass getWithBlock() {
  return SomeClass('val');
}

// No explicit return type — not flagged:
getInstance() => SomeClass('val');

// Dynamic return type — not flagged:
dynamic getDynamic() => SomeClass('val');
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_returning_shorthands: false
```
