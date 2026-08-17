---
title: avoid_ref_read_inside_build
description: "Subscribe in build; do not read once"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_ref_read_inside_build
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

This rule flags a **one-off provider read** inside a `build()` method. Such a read fetches the value once and does not subscribe, so the widget will not rebuild when the provider updates.

It covers both ecosystems, because the mistake is identical in each:

| | One-off (flagged in `build`) | Subscribing (correct in `build`) |
|---|---|---|
| **Riverpod** | `ref.read(...)` | `ref.watch(...)` |
| **package:provider** | `context.read<T>()` | `context.watch<T>()` |

## Why use this rule

A one-off read in `build()` is almost always a mistake. The widget renders with whatever value the provider had at that moment and is never told it changed, so the UI goes stale until something unrelated rebuilds it — a bug that reproduces only in the order the user happened to tap things.

A one-off read inside a **callback** (`onPressed`) is intentional and is not reported.

The two ecosystems are told apart by the **receiver's resolved type**, not by its name: Riverpod's `ref` is a `WidgetRef`/`Ref`, while provider's extensions hang off `BuildContext`. So `widgetContext.read<T>()` is caught under any receiver name, while a field of some unrelated class you happened to call `ref` is not.

**See also:** [Riverpod refs](https://riverpod.dev/docs/concepts2/refs), [provider: read vs watch](https://pub.dev/packages/provider)

## Don't

```dart
// Riverpod
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reads once, never rebuilds on changes
    final value = ref.read(someProvider);
    return Text(value);
  }
}

// package:provider
class MyOtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final value = context.read<String>();
    return Text(value);
  }
}
```

## Do

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribes and rebuilds when provider changes
    final value = ref.watch(someProvider);
    return Text(value);
  }
}

// package:provider
class MyProviderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final value = context.watch<String>();
    return Text(value);
  }
}

// A one-off read inside a callback is fine, in either ecosystem.
class MyOtherWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // Intentional one-time read triggered by user action
        final value = ref.read(someProvider);
      },
      child: const Text('Tap'),
    );
  }
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_ref_read_inside_build: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_ref_read_inside_build: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_ref_inside_state_dispose`](/many_lints/docs/rules/riverpod-state/avoid-ref-inside-state-dispose/) — Avoid accessing ref inside the dispose method of a ConsumerState.
- [`avoid_ref_watch_outside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-watch-outside-build/) — Subscribe only in build; read once everywhere else.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`notifier_build`](/many_lints/docs/rules/riverpod-state/notifier-build/) — Classes annotated with @riverpod must define a build method.
