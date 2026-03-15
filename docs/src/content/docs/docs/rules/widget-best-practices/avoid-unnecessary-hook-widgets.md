---
title: avoid_unnecessary_hook_widgets
description: "Don't extend HookWidget if you never call any hooks"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_hook_widgets
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule detects `HookWidget` subclasses whose `build` method does not call any hooks (`useState`, `useMemoized`, `useEffect`, etc.). If no hooks are used, the widget should be a plain `StatelessWidget` instead.

## Why use this rule

`HookWidget` adds a hook management layer on top of the standard widget lifecycle. If you never call any hooks, that layer is pure overhead. Switching to `StatelessWidget` removes the dependency on `flutter_hooks`, makes the widget simpler, and signals to readers that no hook-based state management is happening.

**See also:** [flutter_hooks](https://pub.dev/packages/flutter_hooks)

## Don't

```dart
// HookWidget that never calls any hooks
class Greeting extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

## Do

```dart
// StatelessWidget since no hooks are needed
class Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_hook_widgets: false
```
