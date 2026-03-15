---
title: avoid_unnecessary_setstate
description: "Detect unnecessary setState calls in lifecycle methods"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_setstate
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">State Management</span>

Warns when `setState` is called directly inside `initState`, `didUpdateWidget`, or `build` methods. In these lifecycle methods, mutating state directly is sufficient because the framework already schedules a build after they return. Calling `setState` in `build` triggers an unnecessary additional rebuild.

## Why use this rule

In `initState` and `didUpdateWidget`, the framework will call `build` automatically after the method returns, so wrapping mutations in `setState` is redundant overhead. In `build`, calling `setState` triggers an infinite rebuild loop or at minimum a wasted frame. Event handler callbacks (like `onTap`) inside `build` are excluded from this rule since they run asynchronously and do need `setState`.

**See also:** [setState](https://api.flutter.dev/flutter/widgets/State/setState.html)

## Don't

```dart
class _BadInitStateState extends State<BadInitState> {
  String _data = '';

  @override
  void initState() {
    super.initState();
    // Unnecessary — framework rebuilds after initState anyway
    setState(() {
      _data = 'Hello';
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _BadBuildState extends State<BadBuild> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    // Triggers an unnecessary rebuild during build
    setState(() {
      _data = 'Hello';
    });
    return const SizedBox();
  }
}
```

## Do

```dart
class _GoodInitStateState extends State<GoodInitState> {
  String _data = '';

  @override
  void initState() {
    super.initState();
    _data = 'Hello'; // Assign directly — no setState needed
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// setState in an async method is fine
class _GoodAsyncState extends State<GoodAsync> {
  String _data = '';

  Future<void> _loadData() async {
    final data = await Future.value('Hello');
    setState(() {
      _data = data; // Async method needs setState to trigger rebuild
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// setState in event handler callbacks inside build is fine
class _GoodCallbackState extends State<GoodCallback> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _data = 'tapped'; // Event handler runs asynchronously
        });
      },
      child: const SizedBox(),
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
      avoid_unnecessary_setstate: false
```
