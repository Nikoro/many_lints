---
title: avoid_flexible_outside_flex
description: "Only use Flexible and Expanded as direct children of Row, Column, or Flex"
sidebar:
  label: avoid_flexible_outside_flex
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags `Flexible` and `Expanded` widgets that are not direct children of a `Row`, `Column`, or `Flex`. These widgets rely on the flex layout protocol to work, so wrapping them inside other widgets like `Container` or `Padding` makes them silently do nothing.

## Why use this rule

When `Expanded` or `Flexible` is nested inside a non-flex parent, Flutter does not throw an error at build time -- the widget simply has no effect. This leads to confusing layouts where you think you are distributing space but nothing happens. Catching this at lint time saves you from staring at the widget tree wondering why your layout is broken.

**See also:** [Flexible](https://api.flutter.dev/flutter/widgets/Flexible-class.html) | [Row](https://api.flutter.dev/flutter/widgets/Row-class.html) | [Column](https://api.flutter.dev/flutter/widgets/Column-class.html)

## Don't

```dart
Column(
  children: [
    // Expanded is inside a Container, not directly in the Column
    Container(child: Expanded(child: Text('hello'))),

    // Flexible is inside a Center
    Center(child: Flexible(child: Text('hello'))),
  ],
)
```

## Do

```dart
Column(
  children: [
    // Expanded directly in a Row
    Row(children: [Expanded(child: Text('hello'))]),

    // Flexible directly in a Column
    Flexible(child: Text('hello')),
  ],
)
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_flexible_outside_flex: false
```
