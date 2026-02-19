// ignore_for_file: unused_local_variable, dead_code

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// avoid_conditional_hooks
//
// Hooks must always be called in the same order on every build.
// Calling hooks conditionally can cause hooks to be called in
// a different order between builds, leading to unexpected behavior.

// ❌ Bad: Hook called inside an if statement
class ConditionalHookWidget extends HookWidget {
  const ConditionalHookWidget({super.key, required this.condition});

  final bool condition;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      // LINT: Hook called conditionally
      final value = useMemoized(() => 42);
    }
    return const Text('Hello');
  }
}

// ❌ Bad: Hook called inside a ternary expression
class TernaryHookWidget extends HookWidget {
  const TernaryHookWidget({super.key, required this.condition});

  final bool condition;

  @override
  Widget build(BuildContext context) {
    // LINT: Both branches call hooks conditionally
    final value = condition ? useState(0) : useState(1);
    return Text('$value');
  }
}

// ✅ Good: Hooks called unconditionally, conditional logic inside
class CorrectHookWidget extends HookWidget {
  const CorrectHookWidget({super.key, required this.condition});

  final bool condition;

  @override
  Widget build(BuildContext context) {
    final value = useMemoized(() {
      if (condition) {
        return 42;
      }
      return 0;
    });
    return Text('$value');
  }
}

// ✅ Good: All hooks called unconditionally at top level
class MultipleHooksWidget extends HookWidget {
  const MultipleHooksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useState(0);
    final label = useMemoized(() => 'Count: ${count.value}');
    return Text(label);
  }
}
