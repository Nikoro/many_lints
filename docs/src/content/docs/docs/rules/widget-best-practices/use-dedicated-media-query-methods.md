---
title: use_dedicated_media_query_methods
description: "Use MediaQuery.sizeOf(context) instead of MediaQuery.of(context).size"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_dedicated_media_query_methods
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags calls like `MediaQuery.of(context).size` and suggests using the dedicated aspect methods like `MediaQuery.sizeOf(context)` instead. The dedicated methods subscribe only to the specific property you need, so your widget does not rebuild when unrelated MediaQuery properties change.

## Why use this rule

`MediaQuery.of(context)` subscribes to the entire `MediaQueryData`. That means your widget rebuilds whenever any media property changes -- orientation, padding, text scale, view insets, and more. If you only need `size`, using `MediaQuery.sizeOf(context)` ensures rebuilds happen only when the size actually changes. This is a significant performance win for widgets that appear in frequently-rebuilt subtrees.

**See also:** [MediaQuery](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)

## Don't

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Subscribes to ALL MediaQuery changes
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return SizedBox(width: size.width, height: size.height - padding.top);
  }
}
```

## Do

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Only rebuilds when size or padding changes
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return SizedBox(width: size.width, height: size.height - padding.top);
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_dedicated_media_query_methods: false
```
