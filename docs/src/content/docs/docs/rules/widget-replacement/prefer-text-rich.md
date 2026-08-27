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

`RichText` is the raw widget: `textScaler` defaults to `TextScaler.noScaling`,
and it inherits nothing from `DefaultTextStyle`. Text written with it stays the
same size when the user raises the system font scale, and ignores whatever style
the surrounding theme set.

`Text.rich` is a thin wrapper that reads both from context. It is the same
`InlineSpan` tree, so the change is mechanical — the quick fix moves the `text:`
argument to the first positional slot and carries the rest.

**See also:** [Text.rich](https://api.flutter.dev/flutter/widgets/Text/Text.rich.html) | [RichText](https://api.flutter.dev/flutter/widgets/RichText-class.html)

## Don't

```dart
// A price line that does not grow with the user's text-size setting.
RichText(
  text: TextSpan(
    text: 'Total: ',
    children: [
      TextSpan(text: '42 USD', style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: ' incl. VAT'),
    ],
  ),
);
```

## Do

```dart
Text.rich(
  TextSpan(
    text: 'Total: ',
    children: [
      TextSpan(text: '42 USD', style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: ' incl. VAT'),
    ],
  ),
);
```

Note what the rewrite also fixes: the un-styled spans now inherit the ambient
`DefaultTextStyle`, where under `RichText` they fell back to the framework
default.

## Examples

### Other arguments carry across

`textAlign`, `maxLines`, `overflow`, `softWrap`, `strutStyle` and `locale` are
all named the same on both widgets:

```dart
// Don't
RichText(
  text: TextSpan(text: 'A very long line of body copy'),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
);

// Do
Text.rich(
  TextSpan(text: 'A very long line of body copy'),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
);
```

### Set the base style once

Because `Text.rich` inherits, the outer `TextSpan` usually stops needing a style
at all:

```dart
// Don't — every span has to name the style RichText will not supply
RichText(
  text: TextSpan(
    style: Theme.of(context).textTheme.bodyMedium,
    text: 'Read our ',
    children: [
      TextSpan(text: 'terms', style: const TextStyle(decoration: TextDecoration.underline)),
    ],
  ),
);

// Do — bodyMedium comes from the theme via DefaultTextStyle
Text.rich(
  TextSpan(
    text: 'Read our ',
    children: [
      TextSpan(text: 'terms', style: const TextStyle(decoration: TextDecoration.underline)),
    ],
  ),
);
```

## Known limitations

**`textDirection` behaves differently.** `RichText` requires either an explicit
`textDirection` or an ambient `Directionality`. `Text.rich` always falls back to
`Directionality`, so an explicit argument the fix carries over is usually
redundant afterwards and can be deleted.

**`selectionRegistrar` has no `Text.rich` equivalent.** It exists only on
`RichText`; the fix will copy it and the result will not compile. Wrap a
`Text.rich` in a `SelectionArea` instead, or keep the `RichText` and silence the
line with `// ignore: many_lints/prefer_text_rich`.

**`textScaleFactor` is deprecated on both.** If the code you are converting
passes it, replace it with `textScaler:` at the same time.

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
