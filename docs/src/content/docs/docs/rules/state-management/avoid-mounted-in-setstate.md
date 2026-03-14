---
title: avoid_mounted_in_setstate
description: "Checking mounted inside setState is too late and can lead to an exception."
sidebar:
  label: avoid_mounted_in_setstate
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_mounted_in_setstate` |
| **Category** | State Management |
| **Severity** | Warning |
| **Has quick fix** | No |

## Problem

Checking mounted inside setState is too late and can lead to an exception.

## Suggestion

Check mounted before calling setState instead.

## Example

```dart
// ignore_for_file: unused_local_variable, unnecessary_lambdas

// avoid_mounted_in_setstate
//
// Warns when `mounted` is checked inside a `setState` callback.
// Checking `mounted` inside `setState` is too late — if the widget has
// been disposed, `setState` itself will throw before the callback runs.

import 'package:flutter/widgets.dart';

// ❌ Bad: mounted check inside setState callback
class BadExample extends StatefulWidget {
  const BadExample({super.key});

  @override
  State<BadExample> createState() => _BadExampleState();
}

class _BadExampleState extends State<BadExample> {
  Future<void> _loadData() async {
    final data = await Future.delayed(const Duration(seconds: 1), () => 42);

    // LINT: Checking mounted inside setState is too late
    setState(() {
      if (mounted) {
        // This check is useless — if the widget was disposed,
        // setState itself already threw before reaching here.
      }
    });

    // LINT: context.mounted inside setState is also flagged
    setState(() {
      if (context.mounted) {
        // Same problem as above
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: mounted check before setState
class GoodExample extends StatefulWidget {
  const GoodExample({super.key});

  @override
  State<GoodExample> createState() => _GoodExampleState();
}

class _GoodExampleState extends State<GoodExample> {
  Future<void> _loadData() async {
    final data = await Future.delayed(const Duration(seconds: 1), () => 42);

    // Check mounted BEFORE calling setState
    if (!mounted) return;
    setState(() {
      // Safe — we already verified the widget is still mounted
    });

    // Or using context.mounted
    if (context.mounted) {
      setState(() {
        // Also safe
      });
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_mounted_in_setstate: false
```
