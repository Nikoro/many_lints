---
title: prefer_container
description: "Replace sequences of nested widgets with a single Container"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_container
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags chains of 3 or more nested widgets that can all be replaced with a single `Container` widget. `Container` internally composes `Align`, `Padding`, `DecoratedBox`, `ConstrainedBox`, `Transform`, `ColoredBox`, `SizedBox`, and other layout widgets -- so nesting them individually is redundant.

## Why use this rule

Deeply nested single-purpose widgets make the widget tree harder to read and debug. When three or more of these widgets are stacked, collapsing them into a single `Container` reduces nesting, improves readability, and still gives you access to all the same properties. The rule only triggers when there are no conflicting parameters (e.g., two `Padding` widgets would conflict).

**See also:** [Container](https://api.flutter.dev/flutter/widgets/Container-class.html) | [DecoratedBox](https://api.flutter.dev/flutter/widgets/DecoratedBox-class.html) | [SizedBox](https://api.flutter.dev/flutter/widgets/SizedBox-class.html)

## Don't

```dart
// Transform > Padding > Align can be replaced with Container
Transform(
  transform: Matrix4.identity(),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Align(alignment: Alignment.center, child: Text('Hello')),
  ),
);

// Padding > ColoredBox > SizedBox can be replaced with Container
Padding(
  padding: EdgeInsets.all(8),
  child: ColoredBox(
    color: Colors.red,
    child: SizedBox(width: 100, height: 50, child: Text('World')),
  ),
);
```

## Do

```dart
// Single Container combines all properties
Container(
  transform: Matrix4.identity(),
  padding: EdgeInsets.all(16),
  alignment: Alignment.center,
  child: Text('Hello'),
);

// Single Container with color and size
Container(
  padding: EdgeInsets.all(8),
  color: Colors.red,
  width: 100,
  height: 50,
  child: Text('World'),
);

// Only 2 nested widgets (below threshold) is fine
Padding(
  padding: EdgeInsets.all(8),
  child: Align(alignment: Alignment.center, child: Text('OK')),
);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_container: false
```
