---
title: prefer_for_loop_in_children
description: "Prefer collection-for syntax over functional list building in widget children."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_for_loop_in_children
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Code Organization</span>

Flags four functional list-building shapes that collection-for expresses directly: `.map().toList()`, a spread of `.map()`, `List.generate()`, and a `.fold()` that starts from an empty list.

Collection-for allocates no intermediate iterable, sits inline in the `children:` list alongside collection-if, and reads as one list rather than as a chain that must be unwound to see what it produces.

A quick fix rewrites each shape.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` or `preset: pedantic`.

**See also:** [Flutter - Flex.children](https://api.flutter.dev/flutter/widgets/Flex/children.html) | [Dart collection elements](https://dart.dev/language/collections#control-flow-operators)

## Don't

```dart
Widget build(BuildContext context) {
  return Column(
    children: items.map((item) => Text(item)).toList(),
  );
}
```

## Do

```dart
Widget build(BuildContext context) {
  return Column(
    children: [for (final item in items) Text(item)],
  );
}
```

## Examples

### A spread of `.map()`

The shape that appears once a list has a fixed header or footer around the generated part:

```dart
// Don't
Column(
  children: [
    const Text('Header'),
    ...items.map((item) => Text(item)),
  ],
);
```

```dart
// Do
Column(
  children: [
    const Text('Header'),
    for (final item in items) Text(item),
  ],
);
```

The trailing `.toList()` makes no difference — `...items.map(...).toList()` is reported too.

### `List.generate()`

Reported with or without explicit type arguments:

```dart
// Don't
Column(
  children: List.generate(5, (index) => Text('Item $index')),
);

// Don't — the same with type arguments
Column(
  children: List<Widget>.generate(5, (index) => Text('Item $index')),
);
```

```dart
// Do
Column(
  children: [for (var i = 0; i < 5; i++) Text('Item $i')],
);
```

### A `.fold()` that accumulates into an empty list

Only a fold whose seed is an **empty list literal** is reported — that is the one collection-for replaces exactly:

```dart
// Don't
final tiles = items.fold<List<Widget>>([], (acc, item) {
  acc.add(Text(item));
  return acc;
});
```

```dart
// Do
final tiles = [for (final item in items) Text(item)];
```

A fold with any other seed is a real reduction and is left alone:

```dart
// Accepted — not a list build
final total = prices.fold<int>(0, (acc, price) => acc + price);
```

## Known limitations

**`.map()` without `.toList()` is not reported.** A bare `.map()` returns a lazy iterable, which is a different value from a list — rewriting it would change the type.

**`.map().toSet()` is not reported**, for the same reason: the result is a `Set`.

**A `.map()` taking a named function is not reported.** `items.map(buildTile).toList()` has no closure body to inline into the loop.

**`generate` on anything but `List` is not reported.** The receiver is checked, so a custom class with its own `generate` is left alone.

**The rule fires anywhere, not only inside `children:`.** Despite the name, any of these four shapes in ordinary code is reported — the `children:` list is simply where it matters most.

## Configuration

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_for_loop_in_children: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/) — Only use Flexible and Expanded as direct children of Row, Column, or Flex.
- [`avoid_single_child_in_multi_child_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-single-child-in-multi-child-widgets/) — Don't use Column, Row, or other multi-child widgets with only one child.
- [`arguments_ordering`](/many_lints/docs/rules/code-organization/arguments-ordering/) — Keep named arguments in a configured order.
- [`avoid_duplicate_mixins`](/many_lints/docs/rules/code-organization/avoid-duplicate-mixins/) — Flag a mixin applied twice in one `with` clause.
