---
title: avoid_single_child_in_multi_child_widgets
description: "Don't use Column, Row, or other multi-child widgets with only one child"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_single_child_in_multi_child_widgets
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags multi-child widgets like `Column`, `Row`, and `Wrap` that contain only a single child in their `children` list. A multi-child layout widget with one child adds unnecessary complexity and layout overhead for something that could be expressed more simply.

## Why use this rule

A `Column` or `Row` with a single child does the same thing as just using that child directly, but adds an extra layout pass and makes the code harder to read. If you need alignment, use `Align` or `Center`. If you need padding, use `Padding`. Using the right widget for the job makes intent clearer and keeps the widget tree lean.

**See also:** [Column](https://api.flutter.dev/flutter/widgets/Column-class.html) | [Row](https://api.flutter.dev/flutter/widgets/Row-class.html)

## Don't

```dart
Scaffold(
  body: Column(
    // Column with a single child is unnecessary
    children: [Text('I am the only child')],
  ),
)
```

## Do

```dart
Scaffold(
  // Use the child widget directly
  body: Text('I am the only child'),
)
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_single_child_in_multi_child_widgets: false
```
