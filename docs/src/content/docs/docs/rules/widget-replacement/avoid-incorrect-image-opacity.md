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

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_incorrect_image_opacity: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_incorrect_image_opacity: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/) — Use Border.fromBorderSide instead of Border.all for const support.
- [`avoid_expanded_as_spacer`](/many_lints/docs/rules/widget-replacement/avoid-expanded-as-spacer/) — Use Spacer instead of Expanded with an empty child.
- [`avoid_wrapping_in_padding`](/many_lints/docs/rules/widget-replacement/avoid-wrapping-in-padding/) — Avoid wrapping widgets that support padding in a Padding widget.
- [`prefer_align_over_container`](/many_lints/docs/rules/widget-replacement/prefer-align-over-container/) — Use Align instead of Container when only alignment is set.
