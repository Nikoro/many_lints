// ignore_for_file: unused_local_variable, unused_element

// avoid_ref_watch_outside_build
//
// Warns when ref.watch() is called outside a build() method. ref.watch
// creates a subscription tied to a build; calling it from a lifecycle
// method or a callback leaks listeners and rebuilds at unexpected times.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final someProvider = Provider<String>((ref) => 'hello');

class _MyWidget extends ConsumerStatefulWidget {
  const _MyWidget();

  @override
  ConsumerState<_MyWidget> createState() => _BadState();
}

// ❌ Bad: watching outside build
class _BadState extends ConsumerState<_MyWidget> {
  @override
  void initState() {
    super.initState();
    // LINT: a subscription created in initState is never managed correctly
    final value = ref.watch(someProvider);
  }

  void onButtonTap() {
    // LINT: callbacks should read, not subscribe
    final value = ref.watch(someProvider);
  }

  @override
  void dispose() {
    // LINT: watching a provider while tearing down makes no sense
    ref.watch(someProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ✅ Good: watch in build, read in callbacks, listen for side effects
class _GoodState extends ConsumerState<_MyWidget> {
  void onButtonTap() {
    // One-off read — correct in a callback
    final value = ref.read(someProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Subscribing here is exactly what watch is for
    final value = ref.watch(someProvider);

    // Side effects on change belong in listen
    ref.listen(someProvider, (previous, next) {
      debugPrint('changed to $next');
    });

    return Text(value);
  }
}

// ✅ Good: ConsumerWidget.build may watch freely
class _GoodConsumerWidget extends ConsumerWidget {
  const _GoodConsumerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(someProvider);
    return Text(value);
  }
}

// ✅ Edge case: `watch` on an unrelated receiver is not a Riverpod call
class _Observer {
  Object watch(Object target) => target;
}

class _EdgeCaseState extends ConsumerState<_MyWidget> {
  final _Observer observer = _Observer();

  void track() {
    // Not ref.watch — no lint
    observer.watch(someProvider);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
