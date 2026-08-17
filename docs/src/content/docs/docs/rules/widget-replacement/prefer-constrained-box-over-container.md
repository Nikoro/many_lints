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

`Container` is a convenience widget that composes many lower-level widgets internally. When you only need constraints, using `ConstrainedBox` directly avoids the overhead and communicates your intent more clearly. It also keeps the widget tree shallow and easier to reason about.

**See also:** [ConstrainedBox](https://api.flutter.dev/flutter/widgets/ConstrainedBox-class.html) | [Container](https://api.flutter.dev/flutter/widgets/Container-class.html)

## Don't

```dart
// Container with only constraints parameter
Container(
  constraints: BoxConstraints(maxWidth: 200),
  child: Text('Hello'),
);

// Container with only constraints, no child
Container(constraints: BoxConstraints.tightFor(width: 100));
```

## Do

```dart
// Use ConstrainedBox directly
ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 200),
  child: Text('Hello'),
);

// Container with additional properties besides constraints is fine
Container(
  constraints: BoxConstraints(maxWidth: 200),
  padding: EdgeInsets.all(8),
  child: Text('Hello'),
);
```

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
