---
title: prefer_container
description: "Replace sequences of nested widgets with a single Container"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_container
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags chains of 3 or more nested widgets that can all be replaced with a single `Container` widget. `Container` internally composes `Align`, `Padding`, `DecoratedBox`, `ConstrainedBox`, `Transform`, `ColoredBox`, `SizedBox`, and other layout widgets -- so nesting them individually is redundant.

:::note[Points the opposite way from the `prefer_*_over_container` rules]
This rule collapses **3 or more** nested layout widgets *into* a `Container`, while [`prefer_padding_over_container`](/many_lints/docs/rules/widget-replacement/prefer-padding-over-container/), [`prefer_align_over_container`](/many_lints/docs/rules/widget-replacement/prefer-align-over-container/), [`prefer_constrained_box_over_container`](/many_lints/docs/rules/widget-replacement/prefer-constrained-box-over-container/), and [`prefer_transform_over_container`](/many_lints/docs/rules/widget-replacement/prefer-transform-over-container/) replace a **single-parameter** `Container` with the specific widget.

The thresholds keep them from firing on the same code, but after further edits a fix from one rule can produce code the other flags. If that churn bothers you, enable only one direction.

The SDK's [`avoid_unnecessary_containers`](https://dart.dev/tools/linter-rules/avoid_unnecessary_containers) is a third, non-overlapping case: it removes a `Container` that has *no* parameters at all.
:::

## Why use this rule

Deeply nested single-purpose widgets make the widget tree harder to read and debug. When three or more of these widgets are stacked, collapsing them into a single `Container` reduces nesting, improves readability, and still gives you access to all the same properties. The rule only triggers when there are no conflicting parameters (e.g., two `Padding` widgets would conflict).

**See also:** [Container](https://api.flutter.dev/flutter/widgets/Container-class.html) | [DecoratedBox](https://api.flutter.dev/flutter/widgets/DecoratedBox-class.html) | [SizedBox](https://api.flutter.dev/flutter/widgets/SizedBox-class.html) | [Dart lint: avoid_unnecessary_containers](https://dart.dev/tools/linter-rules/avoid_unnecessary_containers)

## Don't

```dart
// Transform > Padding > Align can be replaced with Container
Transform(
  transform: Matrix4.identity(),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Align(alignment: Alignment.center, child: Text('Hello')),
  ),
);

// Padding > ColoredBox > SizedBox can be replaced with Container
Padding(
  padding: EdgeInsets.all(8),
  child: ColoredBox(
    color: Colors.red,
    child: SizedBox(width: 100, height: 50, child: Text('World')),
  ),
);
```

## Do

```dart
// Single Container combines all properties
Container(
  transform: Matrix4.identity(),
  padding: EdgeInsets.all(16),
  alignment: Alignment.center,
  child: Text('Hello'),
);

// Single Container with color and size
Container(
  padding: EdgeInsets.all(8),
  color: Colors.red,
  width: 100,
  height: 50,
  child: Text('World'),
);

// Only 2 nested widgets (below threshold) is fine
Padding(
  padding: EdgeInsets.all(8),
  child: Align(alignment: Alignment.center, child: Text('OK')),
);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_container: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  prefer_container:
    min_sequence: 4
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `min_sequence` | int | `3` | Minimum number of consecutive Container-compatible widgets in a nesting chain before the rule reports |

Raise it to only flag deeper nesting; lower it to `2` to catch every collapsible pair.

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
