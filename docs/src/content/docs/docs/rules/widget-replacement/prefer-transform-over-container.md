---
title: prefer_transform_over_container
description: "Use Transform instead of Container when only transform is set"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_transform_over_container
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Container` widgets that only use the `transform` parameter (plus optional `key` and `child`). When `Container` is used solely for a transform, the `Transform` widget is a lighter, more descriptive alternative.

:::note[Points the opposite way from `prefer_container`]
This rule replaces a **single-parameter** `Container` with the specific widget, while [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) collapses **3 or more** nested layout widgets *into* a `Container`.

The thresholds keep them from firing on the same code, but after further edits a fix from one rule can produce code the other flags. If that churn bothers you, enable only one direction.

The SDK's [`avoid_unnecessary_containers`](https://dart.dev/tools/linter-rules/avoid_unnecessary_containers) is a third, non-overlapping case: it removes a `Container` that has *no* parameters at all.
:::

## Why use this rule

With only `transform` set, the `Container` collapses to a single `Transform`.
Writing `Transform` directly also puts the named constructors in reach —
`Transform.rotate`, `Transform.scale`, `Transform.translate` — which are far
easier to read than a hand-built `Matrix4`. The quick fix does the rename; the
matrix moves across as-is.

**See also:** [Transform](https://api.flutter.dev/flutter/widgets/Transform-class.html) | [Matrix4](https://api.flutter.dev/vector_math/Matrix4-class.html)

## Don't

```dart
// A "SALE" ribbon tilted across a product tile.
Container(
  transform: Matrix4.rotationZ(-math.pi / 12),
  child: const Text('SALE'),
);
```

## Do

```dart
Transform(
  transform: Matrix4.rotationZ(-math.pi / 12),
  child: const Text('SALE'),
);
```

## Examples

### Reach for the named constructor

Once it is a `Transform`, most cases have a constructor that spells out the
intent — and unlike the raw matrix, they take an `alignment`:

```dart
// Don't
Container(
  transform: Matrix4.rotationZ(-math.pi / 12),
  child: const Text('SALE'),
);

// Do — rotates about the centre rather than the top-left corner
Transform.rotate(
  angle: -math.pi / 12,
  child: const Text('SALE'),
);
```

The quick fix will not do this step for you; it only renames the widget.

### `key` and `child` do not count

```dart
// Don't
Container(
  key: const ValueKey('ribbon'),
  transform: Matrix4.rotationZ(math.pi / 4),
  child: const Text('Rotated'),
);

// Do
Transform(
  key: const ValueKey('ribbon'),
  transform: Matrix4.rotationZ(math.pi / 4),
  child: const Text('Rotated'),
);
```

## Known limitations

**Any other argument silences it,** including `transformAlignment` — which is
the argument you would reach for next:

```dart
// Not reported: transformAlignment has no equivalent on a plain Transform,
// which takes `origin` and `alignment` instead.
Container(
  transform: Matrix4.rotationZ(math.pi / 4),
  transformAlignment: Alignment.center,
  child: const Text('Rotated'),
);
```

The equivalent is `Transform(transform: …, alignment: Alignment.center, …)`, but
that is a rename plus an argument rename, so the rule leaves it alone.

**A transform does not affect layout.** Both widgets paint the transformed
child while laying it out untransformed, so the rewrite changes nothing about
the render — it is purely a simplification.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_transform_over_container: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_transform_over_container: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) — **Opposing convention.** Replace sequences of nested widgets with a single Container.
- [`prefer_align_over_container`](/many_lints/docs/rules/widget-replacement/prefer-align-over-container/) — Use Align instead of Container when only alignment is set.
- [`prefer_constrained_box_over_container`](/many_lints/docs/rules/widget-replacement/prefer-constrained-box-over-container/) — Use ConstrainedBox instead of Container when only constraints is set.
- [`prefer_padding_over_container`](/many_lints/docs/rules/widget-replacement/prefer-padding-over-container/) — Use Padding instead of Container when only padding or margin is set.
