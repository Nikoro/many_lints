---
title: avoid_constant_switches
description: "Detect switch statements on constant expressions"
sidebar:
  label: avoid_constant_switches
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a switch statement or switch expression evaluates a constant expression. Since the value never changes, the switch always takes the same branch, making all other cases dead code. This usually indicates a typo or a bug.

## Why use this rule

Switching on a constant means only one branch can ever execute, turning the switch into expensive dead code. This is typically a mistake -- the developer likely intended to switch on a variable or parameter instead of a compile-time constant. Catching this early prevents unreachable code from accumulating.

**See also:** [Effective Dart: Usage](https://dart.dev/effective-dart/usage)

## Don't

```dart
const _retryLimit = 4;

abstract final class Config {
  static const channel = 'stable';
}

void bad() {
  // Switching on a static const field
  switch (Config.channel) {
    case 'stable':
      print('always');
    case '2':
      print('never');
  }

  // Switching on a top-level const
  switch (_retryLimit) {
    case 4:
      print('always');
    default:
      print('never');
  }

  // Switch expression on an integer literal
  final x = switch (42) {
    42 => 'yes',
    _ => 'no',
  };
}
```

## Do

```dart
void good(int another) {
  // Parameter
  switch (another) {
    case 4:
      print('maybe');
    default:
      print('maybe');
  }

  // Switch expression on parameter
  final x = switch (another) {
    4 => 'ten',
    _ => 'other',
  };

  // Method call result
  switch (another.toString()) {
    case '4':
      print('maybe');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_constant_switches: false
```
