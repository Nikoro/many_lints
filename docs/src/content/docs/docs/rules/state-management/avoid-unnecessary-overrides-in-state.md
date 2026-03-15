---
title: avoid_unnecessary_overrides_in_state
description: "Detect State lifecycle overrides that only call super"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_overrides_in_state
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">State Management</span>

Warns when a `State` class overrides a lifecycle method (like `initState`, `dispose`, `didChangeDependencies`) but the body only calls the corresponding `super` method without any additional logic. These overrides are redundant and should be removed.

## Why use this rule

Lifecycle overrides that only call `super` clutter your State classes and make it harder to spot the overrides that actually do meaningful work. When every lifecycle method is overridden "just in case," readers must inspect each one to know which ones matter. Removing the no-op overrides keeps your State classes focused on actual behavior.

**See also:** [State.initState](https://api.flutter.dev/flutter/widgets/State/initState.html) | [State.dispose](https://api.flutter.dev/flutter/widgets/State/dispose.html)

## Don't

```dart
class _BadWidgetState extends State<_BadWidget> {
  @override
  void dispose() {
    super.dispose(); // Only calls super — remove this override
  }

  @override
  void initState() {
    super.initState(); // Only calls super — remove this override
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _BadExpressionWidgetState extends State<_BadExpressionWidget> {
  @override
  void initState() => super.initState(); // Expression body, still redundant

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Do

```dart
class _GoodWidgetState extends State<_GoodWidget> {
  final ValueNotifier<int> _counter = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _counter.addListener(_onChanged); // Additional logic — override is justified
  }

  @override
  void dispose() {
    _counter.removeListener(_onChanged); // Cleanup logic — override is justified
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// No overrides at all — clean and simple
class _MinimalWidgetState extends State<_MinimalWidget> {
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
      avoid_unnecessary_overrides_in_state: false
```
