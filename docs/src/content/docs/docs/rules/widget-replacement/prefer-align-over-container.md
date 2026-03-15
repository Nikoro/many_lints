---
title: prefer_align_over_container
description: "Use Align instead of Container when only alignment is set"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_align_over_container
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Container` widgets that only use the `alignment` parameter (plus optional `key` and `child`). When `Container` is used solely for alignment, the `Align` widget is a lighter, more descriptive alternative.

## Why use this rule

`Container` is a convenience widget that composes many lower-level widgets internally. When you only need alignment, using `Align` directly avoids the overhead and makes the intent clearer. It also makes the widget tree easier to understand at a glance.

**See also:** [Align](https://api.flutter.dev/flutter/widgets/Align-class.html) | [Container](https://api.flutter.dev/flutter/widgets/Container-class.html)

## Don't

```dart
// Container with only alignment parameter
Container(alignment: Alignment.topLeft, child: Text('Hello'));

// Container with only alignment, no child
Container(alignment: Alignment.bottomRight);
```

## Do

```dart
// Use Align directly
Align(alignment: Alignment.topLeft, child: Text('Hello'));

Align(alignment: Alignment.bottomRight);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_align_over_container: false
```
