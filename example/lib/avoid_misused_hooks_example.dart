// ignore_for_file: unused_local_variable, unused_element

// avoid_misused_hooks
//
// Warns when a hook is called inside a loop. Hook state is addressed by
// call position, so a data-dependent number of hook calls shifts every
// later hook into a different slot.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// ❌ Bad: hook count depends on the data
class _BadForInLoop extends HookWidget {
  const _BadForInLoop(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    for (final item in items) {
      // LINT: one hook per item — positions shift when items change
      final controller = useState(item);
    }
    return const SizedBox();
  }
}

// ❌ Bad: classic for loop
class _BadForLoop extends HookWidget {
  const _BadForLoop();

  @override
  Widget build(BuildContext context) {
    for (var i = 0; i < 3; i++) {
      // LINT: hooks must run the same number of times each build
      final value = useState(i);
    }
    return const SizedBox();
  }
}

// ❌ Bad: while loop
class _BadWhileLoop extends HookWidget {
  const _BadWhileLoop();

  @override
  Widget build(BuildContext context) {
    var i = 0;
    while (i < 3) {
      // LINT: same problem
      final value = useState(i);
      i++;
    }
    return const SizedBox();
  }
}

// ❌ Bad: for element inside a collection literal
class _BadForElement extends HookWidget {
  const _BadForElement();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LINT: a for element is still a loop
        for (var i = 0; i < 3; i++) Text('${useState(i).value}'),
      ],
    );
  }
}

// ✅ Good: one hook call, regardless of item count
class _GoodMemoized extends HookWidget {
  const _GoodMemoized(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final controllers = useMemoized(
      () => items.map((item) => TextEditingController(text: item)).toList(),
      [items],
    );
    return const SizedBox();
  }
}

// ✅ Good: hook before the loop, loop does no hook work
class _GoodHookBeforeLoop extends HookWidget {
  const _GoodHookBeforeLoop();

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    for (var i = 0; i < 3; i++) {
      counter.value = i;
    }
    return Text('${counter.value}');
  }
}

// ✅ Edge case: a qualified call in a loop is not a hook
class _Controller {
  void useResource() {}
}

void edgeCase() {
  final controller = _Controller();
  for (var i = 0; i < 3; i++) {
    // Not an unqualified hook call — no lint
    controller.useResource();
  }
}
