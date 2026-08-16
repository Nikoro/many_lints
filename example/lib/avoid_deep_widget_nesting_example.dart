// ignore_for_file: many_lints/prefer_single_widget_per_file
// ignore_for_file: many_lints/avoid_wrapping_in_padding
// ignore_for_file: many_lints/prefer_overriding_parent_equality
// ignore_for_file: many_lints/prefer_shorthands_with_constructors
// ignore_for_file: many_lints/avoid_single_child_in_multi_child_widgets
// ignore_for_file: many_lints/prefer_center_over_align

// avoid_deep_widget_nesting
//
// Detects a widget tree nested more deeply than the configured budget.
// Only widget instantiations count, so lists, closures and conditionals
// between them do not inflate the number.

import 'package:flutter/widgets.dart';

// ❌ Bad: the widget that matters sits nine levels in
class BadExample extends StatelessWidget {
  const BadExample({super.key});

  // LINT: nested 9 levels deep, over the limit of 8. The diagnostic is
  // anchored here, at the root of the tree that needs splitting, rather than
  // on the Text at the bottom.
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text('Finally'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ✅ Good: extracting a subtree removes a level and names the part
class GoodExample extends StatelessWidget {
  const GoodExample({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(16), child: const _Content()),
  );
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) => Column(
    children: [Expanded(child: Center(child: Text('Finally')))],
  );
}

// Edge case: a builder closure starts a tree of its own, so its depth is
// counted separately rather than added to the caller's.
class EdgeCase extends StatelessWidget {
  const EdgeCase({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.zero,
      child: Builder(
        builder: (context) => Center(
          child: Padding(
            padding: EdgeInsets.zero,
            child: Center(child: Text('x')),
          ),
        ),
      ),
    ),
  );
}
