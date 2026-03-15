---
title: use_ref_and_state_synchronously
description: "Check ref.mounted before using ref or state after an await"
sidebar:
  label: use_ref_and_state_synchronously
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule warns when `ref` or `state` is accessed after an `await` in a Riverpod Notifier method without first checking `ref.mounted`. If the notifier gets disposed while the async operation is in progress, accessing `ref` or `state` will throw an `UnmountedRefException`.

## Why use this rule

Async methods in Notifiers can outlive the notifier itself. When a user navigates away or a provider is disposed mid-await, the notifier is torn down but the async method keeps running. Without a `ref.mounted` guard, the next `ref.read()` or `state = ...` will crash at runtime with an exception that is easy to miss during development but hits users in production.

**See also:** [Riverpod async safety](https://riverpod.dev/docs/essentials/auto_dispose) | [Flutter mounted check](https://api.flutter.dev/flutter/widgets/State/mounted.html)

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

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_ref_and_state_synchronously: false
```
