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

`Spacer` exists for exactly this. `Expanded(child: SizedBox())` builds two
widgets to do what one does, and the reader has to work out that the empty box
is deliberate rather than a leftover. The quick fix swaps the whole expression
for a `Spacer`, carrying `flex` across.

**See also:** [Spacer](https://api.flutter.dev/flutter/widgets/Spacer-class.html) | [Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html)

## Don't

```dart
// Push the action button to the far end of the row.
Row(
  children: [
    const Text('Total'),
    const Expanded(child: SizedBox()),
    TextButton(onPressed: onPay, child: const Text('Pay')),
  ],
);
```

## Do

```dart
Row(
  children: [
    const Text('Total'),
    const Spacer(),
    TextButton(onPressed: onPay, child: const Text('Pay')),
  ],
);
```

## Examples

### An empty `Container` counts too

```dart
// Don't
Expanded(child: Container());

// Do
const Spacer();
```

### `flex` is carried across

Use it to split the leftover space unevenly:

```dart
// Don't — the gap after the title is twice the one before it
Row(
  children: [
    const Expanded(flex: 1, child: SizedBox()),
    const Text('Title'),
    const Expanded(flex: 2, child: SizedBox()),
  ],
);

// Do
Row(
  children: [
    const Spacer(),
    const Text('Title'),
    const Spacer(flex: 2),
  ],
);
```

`Spacer`'s `flex` defaults to `1`, so the first one can drop the argument.

### A `key` on the empty child does not save it

`key` is the one argument the rule tolerates on the child — a `SizedBox` that
carries only a key is still empty:

```dart
// Don't
const Expanded(child: SizedBox(key: ValueKey('gap')));

// Do
const Spacer();
```

The fix keeps a `key` written on the **`Expanded`**, and drops one written on
the child, since the child is what disappears:

```dart
// Don't
const Expanded(key: ValueKey('gap'), child: SizedBox());

// Do
const Spacer(key: ValueKey('gap'));
```

## Known limitations

**The child has to be genuinely empty.** A `SizedBox` with any argument other
than `key` is sizing something, and is left alone:

```dart
// Not reported — this is a fixed 24px gap, and `Spacer` cannot express it
Row(children: [const Text('A'), const SizedBox(width: 24), const Text('B')]);

// Not reported — the box has a size, so the Expanded is not just a spacer
Expanded(child: SizedBox(height: 40));
```

For fixed gaps like the first one, see
[`prefer_spacing`](/many_lints/docs/rules/widget-best-practices/prefer-spacing/)
and [`use_gap`](/many_lints/docs/rules/widget-best-practices/use-gap/).

**`Flexible` is not matched, only `Expanded`.** `Flexible(child: SizedBox())`
uses `FlexFit.loose`, which takes no space at all — it is a different (and
usually mistaken) thing, not a spacer.

**`Spacer` only works inside a `Flex`.** `Row`, `Column` and `Flex` are the only
valid parents; the rule does not check that, so a stray
`Expanded(child: SizedBox())` outside one will be reported and the rewrite will
throw at runtime. In practice `Expanded` has the same restriction, so such code
was already broken.

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
