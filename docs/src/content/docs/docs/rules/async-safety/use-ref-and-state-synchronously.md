---
title: use_ref_and_state_synchronously
description: "Check ref.mounted before using ref or state after an await"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_ref_and_state_synchronously
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule warns when `ref` or `state` is accessed after an `await` in a Riverpod Notifier method without first checking `ref.mounted`. If the notifier gets disposed while the async operation is in progress, accessing `ref` or `state` will throw an `UnmountedRefException`.

## Why use this rule

Async methods in Notifiers can outlive the notifier itself. When a user navigates away or a provider is disposed mid-await, the notifier is torn down but the async method keeps running. Without a `ref.mounted` guard, the next `ref.read()` or `state = ...` will crash at runtime with an exception that is easy to miss during development but hits users in production.

**See also:** [Riverpod automatic disposal](https://riverpod.dev/docs/concepts2/auto_dispose) | [Flutter mounted check](https://api.flutter.dev/flutter/widgets/State/mounted.html) | [Dart lint: use_build_context_synchronously](https://dart.dev/tools/linter-rules/use_build_context_synchronously)

## Don't

```dart
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> incrementDelayed() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    // Notifier may be disposed by now — this can throw
    state = state + 1;
  }
}
```

## Do

```dart
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> incrementDelayed() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!ref.mounted) return;
    state = state + 1;
  }
}
```

### Reading a provider after the await

`ref` itself is guarded, not just `state`. Any `ref.read` / `ref.watch` after an await needs the check too:

```dart
class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => const Cart.empty();

  Future<void> checkout() async {
    await ref.read(paymentProvider).charge();
    if (!ref.mounted) return;
    ref.read(analyticsProvider).purchased();
    state = const Cart.empty();
  }
}
```

### Each await needs its own guard

A guard clears the tracking, so a second suspension re-opens the gap:

```dart
Future<void> refresh() async {
  final items = await ref.read(catalogProvider.future);
  if (!ref.mounted) return;
  state = Cart(items);

  await ref.read(syncProvider).push();
  if (!ref.mounted) return;   // needed again
  state = state.markSynced();
}
```

## Known limitations

**The guard must be an early return.** Only `if (!ref.mounted) return;` is recognised. The wrapper form is *not*, even though it is equally safe:

```dart
Future<void> incrementDelayed() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  if (ref.mounted) {
    state = state + 1;   // still reported
  }
}
```

Write the early return, or suppress with `// ignore: many_lints/use_ref_and_state_synchronously`. (Its `State` sibling [`use_setstate_synchronously`](/many_lints/docs/rules/async-safety/use-setstate-synchronously/) does accept the wrapper form.)

Only methods on a class extending Riverpod's `Notifier` are scanned, and statements are read in source order within one method body. A usage inside a nested closure is not reported, and a guard behind a helper method is not recognised.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  use_ref_and_state_synchronously: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  use_ref_and_state_synchronously: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`use_ref_read_synchronously`](/many_lints/docs/rules/async-safety/use-ref-read-synchronously/) — Add a mounted guard before calling ref.read after an await.
- [`use_setstate_synchronously`](/many_lints/docs/rules/async-safety/use-setstate-synchronously/) — Guard setState after an await with a mounted check.
- [`check_is_not_closed_after_async_gap`](/many_lints/docs/rules/async-safety/check-is-not-closed-after-async-gap/) — Check isClosed before emitting state after an await.
- [`require_atomic_async_updates`](/many_lints/docs/rules/async-safety/require-atomic-async-updates/) — Re-read shared state after an await instead of writing back a stale value.
