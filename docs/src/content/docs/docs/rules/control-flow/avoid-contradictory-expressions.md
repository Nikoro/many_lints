---
title: avoid_contradictory_expressions
description: "This condition contains contradictory comparisons and always evaluates to false."
sidebar:
  label: avoid_contradictory_expressions
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_contradictory_expressions` |
| **Category** | Control Flow |
| **Severity** | Warning |
| **Has quick fix** | No |

## Problem

This condition contains contradictory comparisons and always evaluates to false.

## Suggestion

Check the operands — one of the comparisons is likely a bug.

## Example

```dart
// ignore_for_file: unused_local_variable, unnecessary_statements

// avoid_contradictory_expressions
//
// Warns when a logical AND (&&) expression contains contradictory comparisons
// on the same variable, resulting in a condition that always evaluates to false.

// ❌ Bad: Contradictory comparisons — always false
void bad(int x, int y) {
  // LINT: x cannot equal both 3 and 4
  if (x == 3 && x == 4) {
    print('unreachable');
  }

  // LINT: impossible range — x can't be less than 4 AND greater than 4
  if (x < 4 && x > 4) {
    print('unreachable');
  }

  // LINT: equality contradicts inequality
  if (x == 2 && x != 2) {
    print('unreachable');
  }

  // LINT: same comparison with variable, opposite operators
  if (x == y && x != y) {
    print('unreachable');
  }

  // LINT: different bool literals
  final b = x > 0 && x == 1 && x == 5;
}

// ✅ Good: Logically consistent conditions
void good(int x, int y) {
  // Uses OR — x can be 3 or 4
  if (x == 3 || x == 4) {
    print('ok');
  }

  // Consistent range — x between 2 and 4
  if (x < 4 && x > 2) {
    print('ok');
  }

  // Single comparison
  if (x == 2) {
    print('ok');
  }

  // Different variables
  if (x == 3 && y == 4) {
    print('ok');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_contradictory_expressions: false
```
