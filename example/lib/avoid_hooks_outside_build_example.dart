// ignore_for_file: unused_local_variable, unused_element
// ignore_for_file: many_lints/avoid_unnecessary_hook_widgets, many_lints/prefer_overriding_parent_equality, many_lints/prefer_use_prefix

// avoid_hooks_outside_build
//
// Warns when a hook is called outside a hook context. Hook state is stored
// by call position while a hook widget builds; calling a hook from a
// callback, a lifecycle method, or a plain helper has nowhere to write to.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// ❌ Bad: hook inside an event handler
class _BadInCallback extends HookWidget {
  const _BadInCallback();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // LINT: no hook context inside a callback
        final counter = useState(0);
      },
      child: const Text('tap'),
    );
  }
}

// ❌ Bad: hook in a plain helper method
class _BadInHelper extends HookWidget {
  const _BadInHelper();

  void helper() {
    // LINT: not a hook context
    final counter = useState(0);
  }

  @override
  Widget build(BuildContext context) => const Text('x');
}

// ❌ Bad: hook inside a StatelessWidget (no hook machinery at all)
class _BadInStateless extends StatelessWidget {
  const _BadInStateless();

  @override
  Widget build(BuildContext context) {
    // LINT: StatelessWidget is not a HookWidget
    final counter = useState(0);
    return const Text('x');
  }
}

// ❌ Bad: hook in a top-level function that is not itself a hook
void setupThings() {
  // LINT: no hook context
  final counter = useState(0);
}

// ✅ Good: called directly in a HookWidget build
class _GoodInBuild extends HookWidget {
  const _GoodInBuild();

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    return ElevatedButton(
      onPressed: () => counter.value++,
      child: Text('${counter.value}'),
    );
  }
}

// ✅ Good: composing hooks inside another hook
ValueNotifier<int> useCounter() {
  return useState(0);
}

// ✅ Good: private hook functions work the same way
ValueNotifier<String> _useLabel() {
  return useState('');
}

// ✅ Good: inside a HookBuilder's builder
class _GoodInHookBuilder extends StatelessWidget {
  const _GoodInHookBuilder();

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final counter = useState(0);
        return Text('${counter.value}');
      },
    );
  }
}

// ✅ Edge case: a qualified call is never a hook
class _Controller {
  void useResource() {}
}

void edgeCase() {
  // Not an unqualified hook call — no lint
  _Controller().useResource();
}
// ignore_for_file: many_lints/prefer_widget_private_members
