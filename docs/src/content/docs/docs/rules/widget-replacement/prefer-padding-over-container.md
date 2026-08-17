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

`Container` is a convenience widget that composes many lower-level widgets internally. When you only need padding or margin, using `Padding` directly avoids the overhead and makes the intent immediately clear. This also keeps the widget tree shallow and easier to read during debugging.

**See also:** [Padding](https://api.flutter.dev/flutter/widgets/Padding-class.html) | [Container](https://api.flutter.dev/flutter/widgets/Container-class.html)

## Don't

```dart
// Container with only margin parameter
Container(margin: EdgeInsets.all(16), child: Text('Hello'));

// Container with only margin, no child
Container(margin: EdgeInsets.symmetric(horizontal: 8));

// Container with only padding parameter
Container(padding: EdgeInsets.all(16), child: Text('Hello'));

// Container with only padding, no child
Container(padding: EdgeInsets.symmetric(vertical: 8));
```

## Do

```dart
// Use Padding directly
Padding(padding: EdgeInsets.all(16), child: Text('Hello'));

Padding(padding: EdgeInsets.symmetric(horizontal: 8));

Padding(padding: EdgeInsets.all(16), child: Text('Hello'));

Padding(padding: EdgeInsets.symmetric(vertical: 8));
```

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
