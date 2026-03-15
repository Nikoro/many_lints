---
title: avoid_incorrect_image_opacity
description: "Use Image's opacity parameter instead of wrapping in Opacity"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_incorrect_image_opacity
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Opacity` widgets that wrap an `Image` widget as their child. The `Image` widget has a dedicated `opacity` parameter that is more efficient than wrapping it in a separate `Opacity` widget.

## Why use this rule

Wrapping an `Image` in an `Opacity` widget creates an additional layer in the rendering pipeline, which triggers an offscreen buffer (saveLayer). The `Image` widget's built-in `opacity` parameter applies opacity directly during painting, avoiding the extra compositing pass. This is both more performant and produces a flatter widget tree.

**See also:** [Image](https://api.flutter.dev/flutter/widgets/Image-class.html) | [Opacity](https://api.flutter.dev/flutter/widgets/Opacity-class.html)

## Don't

```dart
// Image wrapped in Opacity
Opacity(opacity: 0.5, child: Image.asset('assets/logo.png'));

// Image.network wrapped in Opacity
Opacity(
  opacity: 0.8,
  child: Image.network('https://example.com/image.png'),
);
```

## Do

```dart
// Use Image's opacity parameter directly
Image.asset(
  'assets/logo.png',
  opacity: const AlwaysStoppedAnimation(0.5),
);

Image.network(
  'https://example.com/image.png',
  opacity: const AlwaysStoppedAnimation(0.8),
);

// Opacity wrapping a non-Image widget is fine
Opacity(opacity: 0.5, child: Text('Hello'));
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_incorrect_image_opacity: false
```
