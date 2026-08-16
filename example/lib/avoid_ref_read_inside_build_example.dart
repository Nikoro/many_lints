// ignore_for_file: unused_local_variable, unused_element
// ignore_for_file: many_lints/prefer_immutable_bloc_state, many_lints/prefer_overriding_parent_equality

// avoid_ref_read_inside_build
//
// Warns when a ONE-OFF provider read happens inside a build() method. Such a
// read fetches the value once and does not subscribe, so the widget won't
// rebuild when the provider's value changes.
//
// Covers both ecosystems, told apart by the receiver's resolved TYPE:
//
//   Riverpod          ref.read(...)      -> use ref.watch(...)
//   package:provider  context.read<T>()  -> use context.watch<T>()
//
// Only the Riverpod half is shown below, because this example package does not
// depend on package:provider. The provider half is covered by the rule's tests
// and by its docs page.

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
