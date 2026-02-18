// ignore_for_file: unused_field, unused_element

// dispose_fields
//
// Warns when a State field that has a disposal method (dispose, close, cancel)
// is not cleaned up in the dispose() method. This prevents memory leaks from
// unclosed resources.

import 'dart:async';

import 'package:flutter/material.dart';

// ❌ Bad: Controllers not disposed
class BadNoDispose extends StatefulWidget {
  const BadNoDispose({super.key});

  @override
  State<BadNoDispose> createState() => _BadNoDisposeState();
}

class _BadNoDisposeState extends State<BadNoDispose> {
  // LINT: TextEditingController has a dispose() method but is never disposed
  final _textController = TextEditingController();
  // LINT: FocusNode has a dispose() method but is never disposed
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: StreamController not closed
class BadStreamNotClosed extends StatefulWidget {
  const BadStreamNotClosed({super.key});

  @override
  State<BadStreamNotClosed> createState() => _BadStreamNotClosedState();
}

class _BadStreamNotClosedState extends State<BadStreamNotClosed> {
  // LINT: StreamController has a close() method but is never closed
  final _streamController = StreamController<int>();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ❌ Bad: dispose() exists but field is missing from it
class BadIncompleteDispose extends StatefulWidget {
  const BadIncompleteDispose({super.key});

  @override
  State<BadIncompleteDispose> createState() => _BadIncompleteDisposeState();
}

class _BadIncompleteDisposeState extends State<BadIncompleteDispose> {
  final _controller1 = TextEditingController();
  // LINT: _controller2 is not disposed even though dispose() exists
  final _controller2 = TextEditingController();

  @override
  void dispose() {
    _controller1.dispose();
    // Missing: _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: All controllers properly disposed
class GoodProperDispose extends StatefulWidget {
  const GoodProperDispose({super.key});

  @override
  State<GoodProperDispose> createState() => _GoodProperDisposeState();
}

class _GoodProperDisposeState extends State<GoodProperDispose> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: StreamController properly closed
class GoodStreamClosed extends StatefulWidget {
  const GoodStreamClosed({super.key});

  @override
  State<GoodStreamClosed> createState() => _GoodStreamClosedState();
}

class _GoodStreamClosedState extends State<GoodStreamClosed> {
  final _streamController = StreamController<int>();

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: Non-disposable fields are ignored (no lint)
class GoodNonDisposable extends StatefulWidget {
  const GoodNonDisposable({super.key});

  @override
  State<GoodNonDisposable> createState() => _GoodNonDisposableState();
}

class _GoodNonDisposableState extends State<GoodNonDisposable> {
  int _counter = 0;
  String _label = '';
  final List<int> _items = [];

  @override
  Widget build(BuildContext context) => const SizedBox();
}
