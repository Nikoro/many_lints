// ignore_for_file: unused_field, unused_element

// always_remove_listener
//
// Warns when addListener() is called in a State lifecycle method
// (initState, didUpdateWidget, didChangeDependencies) without a
// matching removeListener() call in dispose(). This can cause
// memory leaks if the Listenable outlives the widget.

import 'package:flutter/material.dart';

// ❌ Bad: Listener added in initState but never removed
class BadNoDispose extends StatefulWidget {
  const BadNoDispose({super.key});

  @override
  State<BadNoDispose> createState() => _BadNoDisposeState();
}

class _BadNoDisposeState extends State<BadNoDispose> {
  final ValueNotifier<int> _counter = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // LINT: addListener without matching removeListener in dispose
    _counter.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: Listener added but wrong listener removed in dispose
class BadWrongListener extends StatefulWidget {
  const BadWrongListener({super.key});

  @override
  State<BadWrongListener> createState() => _BadWrongListenerState();
}

class _BadWrongListenerState extends State<BadWrongListener> {
  final ValueNotifier<int> _counter = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // LINT: removeListener in dispose uses a different callback
    _counter.addListener(_onChanged);
  }

  @override
  void dispose() {
    _counter.removeListener(_wrongCallback);
    super.dispose();
  }

  void _onChanged() => setState(() {});
  void _wrongCallback() {}

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: Listener properly removed in dispose
class GoodProperCleanup extends StatefulWidget {
  const GoodProperCleanup({super.key});

  @override
  State<GoodProperCleanup> createState() => _GoodProperCleanupState();
}

class _GoodProperCleanupState extends State<GoodProperCleanup> {
  final ValueNotifier<int> _counter = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _counter.addListener(_onChanged);
  }

  @override
  void dispose() {
    _counter.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: Multiple listeners all properly cleaned up
class GoodMultipleListeners extends StatefulWidget {
  const GoodMultipleListeners({super.key});

  @override
  State<GoodMultipleListeners> createState() => _GoodMultipleListenersState();
}

class _GoodMultipleListenersState extends State<GoodMultipleListeners> {
  final ValueNotifier<int> _a = ValueNotifier(0);
  final ValueNotifier<int> _b = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _a.addListener(_onA);
    _b.addListener(_onB);
  }

  @override
  void dispose() {
    _a.removeListener(_onA);
    _b.removeListener(_onB);
    super.dispose();
  }

  void _onA() => setState(() {});
  void _onB() => setState(() {});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
