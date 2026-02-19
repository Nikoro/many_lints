// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// prefer_use_callback
//
// Prefer useCallback over useMemoized when memoizing function expressions.
// useCallback is specifically designed for callbacks and is more semantically
// correct than wrapping a function in useMemoized.

// ❌ Bad: Using useMemoized to memoize a function expression
class BadCallbackWidget extends HookWidget {
  const BadCallbackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // LINT: useMemoized wrapping a closure — use useCallback instead
    final onPressed = useMemoized(
      () => () {
        debugPrint('pressed');
      },
    );

    // LINT: useMemoized wrapping a closure with keys
    final onTap = useMemoized(
      () => () {
        debugPrint('tapped');
      },
      [],
    );

    return ElevatedButton(onPressed: onPressed, child: const Text('Tap'));
  }
}

// ❌ Bad: Using useMemoized with a tear-off
class BadTearOffWidget extends HookWidget {
  const BadTearOffWidget({super.key});

  void _handlePress() => debugPrint('pressed');

  @override
  Widget build(BuildContext context) {
    // LINT: useMemoized wrapping a tear-off — use useCallback instead
    final onPressed = useMemoized(() => _handlePress);
    return ElevatedButton(onPressed: onPressed, child: const Text('Tap'));
  }
}

// ✅ Good: Using useCallback for memoizing functions
class GoodCallbackWidget extends HookWidget {
  const GoodCallbackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final onPressed = useCallback(() {
      debugPrint('pressed');
    }, []);

    return ElevatedButton(onPressed: onPressed, child: const Text('Tap'));
  }
}

// ✅ Good: Using useMemoized for non-function values
class GoodMemoizedWidget extends HookWidget {
  const GoodMemoizedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final expensiveValue = useMemoized(() => List.generate(100, (i) => i));
    return Text('${expensiveValue.length}');
  }
}
