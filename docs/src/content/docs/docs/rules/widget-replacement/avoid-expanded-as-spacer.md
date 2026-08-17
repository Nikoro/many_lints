---
title: avoid_expanded_as_spacer
description: "Use Spacer instead of Expanded with an empty child"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_expanded_as_spacer
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Expanded` widgets that wrap an empty `SizedBox` or `Container` as their child. This pattern is equivalent to using the `Spacer` widget, which is purpose-built for this exact use case.

## Why use this rule

Flutter provides the `Spacer` widget specifically for creating flexible space in `Row`, `Column`, and `Flex` layouts. Using `Expanded` with an empty child obscures the intent and adds an unnecessary widget to the tree. `Spacer` is clearer, more concise, and immediately communicates that the purpose is to fill available space.

**See also:** [Spacer](https://api.flutter.dev/flutter/widgets/Spacer-class.html) | [Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html)

## Don't

```dart
// Expanded with empty SizedBox
const Expanded(child: SizedBox());

// Expanded with empty Container
Expanded(child: Container());

// Expanded with flex and empty SizedBox
const Expanded(flex: 2, child: SizedBox());
```

## Do

```dart
// Use Spacer directly
const Spacer();

// Use Spacer with flex parameter
const Spacer(flex: 2);

// Expanded with a non-empty child is fine
const Expanded(child: Text('content'));
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_expanded_as_spacer: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_expanded_as_spacer: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_spacing`](/many_lints/docs/rules/widget-best-practices/prefer-spacing/) — Use the spacing argument on Row/Column instead of SizedBox spacers.
- [`use_gap`](/many_lints/docs/rules/widget-best-practices/use-gap/) — Use Gap widget instead of SizedBox for spacing in multi-child widgets.
- [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/) — Use Border.fromBorderSide instead of Border.all for const support.
- [`avoid_incorrect_image_opacity`](/many_lints/docs/rules/widget-replacement/avoid-incorrect-image-opacity/) — Use Image's opacity parameter instead of wrapping in Opacity.
