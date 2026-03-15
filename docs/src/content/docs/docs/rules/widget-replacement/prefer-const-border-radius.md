---
title: prefer_const_border_radius
description: "Use BorderRadius.all(Radius.circular()) for const support"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_const_border_radius
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Replacement</span>

Flags usages of `BorderRadius.circular()` which should be replaced with `BorderRadius.all(Radius.circular(...))`. The `BorderRadius.circular()` factory delegates to `BorderRadius.all(Radius.circular())` internally, but it cannot be made `const` because it is a factory constructor.

## Why use this rule

`BorderRadius.circular()` calls `BorderRadius.all(Radius.circular())` under the hood. Using the explicit form allows the entire expression to be `const`, which means the Dart compiler can canonicalize it at compile time. This avoids repeated allocations in build methods and is especially beneficial for border radii that never change.

**See also:** [BorderRadius](https://api.flutter.dev/flutter/painting/BorderRadius-class.html)

## Don't

```dart
// BorderRadius.circular cannot be const
final radius = BorderRadius.circular(8);

final radius2 = BorderRadius.circular(16.0);
```

## Do

```dart
// BorderRadius.all(Radius.circular()) supports const
final radius = BorderRadius.all(Radius.circular(8));

const radius2 = BorderRadius.all(Radius.circular(16.0));
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_const_border_radius: false
```
