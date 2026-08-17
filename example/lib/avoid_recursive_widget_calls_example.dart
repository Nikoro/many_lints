// ignore_for_file: unused_element
// ignore_for_file: many_lints/avoid_returning_widgets, many_lints/avoid_single_child_in_multi_child_widgets, many_lints/avoid_unnecessary_stateful_widgets, many_lints/prefer_immutable_bloc_state, many_lints/prefer_overriding_parent_equality

// avoid_recursive_widget_calls
//
// Warns when a widget's build method instantiates the widget itself
// unconditionally. That recurses until the stack overflows as soon as the
// widget is mounted.

import 'package:flutter/material.dart';

// ❌ Bad: builds itself with no terminating condition
class _BadRecursive extends StatelessWidget {
  const _BadRecursive();

  @override
  Widget build(BuildContext context) {
    // LINT: infinite recursion — crashes on mount
    return const _BadRecursive();
  }
}

// ❌ Bad: self-construction nested in a child list is still unconditional
class _BadNested extends StatelessWidget {
  const _BadNested();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        // LINT: still recurses forever
        _BadNested(),
      ],
    );
  }
}

// ❌ Bad: a State building its own StatefulWidget
class _BadStateful extends StatefulWidget {
  const _BadStateful();

  @override
  State<_BadStateful> createState() => _BadStatefulState();
}

class _BadStatefulState extends State<_BadStateful> {
  @override
  Widget build(BuildContext context) {
    // LINT: the State builds the widget it belongs to
    return const _BadStateful();
  }
}

// ✅ Good: builds something else
class _GoodSimple extends StatelessWidget {
  const _GoodSimple();

  @override
  Widget build(BuildContext context) => const Text('Hello');
}

// ✅ Good: recursion with a terminating guard
class _GoodTreeNode extends StatelessWidget {
  const _GoodTreeNode(this.depth);

  final int depth;

  @override
  Widget build(BuildContext context) {
    if (depth == 0) return const SizedBox();
    return _GoodTreeNode(depth - 1);
  }
}

// ✅ Edge case: lazily built inside a builder callback
class _GoodLazy extends StatelessWidget {
  const _GoodLazy();

  @override
  Widget build(BuildContext context) {
    // Constructed on demand, not during this build — no lint
    return Builder(builder: (context) => const _GoodLazy());
  }
}

// ✅ Edge case: constructing itself outside build is not recursion
class _GoodFactory extends StatelessWidget {
  const _GoodFactory();

  Widget makeAnother() => const _GoodFactory();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
// ignore_for_file: many_lints/prefer_widget_private_members
