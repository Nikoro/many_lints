---
title: use_ref_read_synchronously
description: "Avoid calling 'ref.read' after an await point without checking if the widget is mounted."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_ref_read_synchronously
---

| Property | Value |
|----------|-------|
| **Rule name** | `use_ref_read_synchronously` |
| **Category** | Async Safety |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Avoid calling 'ref.read' after an await point without checking if the widget is mounted.

## Suggestion

Add a 'if (!mounted) return;' or 'if (!context.mounted) return;' guard before calling 'ref.read' after an await.

## Example

```dart
// ignore_for_file: unused_local_variable, unused_element

// use_ref_read_synchronously
//
// Warns when `ref.read()` is called after an `await` point inside an
// async callback within a ConsumerWidget or ConsumerState build method
// without checking if the widget is still mounted.

import 'package:flutter_riverpod/flutter_riverpod.dart';

final someProvider = Provider<String>((ref) => 'hello');

// ❌ Bad: Calling ref.read after await without a mounted guard
class _BadRefReadAfterAwait extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await Future<void>.delayed(const Duration(seconds: 1));
        // LINT: ref.read after await — widget may be unmounted
        ref.read(someProvider);
      },
      child: const Text('Tap'),
    );
  }
}

// ❌ Bad: Multiple ref.read calls after await
class _BadMultipleReads extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await fetchData();
        // LINT: ref.read after await
        final a = ref.read(someProvider);
        // LINT: still after await with no guard
        final b = ref.read(someProvider);
      },
      child: const Text('Tap'),
    );
  }
}

// ✅ Good: Using mounted guard before ref.read
class _GoodMountedGuard extends ConsumerWidget {
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

// ✅ Good: ref.read before await (no async gap)
class _GoodBeforeAwait extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        ref.read(someProvider);
        await Future<void>.delayed(const Duration(seconds: 1));
        // No ref.read after await — safe
      },
      child: const Text('Tap'),
    );
  }
}

// ✅ Good: ref.read in a synchronous callback
class _GoodSyncCallback extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.read(someProvider); // sync — no issue
      },
      child: const Text('Tap'),
    );
  }
}

Future<void> fetchData() => Future<void>.delayed(const Duration(seconds: 1));
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_ref_read_synchronously: false
```
