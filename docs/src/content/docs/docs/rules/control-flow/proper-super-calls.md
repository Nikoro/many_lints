---
title: proper_super_calls
description: "Enforce correct ordering of super lifecycle calls in State classes"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: proper_super_calls
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when super lifecycle methods are called in the wrong order in `State` subclasses. Methods like `initState`, `didUpdateWidget`, `activate`, `didChangeDependencies`, and `reassemble` must call super first. Methods like `deactivate` and `dispose` must call super last.

## Why use this rule

Flutter's `State` lifecycle methods have a specific contract about when `super` should be called. Calling `super.initState()` after your own initialization code can lead to errors because the framework expects to set up its own state first. Conversely, calling `super.dispose()` before your cleanup code means your resources are released while the framework has already torn down its own state. The quick fix automatically moves the super call to the correct position.

**See also:** [State.initState](https://api.flutter.dev/flutter/widgets/State/initState.html) | [State.dispose](https://api.flutter.dev/flutter/widgets/State/dispose.html)

## Don't

```dart
class _BadInitStateState extends State<BadInitState> {
  String _data = '';

  @override
  void initState() {
    _data = 'Hello'; // super.initState() should come before this
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _BadDisposeState extends State<BadDispose> {
  @override
  void dispose() {
    super.dispose(); // super.dispose() should come after cleanup
    debugPrint('cleanup');
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _BadDeactivateState extends State<BadDeactivate> {
  @override
  void deactivate() {
    super.deactivate(); // super.deactivate() should come after cleanup
    debugPrint('deactivating');
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Do

```dart
class _GoodInitStateState extends State<GoodInitState> {
  String _data = '';

  @override
  void initState() {
    super.initState(); // First
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _GoodDisposeState extends State<GoodDispose> {
  @override
  void dispose() {
    debugPrint('cleanup');
    super.dispose(); // Last
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _GoodDeactivateState extends State<GoodDeactivate> {
  @override
  void deactivate() {
    debugPrint('deactivating');
    super.deactivate(); // Last
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
      proper_super_calls: false
```
