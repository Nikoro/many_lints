import 'package:flutter/material.dart';

// avoid_unnecessary_stateful_widgets
//
// Warns when a StatefulWidget has no mutable state, lifecycle methods, or
// setState calls and could be a StatelessWidget instead.

// ❌ Bad: StatefulWidget with no mutable state — only implements build()
// LINT: This StatefulWidget has no mutable state
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

// ❌ Bad: StatefulWidget with only final/static fields — still no mutable state
// LINT: Final fields don't justify a StatefulWidget
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

// ✅ Good: StatelessWidget — the correct choice when there's no mutable state
class CorrectStatelessExample extends StatelessWidget {
  const CorrectStatelessExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Hello');
  }
}

// ✅ Good: StatefulWidget with mutable state
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

// ✅ Good: StatefulWidget with lifecycle methods
class LifecycleWidget extends StatefulWidget {
  const LifecycleWidget({super.key});

  @override
  State<LifecycleWidget> createState() => _LifecycleWidgetState();
}

class _LifecycleWidgetState extends State<LifecycleWidget> {
  @override
  void initState() {
    super.initState();
    // Setup logic here
  }

  @override
  void dispose() {
    // Cleanup logic here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Text('With lifecycle');
  }
}
