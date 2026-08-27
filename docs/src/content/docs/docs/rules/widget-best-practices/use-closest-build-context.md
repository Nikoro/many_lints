---
title: use_closest_build_context
description: "Use the inner BuildContext from builder callbacks, not the outer one"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_closest_build_context
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a reference to an **outer** `BuildContext` inside a nested callback that has its own.

`Theme.of`, `MediaQuery.of` and `Navigator.of` all walk *up* from the element they are handed. A `Builder` exists precisely to introduce a new element below the widgets around it, so reaching past its context to the enclosing `build`'s one resolves the lookup against a different subtree — skipping whatever the `Builder` was there to see. The code compiles and usually looks right. The quick fix rewrites the reference to the inner name.

This rule is in the **`recommended`** preset, so it is on with `preset: recommended` and every preset above it. No configuration.

**See also:** [BuildContext](https://api.flutter.dev/flutter/widgets/BuildContext-class.html)

## Don't

```dart
class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (_) {
        // Uses the outer context instead of the Builder's own
        return _label(context);
      },
    );
  }

  Widget _label(BuildContext context) => const Text('Order');
}
```

## Do

```dart
class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (innerContext) {
        // Uses the Builder's own context
        return _label(innerContext);
      },
    );
  }

  Widget _label(BuildContext context) => const Text('Order');
}
```

### Why it matters: the Scaffold case

The commonest real bug this catches is `ScaffoldMessenger.of(context)` reaching above the `Scaffold` that was just built:

```dart
// Don't — the outer context is above the Scaffold, so the lookup throws
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Builder(
      builder: (inner) => TextButton(
        onPressed: () =>
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hi'))),
        child: const Text('Show'),
      ),
    ),
  );
}

// Do — the Builder's context sits below the Scaffold
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Builder(
      builder: (inner) => TextButton(
        onPressed: () =>
            ScaffoldMessenger.of(inner).showSnackBar(const SnackBar(content: Text('Hi'))),
        child: const Text('Show'),
      ),
    ),
  );
}
```

## Known limitations

**Shadowing is not reported.** When the inner parameter is also called `context`, the outer one is simply out of scope and the reference already resolves to the closest context. That is the reason the idiomatic spelling — `builder: (context) => ...` — never trips this rule.

**Only methods are examined.** The rule starts from a method with a `BuildContext` parameter, so an outer context captured by a top-level function or a field initialiser is not tracked.

**Only an exact `BuildContext` parameter counts** on both sides — a callback whose parameter is a subclass is not treated as providing a closer context.

## Turning this rule off

To turn it off:

```yaml
# many_lints.yaml
rules:
  use_closest_build_context: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`never_discard_build_context`](/many_lints/docs/rules/widget-best-practices/never-discard-build-context/) — Don't discard a BuildContext parameter with a wildcard.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`avoid_passing_build_context_to_blocs`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-build-context-to-blocs/) — Prevent passing BuildContext to Bloc or Cubit classes.
- [`avoid_too_many_widgets_per_build`](/many_lints/docs/rules/widget-best-practices/avoid-too-many-widgets-per-build/) — Keep one build method within a widget budget.
