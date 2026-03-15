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

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_gesture_detector: false
```
