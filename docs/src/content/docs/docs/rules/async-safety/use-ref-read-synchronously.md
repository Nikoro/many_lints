---
title: use_ref_read_synchronously
description: "Add a mounted guard before calling ref.read after an await"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_ref_read_synchronously
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule catches `ref.read()` calls that happen after an `await` inside async callbacks within a `ConsumerWidget` or `ConsumerState` build method, without a `mounted` check first. If the widget is unmounted while the async operation runs, `ref.read` may return stale or invalid data.

## Why use this rule

Async callbacks like `onPressed: () async { ... }` can easily outlive the widget that created them. After an `await`, the widget might already be disposed. Calling `ref.read` at that point reads from a potentially dead reference. In `ConsumerWidget` callbacks, use `context.mounted` as the guard (for Notifier methods, the sibling rule `use_ref_and_state_synchronously` checks for `ref.mounted` instead).

**See also:** [Riverpod documentation](https://riverpod.dev) | [Dart lint: use_build_context_synchronously](https://dart.dev/tools/linter-rules/use_build_context_synchronously)

## Don't

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await Future<void>.delayed(const Duration(seconds: 1));
        // Widget may be unmounted — ref.read is unsafe
        ref.read(someProvider);
      },
      child: const Text('Tap'),
    );
  }
}
```

## Do

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!context.mounted) return;
        ref.read(someProvider);
      },
      child: const Text('Tap'),
    );
  }
}
```

A guard resets the tracking, so a second `await` after it needs its own guard:

```dart
onPressed: () async {
  await ref.read(saveProvider.future);
  if (!context.mounted) return;
  ref.read(analyticsProvider).saved();

  await Future<void>.delayed(const Duration(seconds: 1));
  if (!context.mounted) return;   // needed again
  ref.read(routerProvider).pop();
},
```

## Known limitations

**Only callbacks inside a `build` method are scanned.** This is the biggest thing to know about the rule. A `ref.read` after an `await` in a separate handler method is the same hazard but is not reported:

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _save(context, ref),   // extracted
      child: const Text('Save'),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    await ref.read(saveProvider.future);
    ref.read(analyticsProvider).saved();   // not reported, still unsafe
  }
}
```

Extracting a handler is good practice, so guard it by hand: the rule cannot follow the call.

The enclosing class must be a `ConsumerWidget`, `ConsumerState`, or a hook variant of either. A guard hidden behind a helper — `if (_stillHere()) ...` — is not recognised; the check has to be written inline.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  use_ref_read_synchronously: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  use_ref_read_synchronously: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`use_ref_and_state_synchronously`](/many_lints/docs/rules/async-safety/use-ref-and-state-synchronously/) — Check ref.mounted before using ref or state after an await.
- [`use_setstate_synchronously`](/many_lints/docs/rules/async-safety/use-setstate-synchronously/) — Guard setState after an await with a mounted check.
- [`check_is_not_closed_after_async_gap`](/many_lints/docs/rules/async-safety/check-is-not-closed-after-async-gap/) — Check isClosed before emitting state after an await.
- [`require_atomic_async_updates`](/many_lints/docs/rules/async-safety/require-atomic-async-updates/) — Re-read shared state after an await instead of writing back a stale value.
