---
title: avoid_duplicate_cascades
description: "Detect duplicate cascade sections in cascade expressions"
sidebar:
  label: avoid_duplicate_cascades
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a cascade expression contains duplicate sections -- identical property assignments, method calls, or index operations repeated with the same arguments. Duplicate cascades are usually the result of a copy-paste error.

## Why use this rule

When the same cascade section appears twice (e.g., `..name = 'test'` repeated), the second one overwrites the first with the same value, making it redundant. For method calls, the duplicate invocation may cause unintended side effects. Either way, it signals a copy-paste mistake that should be fixed.

**See also:** [Cascade notation](https://dart.dev/language/operators#cascade-notation)

## Don't

```dart
void bad() {
  // Same property assigned with same value twice
  final config = Config()
    ..name = 'test'
    ..name = 'test';

  // Same method called twice
  final config2 = Config()
    ..reset()
    ..reset();

  // Same index assigned with same value twice
  final list = [1, 2, 3]
    ..[1] = 5
    ..[1] = 5;
}
```

## Do

```dart
void good() {
  // Different properties
  final config = Config()
    ..name = 'test'
    ..value = 42;

  // Same property but different values
  final config2 = Config()
    ..name = 'first'
    ..name = 'second';

  // Different indices
  final list = [1, 2, 3]
    ..[0] = 10
    ..[1] = 20;
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_duplicate_cascades: false
```
