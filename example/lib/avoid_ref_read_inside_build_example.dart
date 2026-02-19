// ignore_for_file: unused_local_variable, unused_element

// avoid_ref_read_inside_build
//
// Warns when ref.read() is called inside a build() method of a Riverpod
// consumer widget or state. ref.read reads a value once and does not listen
// for changes, so the widget won't rebuild when the provider's value changes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final someProvider = Provider<String>((ref) => 'hello');

// ❌ Bad: Using ref.read() in build — widget won't rebuild on changes
class _BadConsumerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LINT: ref.read reads the value once, missing subsequent changes
    final value = ref.read(someProvider);
    return Text(value);
  }
}

// ❌ Bad: Using ref.read() in ConsumerState.build
class _BadConsumerState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    // LINT: ref.read reads the value once, missing subsequent changes
    final value = ref.read(someProvider);
    return Text(value);
  }
}

// ✅ Good: Using ref.watch() — widget rebuilds when provider changes
class _GoodConsumerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(someProvider);
    return Text(value);
  }
}

// ✅ Good: ref.read() inside a closure/callback is fine (intentional one-time read)
class _GoodRefReadInCallback extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // This is fine — triggered by user action, not during build
        final value = ref.read(someProvider);
      },
      child: const Text('Tap'),
    );
  }
}

// ✅ Good: ref.read() outside build is fine
class _GoodRefReadOutsideBuild extends ConsumerState<ConsumerStatefulWidget> {
  void _handleTap() {
    final value = ref.read(someProvider);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
