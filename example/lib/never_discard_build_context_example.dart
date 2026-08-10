// ignore_for_file: many_lints/avoid_returning_widgets, many_lints/prefer_single_widget_per_file, many_lints/use_closest_build_context, many_lints/prefer_overriding_parent_equality
import 'package:flutter/material.dart';

// never_discard_build_context
//
// Warns when a BuildContext parameter is named with a wildcard. Discarding it
// does not remove the need for a context — the body reaches for an outer one,
// which sits higher in the tree and resolves lookups against a different
// subtree.

// ❌ Bad: the builder's own context is thrown away
class BadDiscardedContext extends StatelessWidget {
  const BadDiscardedContext({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      // LINT: `Theme.of` below runs against the outer context
      builder: (_) => Text('hi', style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

// ❌ Bad: discarded even with an explicit type annotation
Widget badTypedDiscard() {
  return Builder(
    // LINT: naming it makes the closest context available
    builder: (BuildContext _) => const Text('hi'),
  );
}

// ❌ Bad: a wildcard in a top-level function signature
// LINT: callers pass a context that this function then cannot use
Widget badTopLevel(BuildContext _) => const Text('hi');

// ✅ Good: the closest context is named and used
class GoodNamedContext extends StatelessWidget {
  const GoodNamedContext({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (innerContext) =>
          Text('hi', style: Theme.of(innerContext).textTheme.bodyMedium),
    );
  }
}

// ✅ Edge case: `_context` is a private name, not a discard — it stays usable
Widget goodPrivateName(BuildContext _context) =>
    Text('hi', style: Theme.of(_context).textTheme.bodyMedium);

// ✅ Edge case: discarding a parameter that is not a BuildContext is fine
Widget goodDiscardsNonContext() {
  return LayoutBuilder(
    builder: (context, _) => Text(MediaQuery.sizeOf(context).toString()),
  );
}
