---
title: avoid_state_constructors
description: "Avoid constructors with logic in State classes"
sidebar:
  label: avoid_state_constructors
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">State Management</span>

Flags `State` subclasses that have constructors with non-empty bodies or initializer lists. Initialization logic in State classes should live in `initState()`, not in the constructor, to respect the Flutter widget lifecycle.

## Why use this rule

The `State` constructor runs before the framework has fully initialized the state object. At construction time, `widget`, `context`, and other framework-provided properties are not yet available. Placing logic in the constructor can lead to subtle bugs when that logic depends on the widget tree. Using `initState()` ensures all framework wiring is in place.

**See also:** [State class](https://api.flutter.dev/flutter/widgets/State-class.html) | [State.initState](https://api.flutter.dev/flutter/widgets/State/initState.html)

## Don't

```dart
class _BadWidget1State extends State<BadWidget1> {
  late String _data;

  // Constructor body should be empty — move logic to initState()
  _BadWidget1State() {
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _BadWidget2State extends State<BadWidget2> {
  final String _data;

  // Initializer list in State constructor — move logic to initState()
  _BadWidget2State() : _data = 'Hello';

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

## Do

```dart
class _GoodWidgetState extends State<GoodWidget> {
  late String _data;

  @override
  void initState() {
    super.initState();
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// Empty constructor is fine
class _GoodWidget2State extends State<GoodWidget2> {
  _GoodWidget2State();

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
      avoid_state_constructors: false
```
