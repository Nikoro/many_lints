---
title: avoid_ref_inside_state_dispose
description: "Avoid accessing ref inside the dispose method of a ConsumerState"
sidebar:
  label: avoid_ref_inside_state_dispose
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

This rule catches `ref` usage inside the `dispose()` method of `ConsumerState` classes. By the time `dispose()` runs, providers may already be torn down, so reading or watching them can throw unexpected errors or return stale data.

## Why use this rule

In Riverpod, the lifecycle of providers and widgets is not tightly coupled. When `dispose()` fires, there is no guarantee that the providers you are trying to access are still alive. Accessing `ref` in `dispose()` can silently read disposed state or throw `UnmountedRefException`, leading to hard-to-debug crashes in production.

**See also:** [Riverpod automatic disposal](https://riverpod.dev/docs/concepts2/auto_dispose)

## Don't

The usual shape: a `dispose()` that tries to tell a provider the screen is
gone. By the time it runs the provider may already have been torn down, so this
either throws or writes to state nothing is listening to.

```dart
class _EditorPageState extends ConsumerState<EditorPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    ref.read(draftProvider.notifier).save(_controller.text); // LINT
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: _controller);
}
```

## Do

Dispose only what this widget owns, and push the provider work to the moment
the user actually leaves — or let the provider clean up after itself with
`ref.onDispose`:

```dart
class _EditorPageState extends ConsumerState<EditorPage> {
  final _controller = TextEditingController();

  void _saveDraft() {
    ref.read(draftProvider.notifier).save(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onSubmitted: (_) => _saveDraft(),
  );
}
```

### Reading a value you need at dispose time

Capture it while the widget is alive, then use the captured value in
`dispose()`:

```dart
class _SessionPageState extends ConsumerState<SessionPage> {
  late final Analytics _analytics = ref.read(analyticsProvider);

  @override
  void dispose() {
    _analytics.screenClosed('session'); // no ref here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Known limitations

The search stops at a closure boundary. A `ref` read inside a callback declared
in `dispose()` is not reported, because such a callback may be stored and run
somewhere else entirely.

Only `dispose()` on a `ConsumerState` subclass is checked. `deactivate()` has
the same hazard and is not covered.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_ref_inside_state_dispose: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_ref_inside_state_dispose: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/) — Subscribe in build; do not read once.
- [`avoid_ref_watch_outside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-watch-outside-build/) — Subscribe only in build; read once everywhere else.
- [`use_ref_and_state_synchronously`](/many_lints/docs/rules/async-safety/use-ref-and-state-synchronously/) — Check ref.mounted before using ref or state after an await.
- [`async_value_nullable_pattern`](/many_lints/docs/rules/riverpod-state/async-value-nullable-pattern/) — Matching AsyncValue(:final value?) on a nullable value hides a legitimate null result.
