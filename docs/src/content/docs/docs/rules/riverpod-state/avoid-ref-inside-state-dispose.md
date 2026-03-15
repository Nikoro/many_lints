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

**See also:** [Riverpod provider lifecycle](https://riverpod.dev/docs/essentials/auto_dispose)

## Don't

```dart
class MyWidgetState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    // ref may already be invalid at this point
    ref.read(someProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Do

```dart
class MyWidgetState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  void dispose() {
    // Clean up without accessing ref
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref is safe to use in build
    final value = ref.watch(someProvider);
    return Text(value);
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_ref_inside_state_dispose: false
```
