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

A condition like `4 == 11` or `Config.channel == 'stable'` (where `Config.channel` is a `static const`) always evaluates to the same boolean. One branch becomes unreachable dead code while the other always executes. This is almost never intentional and typically signals a mistake where one operand should have been a variable.

**See also:** [Effective Dart: Usage](https://dart.dev/effective-dart/usage)

## Don't

```dart
const _retryLimit = 4;

abstract final class Config {
  static const channel = 'stable';
}

void bad() {
  // Two integer literals compared
  if (4 == 11) {
    print('unreachable');
  }

  // Static const field compared to a string literal
  if (Config.channel == 'stable') {
    print('always true');
  }

  // Top-level const compared to a literal
  final result = _retryLimit != 4;

  // Boolean literals compared
  final b = true == false;
}
```

## Do

```dart
void good(String value, int count) {
  // Variable compared to literal
  if (value == 'stable') {
    print('hello');
  }

  // Variable compared to const
  if (count > _retryLimit) {
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

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_constant_conditions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
