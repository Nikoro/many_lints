---
title: avoid_ref_read_inside_build
description: "Use ref.watch instead of ref.read inside the build method"
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

This rule flags `ref.read()` calls that appear directly inside a `build()` method of a Riverpod consumer widget or state. Since `ref.read` only fetches the value once and does not subscribe to changes, the widget will not rebuild when the provider updates.

## Why use this rule

Using `ref.read` in `build()` is almost always a mistake. The widget renders with whatever value the provider had at that moment, but never updates when the value changes. This leads to stale UI that does not reflect the current application state. Use `ref.watch` to subscribe and rebuild automatically. Note that `ref.read` inside callbacks (like `onPressed`) is perfectly fine and intentional.

**See also:** [ref.read vs ref.watch](https://riverpod.dev/docs/essentials/combining_requests)

## Don't

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reads once, never rebuilds on changes
    final value = ref.read(someProvider);
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

// ref.read inside a callback is fine
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

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_ref_read_inside_build: false
```
