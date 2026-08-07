// ignore_for_file: unused_element, unused_field

// avoid_empty_setstate
//
// Warns when setState is called with an empty callback. The state was
// mutated elsewhere, so the change and the rebuild request are detached
// from each other.

import 'package:flutter/material.dart';

class _MyWidget extends StatefulWidget {
  const _MyWidget();

  @override
  State<_MyWidget> createState() => _BadState();
}

// ❌ Bad: mutation happens outside the callback
class _BadState extends State<_MyWidget> {
  int _counter = 0;

  void increment() {
    _counter++;
    // LINT: the rebuild request is detached from the change
    setState(() {});
  }

  void refresh() {
    // LINT: same problem, written with an explicit receiver
    this.setState(() {});
  }

  @override
  Widget build(BuildContext context) => Text('$_counter');
}

// ✅ Good: the mutation lives inside the callback
class _GoodState extends State<_MyWidget> {
  int _counter = 0;

  void increment() {
    setState(() {
      _counter++;
    });
  }

  void reset() {
    // An expression body is fine too
    setState(() => _counter = 0);
  }

  @override
  Widget build(BuildContext context) => Text('$_counter');
}

// ✅ Edge case: a same-named method on an unrelated class
class _Controller {
  void setState(void Function() fn) {}
}

class _EdgeCaseState extends State<_MyWidget> {
  final _controller = _Controller();

  void refresh() {
    // Not State.setState — no lint
    _controller.setState(() {});
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
