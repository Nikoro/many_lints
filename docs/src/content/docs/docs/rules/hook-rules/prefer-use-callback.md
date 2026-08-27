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

This rule flags `useMemoized(() => someFunction)` — a `useMemoized` whose factory returns a function. `useCallback` exists for exactly that, and the quick fix swaps it in.

## Why use this rule

`useMemoized(() => () { ... })` has two layers of closure and only one of them means anything: the outer one is ceremony the hook demands, the inner one is the callback you wanted. `useCallback` takes the callback directly, so what you read is what gets memoised.

**See also:** [flutter_hooks — useCallback](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useCallback.html)

## Don't

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SubmitButton extends HookWidget {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    // A closure wrapped in a closure
    final onPressed = useMemoized(              // LINT
      () => () {
        debugPrint('submitted');
      },
    );

    return ElevatedButton(onPressed: onPressed, child: const Text('Submit'));
  }
}
```

## Do

```dart
class SubmitButton extends HookWidget {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final onPressed = useCallback(() {
      debugPrint('submitted');
    }, const []);

    return ElevatedButton(onPressed: onPressed, child: const Text('Submit'));
  }
}
```

## A returned tear-off counts too

```dart
// Don't
final onTap = useMemoized(() => _handleTap);          // LINT

// Do
final onTap = useCallback(_handleTap, const []);
```

## `useMemoized` is right for non-function values

Nothing is reported when the factory returns data — that is what the hook is for:

```dart
// Not reported
final rows = useMemoized(
  () => items.map((i) => i.toUpperCase()).toList(),
  [items],
);

final total = useMemoized(() => items.length * 2, [items]);
```

## Known limitations

**Only a single-expression or single-`return` factory is checked.** A factory that does other work before returning the closure is left alone, even though `useCallback` may still fit:

```dart
// Not reported — the block has more than one statement
final onTap = useMemoized(() {
  final label = title.toUpperCase();
  return () => debugPrint(label);
});
```

**The hook is matched by name.** `useMemoized` and `_useMemoized` are recognised wherever they are declared; a memoisation helper under another name is not.

**The factory must be written inline.** `useMemoized(buildCallback)`, passing an existing function rather than a literal closure, is not inspected.

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
