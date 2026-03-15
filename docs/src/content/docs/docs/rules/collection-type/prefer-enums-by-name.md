---
title: prefer_enums_by_name
description: "Use .byName() instead of .firstWhere() to look up enum values by name."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_enums_by_name
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Using `.firstWhere((e) => e.name == value)` on enum values can be replaced with the built-in `.byName()` method, available since Dart 2.15. The dedicated method is more concise, more readable, and throws a clear `ArgumentError` when the name is not found.

## Why use this rule

`.byName()` was specifically designed for looking up enum values by their string name. It is shorter, self-documenting, and provides a better error message on failure compared to the `firstWhere` approach which throws a generic `StateError`.

**See also:** [Dart enums](https://dart.dev/language/enums)

## Don't

```dart
enum Style { bold, italic, underline }

void example() {
  // Use .byName() instead of .firstWhere()
  final style = Style.values.firstWhere(
    (def) => def.name == 'bold',
  );

  // Reversed comparison also detected
  final style2 = Style.values.firstWhere(
    (def) => 'italic' == def.name,
  );

  // Variable comparison
  final name = 'underline';
  final style3 = Style.values.firstWhere((def) => def.name == name);
}
```

## Do

```dart
enum Style { bold, italic, underline }

void example() {
  final style = Style.values.byName('bold');

  final name = 'underline';
  final style2 = Style.values.byName(name);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_enums_by_name: false
```
