---
title: avoid_ref_watch_outside_build
description: "Use ref.read or ref.listen instead of ref.watch outside the build method"
sidebar:
  label: avoid_ref_watch_outside_build
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Riverpod State</span>

This rule flags `ref.watch()` calls that appear outside a `build()` method of a Riverpod consumer widget or state — for example in `initState`, `dispose`, a helper method, or an event handler callback.

## Why use this rule

`ref.watch` establishes a subscription that is tied to the lifecycle of a build. Calling it anywhere else creates a listener that is not managed by the framework: it can fire after the widget is gone, rebuild at surprising moments, or simply leak.

The correct alternative depends on intent. For a one-off read in a callback, use `ref.read`. To react to provider changes with a side effect (navigation, showing a snackbar), use `ref.listen` inside `build`.

This rule is the counterpart to [`avoid_ref_read_inside_build`](/many_lints/docs/rules/riverpod-state/avoid-ref-read-inside-build/): together they express the rule that `watch` belongs in `build` and `read` belongs outside it.

**See also:** [Riverpod refs](https://riverpod.dev/docs/concepts2/refs)

## Don't

```dart
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
`preset: recommended` or `preset: all`. Add it to `preset: core` with
`avoid_ref_watch_outside_build: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_ref_watch_outside_build: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
