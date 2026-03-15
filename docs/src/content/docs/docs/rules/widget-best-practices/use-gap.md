---
title: use_gap
description: "Use Gap widget instead of SizedBox for spacing in multi-child widgets"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_gap
---

<span class="rule-badge rule-badge--version">v0.2.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule suggests replacing `SizedBox` and `Padding` spacers inside multi-child widgets (`Column`, `Row`, etc.) with the `Gap` widget from the `gap` package. `Gap` automatically picks the right axis based on its parent, so you never accidentally use `width` in a `Column` or `height` in a `Row`.

## Why use this rule

Using `SizedBox(height: 16)` for spacing works, but it is error-prone in `Row` (where you need `width` instead) and verbose in either case. `Gap(16)` is axis-aware, shorter, and makes the intent clearer: this is a spacer, not a box with specific dimensions. It also reduces bugs when refactoring a `Column` to a `Row` or vice versa.

**See also:** [gap package](https://pub.dev/packages/gap)

## Don't

```dart
Column(
  children: [
    Text('First'),
    SizedBox(height: 16),
    Text('Second'),
  ],
)

Row(
  children: [
    Text('Left'),
    SizedBox(width: 8),
    Text('Right'),
  ],
)
```

## Do

```dart
Column(
  children: [
    Text('First'),
    Gap(16),
    Text('Second'),
  ],
)

Row(
  children: [
    Text('Left'),
    Gap(8),
    Text('Right'),
  ],
)
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_gap: false
```
