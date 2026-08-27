---
title: prefer_align_over_container
description: "Use Align instead of Container when only alignment is set"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_align_over_container
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Container` widgets that only use the `alignment` parameter (plus optional `key` and `child`). When `Container` is used solely for alignment, the `Align` widget is a lighter, more descriptive alternative.

:::note[Points the opposite way from `prefer_container`]
This rule replaces a **single-parameter** `Container` with the specific widget, while [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) collapses **3 or more** nested layout widgets *into* a `Container`.

The thresholds keep them from firing on the same code, but after further edits a fix from one rule can produce code the other flags. If that churn bothers you, enable only one direction.

The SDK's [`avoid_unnecessary_containers`](https://dart.dev/tools/linter-rules/avoid_unnecessary_containers) is a third, non-overlapping case: it removes a `Container` that has *no* parameters at all.
:::

## Why use this rule

A `Container` builds up to seven render objects depending on which arguments it
got. With only `alignment` set, exactly one of them does anything, and that one
is `Align`. Naming it directly says what the widget is for. The quick fix is a
rename — `Container` becomes `Align` and the arguments stay put.

**See also:** [Align](https://api.flutter.dev/flutter/widgets/Align-class.html) | [Container](https://api.flutter.dev/flutter/widgets/Container-class.html)

## Don't

```dart
// A badge pinned to the corner of a card.
Container(
  alignment: Alignment.topRight,
  child: const Icon(Icons.star),
);
```

## Do

```dart
Align(
  alignment: Alignment.topRight,
  child: const Icon(Icons.star),
);
```

## Examples

### Aligning inside a fixed-size parent

`Align` expands to fill its parent and places the child within it, exactly as
the `Container` did:

```dart
// Don't
SizedBox(
  height: 120,
  child: Container(
    alignment: Alignment.bottomCenter,
    child: const Text('Caption'),
  ),
);

// Do
SizedBox(
  height: 120,
  child: Align(
    alignment: Alignment.bottomCenter,
    child: const Text('Caption'),
  ),
);
```

### `key` and `child` do not count

They exist on both widgets, so a `Container` carrying them plus `alignment` is
still reported:

```dart
// Don't
Container(
  key: const ValueKey('badge'),
  alignment: Alignment.centerLeft,
  child: const Text('New'),
);

// Do
Align(
  key: const ValueKey('badge'),
  alignment: Alignment.centerLeft,
  child: const Text('New'),
);
```

### Centre alignment chains into another rule

Rewriting to `Align(alignment: Alignment.center, …)` is then reported by
[`prefer_center_over_align`](/many_lints/docs/rules/widget-replacement/prefer-center-over-align/),
which wants `Center`. Go straight there:

```dart
// Don't
Container(alignment: Alignment.center, child: const Text('Hi'));

// Do — skip the intermediate Align
Center(child: const Text('Hi'));
```

## Known limitations

**Any other argument silences it.** One `padding`, `color`, `width` or
`decoration` and the `Container` is doing work `Align` cannot:

```dart
// Not reported — the colour has nowhere to go on an Align
Container(
  alignment: Alignment.topLeft,
  color: const Color(0xFFEEEEEE),
  child: const Text('Hello'),
);
```

**Only a direct `Container(...)` is matched.** A factory or helper that returns
a `Container` is not looked through.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_align_over_container: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_align_over_container: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) — **Opposing convention.** Replace sequences of nested widgets with a single Container.
- [`prefer_constrained_box_over_container`](/many_lints/docs/rules/widget-replacement/prefer-constrained-box-over-container/) — Use ConstrainedBox instead of Container when only constraints is set.
- [`prefer_padding_over_container`](/many_lints/docs/rules/widget-replacement/prefer-padding-over-container/) — Use Padding instead of Container when only padding or margin is set.
- [`prefer_transform_over_container`](/many_lints/docs/rules/widget-replacement/prefer-transform-over-container/) — Use Transform instead of Container when only transform is set.
