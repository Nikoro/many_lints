---
title: avoid_unnecessary_gesture_detector
description: "Remove GestureDetector widgets that have no event handlers"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_gesture_detector
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags `GestureDetector` widgets that have no event handler callbacks (no `onTap`, `onLongPress`, `onDoubleTap`, etc.). A GestureDetector without any handlers does nothing useful but still participates in hit testing, which can interfere with gesture recognition for widgets below it.

## Why use this rule

A handler-less `GestureDetector` is dead code that adds clutter to the widget tree. It may also unintentionally swallow touch events from child widgets, especially when `behavior` is set to `HitTestBehavior.opaque`. Removing it or adding the intended handler makes the code correct and easier to understand.

**See also:** [GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html) | [InkWell](https://api.flutter.dev/flutter/material/InkWell-class.html)

## Don't

```dart
// GestureDetector without any on* callback
GestureDetector(child: Text('hello'))

// Non-handler arguments like behavior don't count
GestureDetector(behavior: HitTestBehavior.opaque, child: Text('world'))
```

## Do

```dart
GestureDetector(onTap: () => print('tapped'), child: Text('hello'))

GestureDetector(
  onLongPress: () => print('long pressed'),
  onDoubleTap: () => print('double tapped'),
  child: Text('world'),
)
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_unnecessary_gesture_detector: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_gesture_detector: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
- [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/) — Only use Flexible and Expanded as direct children of Row, Column, or Flex.
