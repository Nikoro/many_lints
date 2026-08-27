---
title: prefer_padding_over_container
description: "Use Padding instead of Container when only padding or margin is set"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_padding_over_container
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags `Container` widgets that only use the `padding` or `margin` parameter (plus optional `key` and `child`). When `Container` is used solely for spacing, the `Padding` widget is a lighter, more descriptive alternative.

:::note[Points the opposite way from `prefer_container`]
This rule replaces a **single-parameter** `Container` with the specific widget, while [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) collapses **3 or more** nested layout widgets *into* a `Container`.

The thresholds keep them from firing on the same code, but after further edits a fix from one rule can produce code the other flags. If that churn bothers you, enable only one direction.

The SDK's [`avoid_unnecessary_containers`](https://dart.dev/tools/linter-rules/avoid_unnecessary_containers) is a third, non-overlapping case: it removes a `Container` that has *no* parameters at all.
:::

## Why use this rule

`Container` composes half a dozen widgets internally; when the only argument is
`padding` or `margin`, `Padding` does the same job in one render object. The
quick fix does the rewrite for you — it renames the constructor and, for a
`margin`, renames the argument too.

**See also:** [Padding](https://api.flutter.dev/flutter/widgets/Padding-class.html) | [Container](https://api.flutter.dev/flutter/widgets/Container-class.html)

## Don't

```dart
// A Container used purely to inset a label.
Container(padding: EdgeInsets.all(16), child: Text('Hello'));
```

## Do

```dart
Padding(padding: EdgeInsets.all(16), child: Text('Hello'));
```

## Examples

### `margin:` becomes `padding:`

On a `Container` with nothing else set, `margin` and `padding` render
identically — the margin has no decoration or colour to sit outside of. So the
fix renames the argument as it swaps the widget:

```dart
// Don't
Container(margin: EdgeInsets.all(16), child: Text('Hello'));

// Do
Padding(padding: EdgeInsets.all(16), child: Text('Hello'));
```

### No child is still reported

`Padding` takes an optional child too, so a childless spacer converts the same
way:

```dart
// Don't
Container(margin: EdgeInsets.symmetric(horizontal: 8));

// Do
Padding(padding: EdgeInsets.symmetric(horizontal: 8));
```

## Known limitations

**`padding` *and* `margin` together is not reported.** Those two are no longer
equivalent once both exist — the fix would have to merge them — so the rule
stays quiet:

```dart
// Not reported
Container(padding: EdgeInsets.all(8), margin: EdgeInsets.all(8));
```

**Any other argument stops it.** `width`, `color`, `decoration`, `alignment` —
one of them and `Container` is doing something `Padding` cannot:

```dart
// Not reported
Container(padding: EdgeInsets.all(8), width: 100, child: Text('Hello'));
```

`key` and `child` are the two exceptions; they do not count against the rule.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_padding_over_container: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_padding_over_container: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_container`](/many_lints/docs/rules/widget-replacement/prefer-container/) — **Opposing convention.** Replace sequences of nested widgets with a single Container.
- [`prefer_align_over_container`](/many_lints/docs/rules/widget-replacement/prefer-align-over-container/) — Use Align instead of Container when only alignment is set.
- [`prefer_constrained_box_over_container`](/many_lints/docs/rules/widget-replacement/prefer-constrained-box-over-container/) — Use ConstrainedBox instead of Container when only constraints is set.
- [`prefer_transform_over_container`](/many_lints/docs/rules/widget-replacement/prefer-transform-over-container/) — Use Transform instead of Container when only transform is set.
