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

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_hook_widgets: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_hook_widgets: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) — Only call hooks from a hook context.
- [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) — Don't call hooks inside loops.
- [`avoid_returning_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-returning-widgets/) — Extract widget helper methods into separate widget classes.
