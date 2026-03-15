---
title: prefer_sized_box_square
description: "Use SizedBox.square when width and height are equal"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_sized_box_square
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `SizedBox` constructors where `width` and `height` are set to the same value. Flutter provides `SizedBox.square(dimension: ...)` as a cleaner way to express this intent.

## Why use this rule

When width and height are identical, `SizedBox.square` communicates "this is a square" at a glance, whereas `SizedBox(width: 50, height: 50)` requires the reader to compare both values. The named constructor eliminates duplication and makes the code more self-documenting.

**See also:** [SizedBox.square](https://api.flutter.dev/flutter/widgets/SizedBox/SizedBox.square.html)

## Don't

```dart
// Both width and height are the same literal
SizedBox(width: 10, height: 10);

// Same double literal
SizedBox(width: 24.0, height: 24.0);

// Same variable reference
const size = 48.0;
SizedBox(width: size, height: size);

// With a child widget
SizedBox(width: 50, height: 50, child: Text('Hello'));
```

## Do

```dart
// Use SizedBox.square
SizedBox.square(dimension: 10);

// Different width and height is fine
SizedBox(width: 100, height: 50);

// Only width specified
SizedBox(width: 10);

// Only height specified
SizedBox(height: 10);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_sized_box_square: false
```
