---
title: prefer_constrained_box_over_container
description: "Use ConstrainedBox instead of Container when only constraints is set"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_constrained_box_over_container
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Container` widgets that only use the `constraints` parameter (plus optional `key` and `child`). When `Container` is used solely for constraints, the `ConstrainedBox` widget is a lighter, more descriptive alternative.

:::note[Points the opposite way from `prefer_container`]
This rule replaces a **single-parameter** `Container` with the specific widget, while [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) collapses **3 or more** nested layout widgets *into* a `Container`.

The thresholds keep them from firing on the same code, but after further edits a fix from one rule can produce code the other flags. If that churn bothers you, enable only one direction.

The SDK's [`avoid_unnecessary_containers`](https://dart.dev/tools/linter-rules/avoid_unnecessary_containers) is a third, non-overlapping case: it removes a `Container` that has *no* parameters at all.
:::

## Why use this rule

With only `constraints` set, the single render object a `Container` produces is
a `ConstrainedBox`. Writing it directly is one widget instead of a composition,
and it reads as what it is. The quick fix renames the constructor; the
`constraints:` argument moves across unchanged.

**See also:** [ConstrainedBox](https://api.flutter.dev/flutter/widgets/ConstrainedBox-class.html) | [BoxConstraints](https://api.flutter.dev/flutter/rendering/BoxConstraints-class.html)

## Don't

```dart
// Cap how wide a label is allowed to grow.
Container(
  constraints: const BoxConstraints(maxWidth: 200),
  child: const Text('A long product name that should wrap'),
);
```

## Do

```dart
ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 200),
  child: const Text('A long product name that should wrap'),
);
```

## Examples

### A minimum tap target

```dart
// Don't
Container(
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  child: const Icon(Icons.close),
);

// Do
ConstrainedBox(
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  child: const Icon(Icons.close),
);
```

### No child is still reported

```dart
// Don't
Container(constraints: BoxConstraints.tightFor(width: 100));

// Do
ConstrainedBox(constraints: BoxConstraints.tightFor(width: 100));
```

### Consider `SizedBox` for a tight constraint

If the constraint is tight in both axes, `SizedBox` says it in fewer words:

```dart
// Reported, and correct as far as this rule goes
ConstrainedBox(
  constraints: const BoxConstraints.tightFor(width: 100, height: 100),
  child: child,
);

// Clearer still — and then
// `prefer_sized_box_square` will suggest SizedBox.square(dimension: 100)
SizedBox(width: 100, height: 100, child: child);
```

## Known limitations

**`width:`/`height:` on a `Container` are not `constraints:`.** They are a
separate pair of arguments, so this rule does not see them:

```dart
// Not reported by this rule
Container(width: 100, height: 100, child: child);
```

**Any other argument silences it.** `padding`, `color`, `alignment`,
`decoration` — one of them and the `Container` is doing more than constraining:

```dart
// Not reported
Container(
  constraints: const BoxConstraints(maxWidth: 200),
  padding: const EdgeInsets.all(8),
  child: const Text('Hello'),
);
```

`key` and `child` are the exceptions; neither counts against the rule.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_constrained_box_over_container: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_constrained_box_over_container: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) — **Opposing convention.** Replace sequences of nested widgets with a single Container.
- [`prefer_align_over_container`](/many_lints/docs/rules/widget-replacement/prefer-align-over-container/) — Use Align instead of Container when only alignment is set.
- [`prefer_padding_over_container`](/many_lints/docs/rules/widget-replacement/prefer-padding-over-container/) — Use Padding instead of Container when only padding or margin is set.
- [`prefer_transform_over_container`](/many_lints/docs/rules/widget-replacement/prefer-transform-over-container/) — Use Transform instead of Container when only transform is set.
