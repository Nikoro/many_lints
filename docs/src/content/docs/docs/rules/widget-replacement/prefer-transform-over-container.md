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

## Why use this rule

`Container` is a convenience widget that composes many lower-level widgets internally. When you only need a matrix transform, using `Transform` directly avoids the overhead and clearly communicates your intent. It also gives you access to Transform's named constructors like `Transform.rotate` and `Transform.scale`.

**See also:** [Transform](https://api.flutter.dev/flutter/widgets/Transform-class.html) | [Container](https://api.flutter.dev/flutter/widgets/Container-class.html)

## Don't

```dart
// Container with only transform parameter
Container(
  transform: Matrix4.skewY(0.3)..rotateZ(-math.pi / 12.0),
  child: const Text('Skewed'),
);

// Container with only transform and key
Container(
  key: const ValueKey('rotated'),
  transform: Matrix4.rotationZ(math.pi / 4),
  child: const Text('Rotated'),
);
```

## Do

```dart
// Use Transform directly
Transform(
  transform: Matrix4.skewY(0.3)..rotateZ(-math.pi / 12.0),
  child: const Text('Skewed'),
);

// Container with transform and other parameters is fine
Container(
  transform: Matrix4.rotationZ(math.pi / 4),
  alignment: Alignment.topRight,
  child: const Text('Rotated with alignment'),
);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_transform_over_container: false
```
