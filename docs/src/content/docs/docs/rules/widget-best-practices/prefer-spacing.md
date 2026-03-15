---
title: prefer_spacing
description: "Use the spacing argument on Row/Column instead of SizedBox spacers"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_spacing
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule detects `SizedBox` widgets used as uniform spacers between children in a `Row`, `Column`, or `Flex`, and suggests using the built-in `spacing` argument instead. It also catches `separatedBy()` and `.expand()` patterns that insert SizedBox spacers. Requires Flutter 3.27+.

## Why use this rule

Scattering `SizedBox(height: 10)` between every child is verbose and easy to get wrong (miss one, use a different value, etc.). The `spacing` parameter on `Row`, `Column`, and `Flex` applies uniform spacing declaratively with a single property, making the intent clear and the code shorter. It also avoids polluting the `children` list with non-semantic spacer widgets.

**See also:** [Column spacing](https://api.flutter.dev/flutter/widgets/Flex/spacing.html)

## Don't

```dart
Column(
  children: [
    Text('First'),
    SizedBox(height: 10),
    Text('Second'),
    SizedBox(height: 10),
    Text('Third'),
  ],
)
```

## Do

```dart
Column(
  spacing: 10,
  children: [Text('First'), Text('Second'), Text('Third')],
)
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_spacing: false
```
