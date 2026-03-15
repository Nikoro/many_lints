---
title: prefer_correct_edge_insets_constructor
description: "Use the simplest EdgeInsets constructor for the given values."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_correct_edge_insets_constructor
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Flutter's `EdgeInsets` provides several constructors for different use cases: `all()`, `symmetric()`, `only()`, `zero`, and `fromLTRB()`. This rule detects when a more verbose constructor is used where a simpler one would suffice, such as using `EdgeInsets.fromLTRB(8, 8, 8, 8)` instead of `EdgeInsets.all(8)`.

## Why use this rule

Using the most specific constructor makes your intent clearer at a glance. `EdgeInsets.all(8)` immediately communicates uniform padding, while `EdgeInsets.fromLTRB(8, 8, 8, 8)` requires reading all four values to understand the pattern.

**See also:** [EdgeInsets](https://api.flutter.dev/flutter/painting/EdgeInsets-class.html)

## Don't

```dart
import 'package:flutter/painting.dart';

void example() {
  // Use EdgeInsets.all(8) instead
  final p1 = EdgeInsets.fromLTRB(8, 8, 8, 8);

  // Use EdgeInsets.symmetric(horizontal: 8) instead
  final p2 = EdgeInsets.fromLTRB(8, 0, 8, 0);

  // Use EdgeInsets.symmetric(horizontal: 8, vertical: 4) instead
  final p3 = EdgeInsets.fromLTRB(8, 4, 8, 4);

  // Use EdgeInsets.only(left: 8) instead
  final p4 = EdgeInsets.fromLTRB(8, 0, 0, 0);

  // Use EdgeInsets.symmetric(horizontal: 16) instead
  final p5 = EdgeInsets.only(left: 16, right: 16);

  // Use EdgeInsets.all(8) instead
  final p6 = EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8);

  // Use EdgeInsets.all(8) instead
  final p7 = EdgeInsets.symmetric(horizontal: 8, vertical: 8);

  // Use EdgeInsets.zero instead
  final p8 = EdgeInsets.all(0);
  final p9 = EdgeInsets.fromLTRB(0, 0, 0, 0);
}
```

## Do

```dart
import 'package:flutter/painting.dart';

void example() {
  final p1 = EdgeInsets.all(8);
  final p2 = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  final p3 = EdgeInsets.symmetric(horizontal: 16);
  final p4 = EdgeInsets.only(left: 8);
  final p5 = EdgeInsets.only(left: 8, top: 4);
  final p6 = EdgeInsets.zero;
  final p7 = EdgeInsets.fromLTRB(1, 2, 3, 4);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_correct_edge_insets_constructor: false
```
