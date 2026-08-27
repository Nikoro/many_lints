---
title: never_discard_build_context
description: "Don't discard a BuildContext parameter with a wildcard"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: never_discard_build_context
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a `BuildContext` parameter named with a wildcard — `_`, `__`, and so on.

Discarding the context does not remove the need for one. The body still has to look things up, so it reaches for a `context` from an enclosing scope — and that one sits **higher in the tree**. `Theme.of`, `MediaQuery.of` and `Navigator.of` all walk *up* from the element they are given, so an outer context resolves against a different subtree:

- a `Theme` or `MediaQuery` introduced between the two contexts is skipped, and you silently read the ancestor's values;
- `Navigator.of` can find the wrong navigator in a nested-navigator layout;
- if the outer element is deactivated while the callback is still alive, the lookup throws.

The code compiles and usually appears to work, right up until someone inserts a widget between the two contexts.

This rule is in the **`pedantic`** preset, because a builder that performs no inherited lookup can legitimately discard its context.

**See also:** [`BuildContext` API docs](https://api.flutter.dev/flutter/widgets/BuildContext-class.html)

## Enabling this rule

```yaml
# many_lints.yaml
rules:
  never_discard_build_context: true
```

## Don't

```dart
class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      // The builder's own context is discarded, so `Theme.of` runs against
      // the outer one and never sees the dark theme just introduced above.
      child: Builder(
        builder: (_) => Text('Total', style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
```

## Do

Name it and use it. The lookup now resolves against the element the `Builder` created, which is below the `Theme`:

```dart
class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Builder(
        builder: (innerContext) =>
            Text('Total', style: Theme.of(innerContext).textTheme.bodyMedium),
      ),
    );
  }
}
```

### Any builder-shaped callback

The rule reads the parameter's type, not the widget it belongs to, so every callback taking a `BuildContext` is covered:

```dart
// Don't
LayoutBuilder(builder: (_, constraints) => SizedBox(width: constraints.maxWidth));

showDialog<void>(context: context, builder: (_) => const AlertDialog());

// Do
LayoutBuilder(
  builder: (context, constraints) => SizedBox(width: constraints.maxWidth),
);

showDialog<void>(
  context: context,
  builder: (dialogContext) => const AlertDialog(),
);
```

### An underscore prefix is not a discard

`_context` is an ordinary private name and remains usable, so it is never reported:

```dart
// Not reported
Builder(builder: (_context) => Text(Theme.of(_context).toString()));
```

## Quick fix

**Name the parameter `context`** renames the wildcard so the parameter becomes usable.

It is deliberately withheld when something named `context` is already in scope — most often the enclosing `build` method's own parameter, which is the commonest case of all. Renaming there would shadow that name and change which element the *existing* lookups in the body resolve against. The rule still reports; picking the new name is left to you.

## Known limitations

Only an exact `BuildContext` is reported. A subclass with its own meaning is left alone.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  never_discard_build_context: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`use_closest_build_context`](/many_lints/docs/rules/widget-best-practices/use-closest-build-context/) — Use the inner BuildContext from builder callbacks, not the outer one.
- [`avoid_build_context_in_providers`](/many_lints/docs/rules/riverpod-state/avoid-build-context-in-providers/) — Providers outlive widgets, so they should not receive a BuildContext.
- [`avoid_passing_build_context_to_blocs`](/many_lints/docs/rules/bloc-riverpod/avoid-passing-build-context-to-blocs/) — Prevent passing BuildContext to Bloc or Cubit classes.
- [`avoid_too_many_widgets_per_build`](/many_lints/docs/rules/widget-best-practices/avoid-too-many-widgets-per-build/) — Keep one build method within a widget budget.
