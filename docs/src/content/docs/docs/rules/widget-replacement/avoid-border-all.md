---
title: avoid_border_all
description: "Use Border.fromBorderSide instead of Border.all for const support"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_border_all
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags usages of `Border.all()` which should be replaced with `Border.fromBorderSide(BorderSide(...))`. The `Border.all()` factory delegates to `Border.fromBorderSide()` internally, but it cannot be made `const` because it is a factory constructor.

## Why use this rule

`Border.all()` calls `Border.fromBorderSide()` under the hood, so using `Border.fromBorderSide(BorderSide(...))` directly allows the entire expression to be `const`. Const objects are canonicalized at compile time, which reduces allocations and improves performance — especially in build methods that run frequently.

**See also:** [Border](https://api.flutter.dev/flutter/painting/Border-class.html) | [Dart lint: prefer_const_constructors](https://dart.dev/tools/linter-rules/prefer_const_constructors)

## Don't

```dart
// Border.all() cannot be const
final border1 = Border.all();

// Border.all() with arguments
final border2 = Border.all(
  color: const Color(0xFF3355AA),
  width: 2.5,
  style: BorderStyle.solid,
);
```

## Do

```dart
// Border.fromBorderSide() supports const
final border1 = const Border.fromBorderSide(BorderSide());

final border2 = const Border.fromBorderSide(
  BorderSide(color: Color(0xFF3355AA), width: 2.5, style: BorderStyle.solid),
);
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_border_all: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_border_all: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
