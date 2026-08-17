---
title: prefer_text_rich
description: "Use Text.rich instead of RichText for better accessibility"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_text_rich
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags usages of `RichText` which should be replaced with `Text.rich`. `RichText` does not respect `MediaQuery` text scaling by default, which can break accessibility for users who configure larger text sizes.

## Why use this rule

`Text.rich` inherits the default `TextStyle` from the nearest `DefaultTextStyle` ancestor and automatically applies text scaling from `MediaQuery`. `RichText` does neither — it requires you to pass these explicitly. Using `Text.rich` gives you correct accessibility behavior out of the box and is the recommended approach for rich text in Flutter.

**See also:** [Text.rich](https://api.flutter.dev/flutter/widgets/Text/Text.rich.html) | [RichText](https://api.flutter.dev/flutter/widgets/RichText-class.html)

## Don't

```dart
// RichText does not handle text scaling
RichText(
  text: TextSpan(
    text: 'Total: ',
    children: [
      TextSpan(
        text: '42 USD',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(text: ' incl. VAT'),
    ],
  ),
);

// Even simple RichText should use Text.rich
RichText(text: TextSpan(text: 'Simple text'));
```

## Do

```dart
// Text.rich handles text scaling and inherits default style
Text.rich(
  TextSpan(
    text: 'Total: ',
    children: [
      TextSpan(
        text: '42 USD',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(text: ' incl. VAT'),
    ],
  ),
);

Text.rich(TextSpan(text: 'Simple text'));
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`prefer_text_rich: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_text_rich: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_center_over_align`](/many_lints/docs/rules/widget-replacement/prefer-center-over-align/) — Use Center instead of Align when alignment is center.
- [`prefer_sized_box_square`](/many_lints/docs/rules/widget-replacement/prefer-sized-box-square/) — Use SizedBox.square when width and height are equal.
- [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/) — Use Border.fromBorderSide instead of Border.all for const support.
- [`avoid_expanded_as_spacer`](/many_lints/docs/rules/widget-replacement/avoid-expanded-as-spacer/) — Use Spacer instead of Expanded with an empty child.
