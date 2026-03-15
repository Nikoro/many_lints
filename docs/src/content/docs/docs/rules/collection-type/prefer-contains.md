---
title: prefer_contains
description: "Use .contains() instead of .indexOf() compared to -1."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_contains
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Comparing `.indexOf()` to `-1` is a common pattern for checking whether an element exists in a collection or a substring exists in a string. The `.contains()` method expresses this intent more clearly and directly.

## Why use this rule

`.contains()` communicates "does this exist?" more clearly than `.indexOf() != -1`. It is also less error-prone since there is no magic number to get wrong. This rule catches both `indexOf(x) == -1` and `indexOf(x) != -1` patterns, including reversed operand order.

**See also:** [Iterable.contains](https://api.dart.dev/stable/dart-core/Iterable/contains.html)

## Don't

```dart
void example() {
  final list = [1, 2, 3];

  // Use .contains() instead of .indexOf() == -1
  final notFound = list.indexOf(1) == -1;

  // Use .contains() instead of .indexOf() != -1
  final found = list.indexOf(1) != -1;

  // Also reversed comparisons
  final reversed = -1 == list.indexOf(1);

  // Works on strings too
  final s = 'hello';
  final hasA = s.indexOf('a') != -1;
}
```

## Do

```dart
void example() {
  final list = [1, 2, 3];

  final notFound = !list.contains(1);
  final found = list.contains(1);

  // Comparing to specific index positions is fine
  final isFirst = list.indexOf(1) == 0;
  final isThird = list.indexOf(1) == 2;

  // Using indexOf for its return value is fine
  final idx = list.indexOf(1);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_contains: false
```
