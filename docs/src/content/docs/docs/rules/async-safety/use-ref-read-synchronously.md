---
title: use_ref_read_synchronously
description: "Add a mounted guard before calling ref.read after an await"
sidebar:
  label: use_ref_read_synchronously
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule catches `ref.read()` calls that happen after an `await` inside async callbacks within a `ConsumerWidget` or `ConsumerState` build method, without a `mounted` check first. If the widget is unmounted while the async operation runs, `ref.read` may return stale or invalid data.

## Why use this rule

Async callbacks like `onPressed: () async { ... }` can easily outlive the widget that created them. After an `await`, the widget might already be disposed. Calling `ref.read` at that point reads from a potentially dead reference. In `ConsumerWidget` callbacks, use `context.mounted` as the guard (for Notifier methods, the sibling rule `use_ref_and_state_synchronously` checks for `ref.mounted` instead).

**See also:** [Riverpod documentation](https://riverpod.dev)

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

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_ref_read_synchronously: false
```
