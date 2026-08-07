// ignore_for_file: unused_local_variable, unused_element

// pass_existing_stream_to_stream_builder
//
// Warns when a StreamBuilder receives a Stream created inline. An inline
// Stream is recreated on every rebuild, so the old subscription is cancelled
// and a new one opened, losing buffered events.

import 'package:flutter/material.dart';

class _Repository {
  Stream<int> watchCounter() async* {
    yield 1;
  }
}

final _repository = _Repository();

// ❌ Bad: a new subscription on every rebuild
class _BadInlineCall extends StatelessWidget {
  const _BadInlineCall();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      // LINT: watchCounter() opens a new stream each build
      stream: _repository.watchCounter(),
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}

// ❌ Bad: constructor call is equally fresh each time
class _BadConstructor extends StatelessWidget {
  const _BadConstructor();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      // LINT: Stream.periodic creates a new stream each build
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}

// ✅ Good: create once in initState, reuse the same instance
class _GoodStateful extends StatefulWidget {
  const _GoodStateful();

  @override
  State<_GoodStateful> createState() => _GoodStatefulState();
}

class _GoodStatefulState extends State<_GoodStateful> {
  late final Stream<int> _counter;

  @override
  void initState() {
    super.initState();
    _counter = _repository.watchCounter();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _counter,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}

// ✅ Good: a Stream passed in from outside is already stable
class _GoodInjected extends StatelessWidget {
  const _GoodInjected({required this.stream});

  final Stream<int> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}

// ✅ Edge case: a non-StreamBuilder widget with a `stream` parameter
class _CustomBuilder extends StatelessWidget {
  const _CustomBuilder({this.stream});

  final Stream<int>? stream;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _GoodCustomBuilder extends StatelessWidget {
  const _GoodCustomBuilder();

  @override
  Widget build(BuildContext context) {
    // Not a StreamBuilder — no lint
    return _CustomBuilder(stream: _repository.watchCounter());
  }
}
