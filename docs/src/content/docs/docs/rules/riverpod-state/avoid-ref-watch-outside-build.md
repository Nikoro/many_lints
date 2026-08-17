---
title: avoid_ref_watch_outside_build
description: "Subscribe only in build; read once everywhere else"
sidebar:
  label: avoid_ref_watch_outside_build
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

This rule flags a **subscribing provider read** outside a `build()` method — for example in `initState`, `dispose`, a helper method, or an event handler callback.

It covers both ecosystems, because the mistake is identical in each:

| | Subscribing (flagged outside `build`) | One-off (correct outside `build`) |
|---|---|---|
| **Riverpod** | `ref.watch(...)` | `ref.read(...)` |
| **package:provider** | `context.watch<T>()` | `context.read<T>()` |

## Why use this rule

A subscribing read ties a listener to the lifecycle of a build. Called anywhere else it creates a subscription the framework does not manage: it can fire after the widget is gone, rebuild at surprising moments, or simply leak.

With **package:provider this is not a smell but a crash** — `context.watch<T>()` throws outright when called from `initState`, so the rule catches a runtime failure rather than a style problem.

The correct alternative depends on intent. For a one-off read in a callback, use `ref.read` / `context.read<T>()`. To react to provider changes with a side effect (navigation, a snackbar), use `ref.listen` inside `build`.

This rule is the counterpart to [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/): together they express the rule that subscribing belongs in `build` and reading once belongs outside it.

The two ecosystems are told apart by the **receiver's resolved type**, not by its name — see the sibling rule for what that buys.

**See also:** [Riverpod refs](https://riverpod.dev/docs/concepts2/refs), [provider: read vs watch](https://pub.dev/packages/provider)

## Don't

```dart
// Riverpod
class MyState extends ConsumerState<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Subscription created outside a build — leaks and misbehaves
    final value = ref.watch(someProvider);
  }

  void onButtonTap() {
    // Also wrong: a callback should not subscribe
    final value = ref.watch(someProvider);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Do

```dart
class MyState extends ConsumerState<MyWidget> {
  void onButtonTap() {
    // One-off read in a callback
    final value = ref.read(someProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe here — this is what watch is for
    final value = ref.watch(someProvider);

    // React to changes with a side effect
    ref.listen(someProvider, (previous, next) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changed to $next')),
      );
    });

    return Text(value);
  }
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_ref_watch_outside_build: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_ref_watch_outside_build: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/) — Subscribe in build; do not read once.
- [`avoid_ref_inside_state_dispose`](/many_lints/docs/rules/riverpod-state/avoid-ref-inside-state-dispose/) — Avoid accessing ref inside the dispose method of a ConsumerState.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`notifier_build`](/many_lints/docs/rules/riverpod-state/notifier-build/) — Classes annotated with @riverpod must define a build method.
