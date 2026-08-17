---
title: prefer_use_callback
description: "Use 'useCallback' instead of 'useMemoized' for memoizing functions."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_use_callback
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Hook Rules</span>

Flags uses of `useMemoized` where the factory function returns another function. When you are memoizing a callback, `useCallback` is the semantically correct hook to use. `useMemoized` is designed for expensive non-function values.

## Why use this rule

`useCallback` communicates intent more clearly than `useMemoized(() => someFunction)`. It signals that you are memoizing a callback, not computing an expensive value. Using the right hook improves readability and aligns with the hooks naming conventions from React and flutter_hooks.

**See also:** [flutter_hooks - useCallback](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)

## Don't

```dart
class BadWidget extends HookWidget {
  const BadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // useMemoized wrapping a closure
    final onPressed = useMemoized(
      () => () {
        debugPrint('pressed');
      },
    );

    // useMemoized wrapping a tear-off
    final onTap = useMemoized(() => _handleTap);
    return ElevatedButton(onPressed: onPressed, child: const Text('Tap'));
  }

  void _handleTap() => debugPrint('tapped');
}
```

## Do

```dart
class GoodWidget extends HookWidget {
  const GoodWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // useCallback for memoizing callbacks
    final onPressed = useCallback(() {
      debugPrint('pressed');
    }, []);

    return ElevatedButton(onPressed: onPressed, child: const Text('Tap'));
  }
}

// useMemoized is fine for non-function values:
final expensiveValue = useMemoized(() => List.generate(100, (i) => i));
```

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_use_callback: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_use_callback: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_use_prefix`](/many_lints/docs/rules/hook-rules/prefer-use-prefix/) — Custom hooks should start with the 'use' prefix.
- [`avoid_hooks_outside_build`](/many_lints/docs/rules/hook-rules/avoid-hooks-outside-build/) — Only call hooks from a hook context.
- [`avoid_misused_hooks`](/many_lints/docs/rules/hook-rules/avoid-misused-hooks/) — Don't call hooks inside loops.
- [`avoid_throw_in_fp_callback`](/many_lints/docs/rules/fpdart/avoid-throw-in-fp-callback/) — A throw inside an fpdart callback escapes the error channel the pipeline is built to carry.
