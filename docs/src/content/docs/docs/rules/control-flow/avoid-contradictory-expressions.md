---
title: avoid_contradictory_expressions
description: "Detect logical AND conditions that always evaluate to false"
sidebar:
  label: avoid_contradictory_expressions
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a logical AND (`&&`) expression contains contradictory comparisons on the same variable, resulting in a condition that always evaluates to `false`. For example, `x == 3 && x == 4` can never be true because `x` cannot equal both values simultaneously.

## Why use this rule

Contradictory conditions create unreachable code that silently does nothing. These are almost always bugs -- typically from copy-paste errors where one operand was not updated, or from refactoring that accidentally introduced conflicting constraints. Catching them at analysis time prevents hard-to-debug logic errors.

**See also:** [Effective Dart: Usage](https://dart.dev/effective-dart/usage)

## Don't

```dart
void bad(int x, int y) {
  // x cannot equal both 3 and 4
  if (x == 3 && x == 4) {
    print('unreachable');
  }

  // Impossible range — x can't be less than 4 AND greater than 4
  if (x < 4 && x > 4) {
    print('unreachable');
  }

  // Equality contradicts inequality
  if (x == 2 && x != 2) {
    print('unreachable');
  }

  // Same comparison with variable, opposite operators
  if (x == y && x != y) {
    print('unreachable');
  }
}
```

## Do

```dart
void good(int x, int y) {
  // Uses OR — x can be 3 or 4
  if (x == 3 || x == 4) {
    print('ok');
  }

  // Consistent range — x between 2 and 4
  if (x < 4 && x > 2) {
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
