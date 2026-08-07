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

:::caution[The Dart SDK already covers this]
The SDK ships a rule with the same name, [`prefer_contains`](https://dart.dev/tools/linter-rules/prefer_contains), and it is part of `package:lints/core.yaml` — so it is almost certainly already enabled in your project. The SDK rule is also slightly broader: it additionally catches `indexOf(x) < 0` and `indexOf(x) >= 0`, which this rule misses.

If both are active you will get **two diagnostics on the same line**, because plugin diagnostics are reported separately from SDK ones. Prefer the SDK rule and disable this one:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_contains: false
```
:::

## Why use this rule

`.contains()` communicates "does this exist?" more clearly than `.indexOf() != -1`. It is also less error-prone since there is no magic number to get wrong. This rule catches both `indexOf(x) == -1` and `indexOf(x) != -1` patterns, including reversed operand order.

**See also:** [Iterable.contains](https://api.dart.dev/stable/dart-core/Iterable/contains.html) | [Dart lint: prefer_contains](https://dart.dev/tools/linter-rules/prefer_contains)

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
