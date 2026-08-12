---
title: never_discard_build_context
description: "Don't discard a BuildContext parameter with a wildcard"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: never_discard_build_context
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule flags a `BuildContext` parameter named with a wildcard — `_`, `__`, and so on. Discarding the parameter throws away the closest context, which is usually the only correct one to use.

## Why use this rule

Discarding a context does not remove the need for one. The body still has to look things up, so it reaches for a `context` from an enclosing scope — and that context sits **higher in the widget tree**.

That difference is not cosmetic. `Theme.of`, `MediaQuery.of` and `Navigator.of` walk *up* from the element they are given, so an outer context resolves against a different subtree. The consequences are real:

- A `Theme` or `MediaQuery` introduced between the two contexts is skipped entirely, so you silently read the ancestor's values.
- `Navigator.of` may find the wrong navigator in a nested-navigator layout.
- If the outer element is deactivated while the callback is still alive, the lookup throws.

The failure mode is what makes this worth linting: the code compiles, and usually appears to work, right up until someone inserts a widget between the two contexts.

**See also:** [`BuildContext` API docs](https://api.flutter.dev/flutter/widgets/BuildContext-class.html), [Flutter: `of` accessors and `BuildContext`](https://docs.flutter.dev/resources/architectural-overview#widgets)

## Don't

```dart
// The builder's own context is discarded, so `Theme.of` runs against the
// outer context and skips any theme introduced in between.
Widget build(BuildContext context) {
  return Builder(
    builder: (_) => Text('hi', style: Theme.of(context).textTheme.bodyMedium),
  );
}
```

## Do

```dart
Widget build(BuildContext context) {
  return Builder(
    builder: (innerContext) =>
        Text('hi', style: Theme.of(innerContext).textTheme.bodyMedium),
  );
}
```

## Quick fix

**Name the parameter `context`** renames the wildcard so the parameter becomes usable.

The fix is deliberately withheld when something named `context` is already in scope — most often the enclosing `build` method's own parameter. Renaming there would shadow that name and change which element the existing lookups in the body resolve against, so the rule still reports but leaves the choice of name to you.

## Known limitations

Only an exact `BuildContext` is reported. A subclass is left alone, since renaming a parameter with its own meaning is not obviously right.

A name such as `_context` is not a discard — it is a private name that remains usable — and is not reported.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  never_discard_build_context: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  never_discard_build_context: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
