---
title: prefer_any_or_every
description: "Use .any() or .every() instead of .where().isEmpty/.isNotEmpty."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_any_or_every
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Using `.where(predicate).isNotEmpty` can be replaced with `.any(predicate)`, and `.where(predicate).isEmpty` can be replaced with `.every(negatedPredicate)`. The dedicated methods are more readable and can short-circuit evaluation, avoiding the creation of an intermediate lazy iterable.

## Why use this rule

`.any()` and `.every()` express intent more clearly and stop iterating as soon as the result is determined. `.where()` creates an intermediate `Iterable` that is unnecessary when you only need a boolean check.

**See also:** [Iterable.any](https://api.dart.dev/stable/dart-core/Iterable/any.html) | [Iterable.every](https://api.dart.dev/stable/dart-core/Iterable/every.html)

## Don't

```dart
class Example {
  final List<int> numbers = [1, 2, 3, 4, 5];

  void checkNumbers() {
    // Use .any() instead of .where().isNotEmpty
    final hasEven = numbers.where((n) => n.isEven).isNotEmpty;

    // Use .every() instead of .where().isEmpty
    final allPositive = numbers.where((n) => n < 0).isEmpty;
  }
}
```

## Do

```dart
class Example {
  final List<int> numbers = [1, 2, 3, 4, 5];

  void checkNumbers() {
    final hasEven = numbers.any((n) => n.isEven);

    final allPositive = numbers.every((n) => n >= 0);
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_any_or_every: false
```
