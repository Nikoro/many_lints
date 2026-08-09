---
title: check_for_equals_in_render_object_setters
description: "Compare before marking a RenderObject dirty"
sidebar:
  label: check_for_equals_in_render_object_setters
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags a `RenderObject` setter that calls `markNeedsLayout` or `markNeedsPaint` without first checking whether the value actually changed.

## Why use this rule

`updateRenderObject` runs on every rebuild and assigns **every** property, whether or not it differs. A setter that unconditionally marks the object dirty therefore turns each rebuild into a full relayout or repaint of that subtree — even when nothing about it changed.

At best that is wasted frames on a hot path. When the layout pass itself causes another rebuild, the two feed each other and the app stops rendering entirely.

The convention in Flutter's own render objects is an early return: compare first, and only then assign and mark dirty.

**See also:** [Flutter: RenderObject](https://api.flutter.dev/flutter/rendering/RenderObject-class.html), [RenderObjectWidget.updateRenderObject](https://api.flutter.dev/flutter/widgets/RenderObjectWidget/updateRenderObject.html)

## Don't

```dart
class MyRender extends RenderBox {
  Color _color;

  set color(Color value) {
    _color = value;
    markNeedsPaint();   // repaints even when the color is unchanged
  }
}
```

## Do

```dart
class MyRender extends RenderBox {
  Color _color;

  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }
}
```

The wrapping form works too:

```dart
set color(Color value) {
  if (_color != value) {
    _color = value;
    markNeedsPaint();
  }
}
```

## Known limitations

The guard detection is deliberately loose: **any** `==`, `!=` or `identical` call in the setter body counts. A false positive on a setter that is in fact guarded would be far more annoying than missing an exotic shape, so the rule prefers to stay quiet.

Only setters that call a mark-dirty method are considered — a setter that merely assigns has nothing to guard against. The recognised methods are `markNeedsLayout`, `markNeedsPaint`, `markNeedsCompositingBitsUpdate`, `markNeedsSemanticsUpdate` and `markNeedsLayoutForSizedByParentChange`; a project wrapper can be added with `additional_methods`.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      check_for_equals_in_render_object_setters: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  check_for_equals_in_render_object_setters:
    additional_methods: [markNeedsCustomPass]
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `additional_methods` | list of strings | `[]` | Extra methods treated as marking the render object dirty |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
