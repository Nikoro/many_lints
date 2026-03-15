---
title: prefer_center_over_align
description: "Use Center instead of Align when alignment is center"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_center_over_align
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Align` widgets that use `Alignment.center` (or omit the alignment parameter, which defaults to center). In these cases, the `Center` widget is a clearer and more idiomatic replacement.

## Why use this rule

`Center` is a specialized subclass of `Align` that always aligns to center. Using `Center` makes the intent immediately obvious and removes the redundant `alignment: Alignment.center` argument. If you omit `alignment` on `Align`, Flutter defaults to center anyway -- so you should just use `Center`.

**See also:** [Center](https://api.flutter.dev/flutter/widgets/Center-class.html) | [Align](https://api.flutter.dev/flutter/widgets/Align-class.html)

## Don't

```dart
// Align with explicit Alignment.center
Align(alignment: Alignment.center, child: Text('Hello'));

// Align without alignment defaults to center
Align(child: Text('World'));
```

## Do

```dart
// Use Center directly
Center(child: Text('Hello'));

Center(child: Text('World'));
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_center_over_align: false
```
