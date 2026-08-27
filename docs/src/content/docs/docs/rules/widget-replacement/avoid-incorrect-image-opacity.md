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

`Opacity` forces the compositor to paint its subtree into an offscreen buffer
(`saveLayer`) and blend that buffer back — expensive, and worse the larger the
image. `Image` takes an `opacity` animation of its own and applies it while
painting the pixels, with no extra layer.

The quick fix moves the value inward, wrapping it in an
`AlwaysStoppedAnimation` because `Image.opacity` takes an
`Animation<double>`, not a plain double.

**See also:** [Image.opacity](https://api.flutter.dev/flutter/widgets/Image/opacity.html) | [Opacity](https://api.flutter.dev/flutter/widgets/Opacity-class.html)

## Don't

```dart
// A watermark faded behind the page content.
Opacity(
  opacity: 0.15,
  child: Image.asset('assets/watermark.png'),
);
```

## Do

```dart
Image.asset(
  'assets/watermark.png',
  opacity: const AlwaysStoppedAnimation(0.15),
);
```

## Examples

### Every `Image` constructor counts

`Image.network`, `Image.file`, `Image.memory` and the unnamed `Image(...)` all
take `opacity`:

```dart
// Don't
Opacity(
  opacity: 0.8,
  child: Image.network('https://example.com/avatar.png'),
);

// Do
Image.network(
  'https://example.com/avatar.png',
  opacity: const AlwaysStoppedAnimation(0.8),
);
```

### An animated fade goes in directly

If the value already comes from an `Animation<double>`, there is no wrapper to
add — pass it straight through:

```dart
// Don't — Opacity forces a layer on every frame of the fade
Opacity(
  opacity: fadeController.value,
  child: Image.asset('assets/logo.png'),
);

// Do — no saveLayer, and the Image repaints without rebuilding
Image.asset('assets/logo.png', opacity: fadeController);
```

The quick fix would write `AlwaysStoppedAnimation(fadeController.value)` here,
which is correct but freezes the fade at the current frame. Passing the
animation itself is the better hand edit.

### Anything but an `Image` is fine

```dart
// Not reported — Text has no opacity parameter
Opacity(opacity: 0.5, child: const Text('Dimmed'));
```

## Known limitations

**The `Image` must be the direct child.** `Opacity > Padding > Image` is not
reported, because the padding would have to move too.

**A subclass of `Image` is reported as well.** The child is matched by
assignability, so your own `class CachedImage extends Image` is caught — and it
does inherit `opacity`, so the rewrite holds.

**An `Image` that already sets `opacity` is skipped by the fix.** The rule still
reports the redundant `Opacity`, but combining two opacity sources is a
decision, so nothing is offered automatically.

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
