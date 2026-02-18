// ignore_for_file: unused_element, avoid_unnecessary_setstate

// proper_super_calls
//
// Warns when super lifecycle methods are called in the wrong order
// in State subclasses. initState, didUpdateWidget, activate,
// didChangeDependencies, and reassemble must call super first.
// deactivate and dispose must call super last.

import 'package:flutter/widgets.dart';

// ❌ Bad: super.initState() should be first
class BadInitState extends StatefulWidget {
  const BadInitState({super.key});

  @override
  State<BadInitState> createState() => _BadInitStateState();
}

class _BadInitStateState extends State<BadInitState> {
  String _data = '';

  @override
  void initState() {
    _data = 'Hello'; // LINT: super.initState() should come before this
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: super.dispose() should be last
class BadDispose extends StatefulWidget {
  const BadDispose({super.key});

  @override
  State<BadDispose> createState() => _BadDisposeState();
}

class _BadDisposeState extends State<BadDispose> {
  @override
  void dispose() {
    super.dispose(); // LINT: super.dispose() should come after cleanup
    debugPrint('cleanup');
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: super.deactivate() should be last
class BadDeactivate extends StatefulWidget {
  const BadDeactivate({super.key});

  @override
  State<BadDeactivate> createState() => _BadDeactivateState();
}

class _BadDeactivateState extends State<BadDeactivate> {
  @override
  void deactivate() {
    super.deactivate(); // LINT: super.deactivate() should come after cleanup
    debugPrint('deactivating');
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: super.initState() is first
class GoodInitState extends StatefulWidget {
  const GoodInitState({super.key});

  @override
  State<GoodInitState> createState() => _GoodInitStateState();
}

class _GoodInitStateState extends State<GoodInitState> {
  String _data = '';

  @override
  void initState() {
    super.initState();
    _data = 'Hello';
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: super.dispose() is last
class GoodDispose extends StatefulWidget {
  const GoodDispose({super.key});

  @override
  State<GoodDispose> createState() => _GoodDisposeState();
}

class _GoodDisposeState extends State<GoodDispose> {
  @override
  void dispose() {
    debugPrint('cleanup');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: super.deactivate() is last
class GoodDeactivate extends StatefulWidget {
  const GoodDeactivate({super.key});

  @override
  State<GoodDeactivate> createState() => _GoodDeactivateState();
}

class _GoodDeactivateState extends State<GoodDeactivate> {
  @override
  void deactivate() {
    debugPrint('deactivating');
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
