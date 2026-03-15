---
title: avoid_wrapping_in_padding
description: "Avoid wrapping widgets that support padding in a Padding widget"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_wrapping_in_padding
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Padding` widgets whose child already supports a `padding` parameter (such as `Container`, `Card`, `ListView`, etc.). Instead of wrapping in `Padding`, you should pass padding directly to the child widget.

## Why use this rule

Many Flutter widgets accept a `padding` parameter in their constructor. Wrapping them in a `Padding` widget adds an unnecessary layer to the widget tree when the same effect can be achieved by passing `padding` directly to the child. This keeps the tree flatter, reduces nesting, and makes the code easier to read.

**See also:** [Padding](https://api.flutter.dev/flutter/widgets/Padding-class.html) | [Container](https://api.flutter.dev/flutter/widgets/Container-class.html)

## Don't

```dart
// Container supports padding, no need to wrap in Padding
Padding(
  padding: EdgeInsets.all(16),
  child: Container(child: Text('Hello')),
);

// Card supports padding
Padding(
  padding: EdgeInsets.symmetric(horizontal: 12),
  child: Card(child: Text('Card content')),
);
```

## Do

```dart
// Pass padding directly to Container
Container(padding: EdgeInsets.all(16), child: Text('Hello'));

// Padding wrapping a widget that doesn't support padding is fine
Padding(padding: EdgeInsets.all(8), child: Text('Hello'));

// Container already has its own padding set -- wrapping is acceptable
Padding(
  padding: EdgeInsets.all(8),
  child: Container(padding: EdgeInsets.all(4), child: Text('Hello')),
);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_wrapping_in_padding: false
```
