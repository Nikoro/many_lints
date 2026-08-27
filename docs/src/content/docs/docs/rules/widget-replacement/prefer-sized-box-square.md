---
title: prefer_sized_box_square
description: "Use SizedBox.square when width and height are equal"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_sized_box_square
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `SizedBox` constructors where `width` and `height` are set to the same value. Flutter provides `SizedBox.square(dimension: ...)` as a cleaner way to express this intent.

## Why use this rule

`SizedBox(width: 48, height: 48)` makes the reader compare two numbers to work
out it is a square, and lets one of them drift during an edit.
`SizedBox.square(dimension: 48)` states it once. The quick fix collapses the two
arguments into `dimension:` and keeps everything else — `child`, `key`, and the
`const` keyword.

**See also:** [SizedBox.square](https://api.flutter.dev/flutter/widgets/SizedBox/SizedBox.square.html)

## Don't

```dart
// A square avatar placeholder.
SizedBox(
  width: 48,
  height: 48,
  child: const CircleAvatar(),
);
```

## Do

```dart
SizedBox.square(
  dimension: 48,
  child: const CircleAvatar(),
);
```

## Examples

### A square gap between items

```dart
// Don't
const SizedBox(width: 16, height: 16);

// Do
const SizedBox.square(dimension: 16);
```

### The same expression, not just the same literal

The two arguments are compared as source text, so a shared constant or a
computed value works as well as a number:

```dart
// Don't
const iconSize = 24.0;
SizedBox(width: iconSize, height: iconSize, child: const Icon(Icons.star));

// Do
SizedBox.square(dimension: iconSize, child: const Icon(Icons.star));
```

## Known limitations

**Both arguments must be present.** A `SizedBox` with only `width` or only
`height` is deliberately one-dimensional and is never reported:

```dart
// Not reported
const SizedBox(width: 16);
```

**Source text, not value.** Because the comparison is textual, `48` and `48.0`
look different and are not reported, and neither is `size` versus
`this.size` — even though each pair is the same number:

```dart
// Not reported — the two sources differ
SizedBox(width: 48, height: 48.0);
```

The flip side is that two *different* calls spelled identically —
`SizedBox(width: next(), height: next())` — are reported, and collapsing them
would call `next()` once instead of twice. Check the diff when the arguments
are not pure.

**Named constructors are skipped.** `SizedBox.square`, `SizedBox.shrink` and
`SizedBox.expand` are already the concise form.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_sized_box_square: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_sized_box_square: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_center_over_align`](/many_lints/docs/rules/widget-replacement/prefer-center-over-align/) — Use Center instead of Align when alignment is center.
- [`prefer_text_rich`](/many_lints/docs/rules/widget-replacement/prefer-text-rich/) — Use Text.rich instead of RichText for better accessibility.
- [`prefer_constrained_box_over_container`](/many_lints/docs/rules/widget-replacement/prefer-constrained-box-over-container/) — Use ConstrainedBox instead of Container when only constraints is set.
- [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/) — Use Border.fromBorderSide instead of Border.all for const support.
