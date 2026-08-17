---
title: avoid_conditional_hooks
description: "Never call hooks inside conditionals, loops, or ternaries"
sidebar:
  label: avoid_conditional_hooks
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags hook calls (`useState`, `useMemoized`, `useEffect`, etc.) that appear inside `if` statements, ternary expressions, `switch` cases, or short-circuit operators (`&&`, `||`). Hooks must be called in the exact same order on every build, and conditional execution breaks that guarantee.

## Why use this rule

The hooks framework tracks state by call order, not by name. If a hook is skipped on one build because a condition is false, every subsequent hook shifts position and reads the wrong state. This leads to bizarre bugs where values swap between hooks or the app crashes with an index-out-of-range error. This is the same "Rules of Hooks" constraint from React.

**See also:** [flutter_hooks](https://pub.dev/packages/flutter_hooks) | [React Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)

## Don't

```dart
class MyWidget extends HookWidget {
  final bool condition;

  @override
  Widget build(BuildContext context) {
    // Hook called conditionally — order changes between builds
    if (condition) {
      final value = useMemoized(() => 42);
    }
    return const Text('Hello');
  }
}
```

## Do

```dart
class MyWidget extends HookWidget {
  final bool condition;

  @override
  Widget build(BuildContext context) {
    // Hook always called, conditional logic inside
    final value = useMemoized(() {
      if (condition) return 42;
      return 0;
    });
    return Text('$value');
  }
}
```

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_conditional_hooks: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_unnecessary_hook_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-unnecessary-hook-widgets/) — Don't extend HookWidget if you never call any hooks.
- [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) — Only call hooks from a hook context.
- [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) — Don't call hooks inside loops.
- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
