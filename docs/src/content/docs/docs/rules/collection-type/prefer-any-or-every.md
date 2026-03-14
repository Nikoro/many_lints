---
title: prefer_any_or_every
description: "Use .{0}() instead of .where().{1}."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_any_or_every
---

| Property | Value |
|----------|-------|
| **Rule name** | `prefer_any_or_every` |
| **Category** | Collection & Type |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use .{0}() instead of .where().{1}.

## Suggestion

Replace with .{0}() for better readability and performance.

## Example

```dart
// prefer_any_or_every
//
// Use .any() instead of .where().isNotEmpty
// Use .every() with negated condition instead of .where().isEmpty

class PreferAnyOrEveryExample {
  final List<int> numbers = [1, 2, 3, 4, 5];

  void checkNumbers() {
    // LINT: Use .any() instead of .where().isNotEmpty
    final hasEven = numbers.where((n) => n.isEven).isNotEmpty;

    // LINT: Use .every() instead of .where().isEmpty
    final allPositive = numbers.where((n) => n < 0).isEmpty;

    print('$hasEven $allPositive');
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
