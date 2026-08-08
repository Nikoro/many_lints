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

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_constrained_box_over_container: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
