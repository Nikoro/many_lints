---
title: avoid_mounted_in_setstate
description: "Detect mounted checks inside setState callbacks"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_mounted_in_setstate
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">State Management</span>

Warns when `mounted` or `context.mounted` is checked inside a `setState` callback. If the widget has been disposed, `setState` itself throws an exception before the callback ever runs, making any `mounted` check inside it useless.

## Why use this rule

A common misconception is that checking `mounted` inside `setState` protects against calling `setState` on a disposed widget. In reality, `setState` validates the state object immediately when called -- if the widget is unmounted, it throws before executing the callback. The `mounted` check must happen before the `setState` call, not inside it.

**See also:** [State.mounted](https://api.flutter.dev/flutter/widgets/State/mounted.html) | [State.setState](https://api.flutter.dev/flutter/widgets/State/setState.html)

## Don't

```dart
class _BadExampleState extends State<BadExample> {
  Future<void> _loadData() async {
    final data = await Future.delayed(const Duration(seconds: 1), () => 42);

    // mounted check inside setState is too late
    setState(() {
      if (mounted) {
        // If the widget was disposed, setState already threw
      }
    });

    // context.mounted inside setState is also wrong
    setState(() {
      if (context.mounted) {
        // Same problem
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Do

```dart
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
