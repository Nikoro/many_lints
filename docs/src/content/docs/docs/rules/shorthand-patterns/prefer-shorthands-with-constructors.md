---
title: prefer_shorthands_with_constructors
description: "Use dot shorthand constructors for common Flutter classes."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_shorthands_with_constructors
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Shorthand Patterns</span>

Flags explicit constructor invocations of `EdgeInsets`, `BorderRadius`, `Radius`, and `Border` when the type can be inferred from context. In named arguments and collection literals, the class name is redundant and can be replaced with a dot shorthand like `.all()`, `.symmetric()`, or `.circular()`.

## Why use this rule

These Flutter classes appear frequently in widget trees, and their constructors are often passed as named arguments where the type is already known. Replacing `EdgeInsets.all(8)` with `.all(8)` reduces visual clutter in deeply nested build methods, making the widget tree easier to scan.

**See also:** [Dart language - Constructor tear-offs](https://dart.dev/language/constructors#constructor-tear-offs)

## Don't

```dart
Padding(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Text('Hello'),
);

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.blue, width: 2),
  ),
);

Padding(padding: EdgeInsets.all(8), child: Text('World'));
```

## Do

```dart
Padding(
  padding: .symmetric(horizontal: 16, vertical: 12),
  child: Text('Hello'),
);

Container(
  decoration: BoxDecoration(
    borderRadius: .circular(18),
    border: .all(color: Colors.blue, width: 2),
  ),
);

Padding(padding: .all(8), child: Text('World'));
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_shorthands_with_constructors: false
```
