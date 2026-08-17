---
title: use_closest_build_context
description: "Use the inner BuildContext from builder callbacks, not the outer one"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_closest_build_context
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule catches cases where an outer `BuildContext` is used inside a nested builder callback (`Builder`, `LayoutBuilder`, etc.) that provides its own context. This commonly happens when the inner parameter is renamed to `_` because it was previously unused, and then the outer `context` is accidentally referenced.

## Why use this rule

Using the wrong `BuildContext` can cause lookups like `Theme.of(context)` or `Navigator.of(context)` to find the wrong ancestor widget. For example, inside a `Builder` the outer context does not reflect widgets introduced by the `Builder` itself. This leads to subtle bugs where your theme, navigator, or scaffold operations target the wrong part of the widget tree.

**See also:** [BuildContext](https://api.flutter.dev/flutter/widgets/BuildContext-class.html)

## Don't

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (_) {
        // Uses the outer context instead of the Builder's own context
        return _buildChild(context);
      },
    );
  }
}
```

## Do

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Uses the Builder's own context
        return _buildChild(context);
      },
    );
  }
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`use_closest_build_context: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  use_closest_build_context: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`never_discard_build_context`](/many_lints/docs/rules/widget-best-practices/never-discard-build-context/) — Don't discard a BuildContext parameter with a wildcard.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`avoid_passing_build_context_to_blocs`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-build-context-to-blocs/) — Prevent passing BuildContext to Bloc or Cubit classes.
- [`avoid_too_many_widgets_per_build`](/many_lints/docs/rules/widget-best-practices/avoid-too-many-widgets-per-build/) — Keep one build method within a widget budget.
