// ignore_for_file: many_lints/avoid_unnecessary_stateful_widgets, many_lints/prefer_immutable_bloc_state, many_lints/prefer_overriding_parent_equality, many_lints/prefer_single_widget_per_file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// avoid_unnecessary_consumer_widgets
//
// ConsumerWidget should only be used when the WidgetRef is actually used.
// If ref is unused, use StatelessWidget instead.

// LINT: ConsumerWidget does not use WidgetRef
class AvoidUnnecessaryConsumerWidgetsExample extends ConsumerWidget {
  const AvoidUnnecessaryConsumerWidgetsExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref is never used here
    return Text('Hello');
  }
}

// LINT: ConsumerStatefulWidget whose state never touches ref
class AvoidUnnecessaryConsumerStatefulWidgetsExample
    extends ConsumerStatefulWidget {
  const AvoidUnnecessaryConsumerStatefulWidgetsExample({super.key});

  @override
  ConsumerState<AvoidUnnecessaryConsumerStatefulWidgetsExample> createState() =>
      _AvoidUnnecessaryConsumerStatefulWidgetsExampleState();
}

class _AvoidUnnecessaryConsumerStatefulWidgetsExampleState
    extends ConsumerState<AvoidUnnecessaryConsumerStatefulWidgetsExample> {
  @override
  Widget build(BuildContext context) {
    // ref is never used anywhere in this state
    return Text('Hello');
  }
}

// OK: a mixin uses ref on the state's behalf
mixin _AnalyticsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void track() {
    ref.read(Provider((_) => 0));
  }
}

class MixinConsumerExample extends ConsumerStatefulWidget {
  const MixinConsumerExample({super.key});

  @override
  ConsumerState<MixinConsumerExample> createState() =>
      _MixinConsumerExampleState();
}

class _MixinConsumerExampleState extends ConsumerState<MixinConsumerExample>
    with _AnalyticsMixin {
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: track, child: const Text('Save'));
  }
}
