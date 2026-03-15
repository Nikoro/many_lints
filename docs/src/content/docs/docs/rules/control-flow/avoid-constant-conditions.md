---
title: avoid_constant_conditions
description: "Detect comparisons where both sides are constants"
sidebar:
  label: avoid_constant_conditions
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a binary comparison has constant operands on both sides, meaning the result is always the same at compile time. This usually indicates a typo, a copy-paste error, or dead code that should be cleaned up.

## Why use this rule

A condition like `10 == 11` or `Config.value == '1'` (where `Config.value` is a `static const`) always evaluates to the same boolean. One branch becomes unreachable dead code while the other always executes. This is almost never intentional and typically signals a mistake where one operand should have been a variable.

**See also:** [Effective Dart: Usage](https://dart.dev/effective-dart/usage)

## Don't

```dart
const _another = 10;

abstract final class Config {
  static const value = '1';
}

void bad() {
  // Two integer literals compared
  if (10 == 11) {
    print('unreachable');
  }

  // Static const field compared to a string literal
  if (Config.value == '1') {
    print('always true');
  }

  // Top-level const compared to a literal
  final result = _another != 10;

  // Boolean literals compared
  final b = true == false;
}
```

## Do

```dart
void good(String value, int count) {
  // Variable compared to literal
  if (value == '1') {
    print('hello');
  }

  // Variable compared to const
  if (count > _another) {
    print('big');
  }

  // Two variables
  final a = count;
  if (a == count) {
    print('same');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_constant_conditions: false
```
