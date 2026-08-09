// ignore_for_file: unused_element, unused_local_variable, unused_field
// ignore_for_file: many_lints/prefer_overriding_parent_equality, many_lints/prefer_immutable_bloc_state, many_lints/avoid_unnecessary_stateful_widgets, many_lints/always_remove_listener, many_lints/dispose_fields, many_lints/avoid_empty_setstate, many_lints/prefer_void_callback

// avoid_unremovable_callbacks_in_listeners
//
// Warns when a closure literal is passed to addListener. removeListener
// matches by identity, so a closure can never be removed — it leaks the
// captured State and keeps firing after disposal.

import 'package:flutter/material.dart';

class _MyWidget extends StatefulWidget {
  const _MyWidget();

  @override
  State<_MyWidget> createState() => _BadState();
}

// ❌ Bad: the closure can never be removed
class _BadState extends State<_MyWidget> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // LINT: removeListener can never match this object
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: an arrow closure is no different
class _BadArrowState extends State<_MyWidget> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // LINT: still a fresh object each time
    _controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: a method tear-off has a stable identity
class _GoodState extends State<_MyWidget> {
  final _controller = TextEditingController();

  void _onChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Edge case: an unrelated method taking a callback is not a listener pair
void runTask(void Function() task) {}

void notAListener() {
  runTask(() {
    debugPrint('go');
  });
}
