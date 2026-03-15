---
title: avoid_unnecessary_stateful_widgets
description: "Detect StatefulWidgets that have no mutable state"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_stateful_widgets
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">State Management</span>

Warns when a `StatefulWidget` has no mutable fields, lifecycle method overrides, or `setState` calls in its companion `State` class. In these cases, the widget should be a `StatelessWidget` instead.

## Why use this rule

Using `StatefulWidget` when there is no mutable state adds unnecessary complexity and overhead. A `StatelessWidget` is simpler to read, easier to test, and communicates intent more clearly. The framework also has slightly less work to do for stateless widgets since there is no `State` object to manage.

**See also:** [StatefulWidget](https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html) | [StatelessWidget](https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html)

## Don't

```dart
// StatefulWidget with no mutable state — only implements build()
class UnnecessaryStatefulExample extends StatefulWidget {
  const UnnecessaryStatefulExample({super.key});

  @override
  State<UnnecessaryStatefulExample> createState() =>
      _UnnecessaryStatefulExampleState();
}

class _UnnecessaryStatefulExampleState
    extends State<UnnecessaryStatefulExample> {
  @override
  Widget build(BuildContext context) {
    return const Text('Hello');
  }
}

// StatefulWidget with only final/static fields — still no mutable state
class FinalFieldStatefulExample extends StatefulWidget {
  const FinalFieldStatefulExample({super.key});

  @override
  State<FinalFieldStatefulExample> createState() =>
      _FinalFieldStatefulExampleState();
}

class _FinalFieldStatefulExampleState extends State<FinalFieldStatefulExample> {
  final String title = 'Hello';

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
```

## Do

```dart
// StatelessWidget — the correct choice when there's no mutable state
class CorrectStatelessExample extends StatelessWidget {
  const CorrectStatelessExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Hello');
  }
}

// StatefulWidget with mutable state — justified
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _count++),
      child: Text('Count: $_count'),
    );
  }
}

// StatefulWidget with lifecycle methods — justified
class LifecycleWidget extends StatefulWidget {
  const LifecycleWidget({super.key});

  @override
  State<LifecycleWidget> createState() => _LifecycleWidgetState();
}

class _LifecycleWidgetState extends State<LifecycleWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Text('With lifecycle');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unnecessary_stateful_widgets: false
```
