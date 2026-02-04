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
