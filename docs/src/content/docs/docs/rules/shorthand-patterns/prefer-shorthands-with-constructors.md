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

Flags explicit constructor invocations of `EdgeInsets`, `BorderRadius`, `Radius`, and `Border` in argument or collection-literal position. In those positions the class name is usually redundant and can be replaced with a dot shorthand like `.all()`, `.symmetric()`, or `.circular()`.

## Why use this rule

These Flutter classes appear frequently in widget trees, and their constructors are often passed as named arguments where the type is already known. Replacing `EdgeInsets.all(8)` with `.all(8)` reduces visual clutter in deeply nested build methods, making the widget tree easier to scan.

**See also:** [Dart language - Constructor tear-offs](https://dart.dev/language/constructors#constructor-tear-offs)

## Don't

```dart
Padding(
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
  child: Text('Hello'),
);

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.blue, width: 3),
  ),
);

Padding(padding: EdgeInsets.all(8), child: Text('World'));
```

## Do

```dart
Padding(
  padding: .symmetric(horizontal: 20, vertical: 6),
  child: Text('Hello'),
);

Container(
  decoration: BoxDecoration(
    borderRadius: .circular(10),
    border: .all(color: Colors.blue, width: 3),
  ),
);

Padding(padding: .all(8), child: Text('World'));
```

## Known limitations

The rule does not resolve the declared type of the destination parameter. In argument position it only checks the constructed expression's own type, so it reports any of the four supported classes appearing there — even when the receiving parameter is `dynamic` or `Object`, where a dot shorthand has no context type and would not compile. If a parameter is untyped, keep the explicit class name and suppress the diagnostic on that line.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_shorthands_with_constructors: false
```
