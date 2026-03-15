---
title: use_closest_build_context
description: "Use the inner BuildContext from builder callbacks, not the outer one"
sidebar:
  label: use_closest_build_context
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
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

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_closest_build_context: false
```
