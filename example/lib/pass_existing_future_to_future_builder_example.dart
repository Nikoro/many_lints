// ignore_for_file: unused_local_variable, unused_element
// ignore_for_file: many_lints/prefer_immutable_bloc_state, many_lints/prefer_overriding_parent_equality

// pass_existing_future_to_future_builder
//
// Warns when a FutureBuilder receives a Future created inline. build() may
// run many times per second, so an inline Future is recreated on every
// rebuild, resetting the builder to its waiting state and redoing the work.

import 'package:flutter/material.dart';

Future<String> fetchUserData() async => 'data';

class _Repository {
  Future<String> load() async => 'data';
}

final _repository = _Repository();

// ❌ Bad: a new Future on every rebuild
class _BadInlineCall extends StatelessWidget {
  const _BadInlineCall();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      // LINT: fetchUserData() allocates a new Future each build
      future: fetchUserData(),
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}

// ❌ Bad: constructor call is equally fresh each time
class _BadConstructor extends StatelessWidget {
  const _BadConstructor();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      // LINT: Future.delayed creates a new Future each build
      future: Future.delayed(const Duration(seconds: 1), () => 'x'),
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}

// ❌ Bad: method call on another object still allocates
class _BadRepositoryCall extends StatelessWidget {
  const _BadRepositoryCall();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      // LINT: repository.load() allocates a new Future each build
      future: _repository.load(),
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
  late final Future<String> _userData;

  @override
  void initState() {
    super.initState();
    _userData = fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userData,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}

// ✅ Good: a Future passed in from outside is already stable
class _GoodInjected extends StatelessWidget {
  const _GoodInjected({required this.future});

  final Future<String> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}

// ✅ Edge case: a non-FutureBuilder widget with a `future` parameter
class _CustomBuilder extends StatelessWidget {
  const _CustomBuilder({this.future});

  final Future<String>? future;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _GoodCustomBuilder extends StatelessWidget {
  const _GoodCustomBuilder();

  @override
  Widget build(BuildContext context) {
    // Not a FutureBuilder — no lint
    return _CustomBuilder(future: fetchUserData());
  }
}
