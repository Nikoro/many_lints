---
title: prefer_center_over_align
description: "Use Center instead of Align when alignment is center"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_center_over_align
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Align` widgets that use `Alignment.center` (or omit the alignment parameter, which defaults to center). In these cases, the `Center` widget is a clearer and more idiomatic replacement.

## Why use this rule

`Center` *is* an `Align` — a subclass that hard-codes `Alignment.center`. Using
it drops an argument and makes the intent readable at a glance in a deep tree.
The quick fix renames the widget and deletes the redundant `alignment:`.

**See also:** [Center](https://api.flutter.dev/flutter/widgets/Center-class.html) | [Align](https://api.flutter.dev/flutter/widgets/Align-class.html)

## Don't

```dart
// A loading spinner in the middle of the page.
Align(
  alignment: Alignment.center,
  child: const CircularProgressIndicator(),
);
```

## Do

```dart
Center(child: const CircularProgressIndicator());
```

## Examples

### An `Align` with no alignment at all

`Align`'s `alignment` defaults to `Alignment.center`, so omitting it is the same
widget written less clearly. It is reported too:

```dart
// Don't
Align(child: const Text('Centred'));

// Do
Center(child: const Text('Centred'));
```

### Alignment written as coordinates

`Alignment(0, 0)` is the centre, so a literal spelled that way is reported as
well:

```dart
// Don't
Align(alignment: const Alignment(0, 0), child: const Text('Centred'));

// Do
Center(child: const Text('Centred'));
```

Only exact zeros count — `Alignment(0.0, 0.1)` is not centre and is not
reported.

### Any other alignment is fine

```dart
// Not reported
Align(alignment: Alignment.bottomRight, child: const Text('Corner'));
```

## Known limitations

**`widthFactor` and `heightFactor` are carried, not dropped.** `Center` declares
both, so an `Align` using them still converts cleanly:

```dart
// Don't
Align(
  alignment: Alignment.center,
  widthFactor: 2,
  child: const Text('Wide'),
);

// Do
Center(widthFactor: 2, child: const Text('Wide'));
```

**Only a literal is recognised.** An alignment behind a variable or a getter is
opaque to the rule, even when it holds the centre:

```dart
// Not reported
const spot = Alignment.center;
Align(alignment: spot, child: const Text('Centred'));
```

**Any `X.center` is matched, not just `Alignment.center`.**
`AlignmentDirectional.center` is the same point, so it converts cleanly — but so
would a `center` constant on some unrelated class of your own, which would not.
That shape is rare enough that the rule does not guard against it; if you hit
it, silence the line with
`// ignore: many_lints/prefer_center_over_align`.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_center_over_align: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_center_over_align: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_sized_box_square`](/many_lints/docs/rules/widget-replacement/prefer-sized-box-square/) — Use SizedBox.square when width and height are equal.
- [`prefer_text_rich`](/many_lints/docs/rules/widget-replacement/prefer-text-rich/) — Use Text.rich instead of RichText for better accessibility.
- [`prefer_align_over_container`](/many_lints/docs/rules/widget-replacement/prefer-align-over-container/) — Use Align instead of Container when only alignment is set.
- [`avoid_border_all`](/many_lints/docs/rules/widget-replacement/avoid-border-all/) — Use Border.fromBorderSide instead of Border.all for const support.
