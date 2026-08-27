---
title: avoid_shrink_wrap_in_lists
description: "Avoid using shrinkWrap in ListView for better scroll performance"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_shrink_wrap_in_lists
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags `shrinkWrap: true` on a `ListView`.

Shrink-wrapping makes the list measure **every** child up front, off-screen ones included, so it can size itself. That is exactly the lazy layout a `ListView` exists to provide. On a long list it is visible jank; on a very long one it is an ANR.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` and `preset: pedantic`. No configuration.

**See also:** [ScrollView.shrinkWrap](https://api.flutter.dev/flutter/widgets/ScrollView/shrinkWrap.html)

## Don't

```dart
final orders = ListView(
  shrinkWrap: true,
  children: const [Text('Order 1'), Text('Order 2')],
);
```

`ListView.builder` is reported the same way:

```dart
final lazyOrders = ListView.builder(
  shrinkWrap: true,
  itemCount: 500,
  itemBuilder: (context, index) => Text('Order $index'),
);
```

## Do

Drop the argument. `shrinkWrap` defaults to `false`, which is what the quick fix does:

```dart
final orders = ListView(
  children: const [Text('Order 1'), Text('Order 2')],
);
```

### When the list is inside another scrollable

This is why `shrinkWrap: true` usually got added — a `ListView` inside a `Column` inside a `SingleChildScrollView` has no bounded height, and removing the argument alone surfaces an unbounded-height error instead.

The fix there is to stop nesting scrollables and make the whole page one `CustomScrollView`. The quick fix cannot make that call for you:

```dart
// Don't — two scrollables, the inner one shrink-wrapped to fit
SingleChildScrollView(
  child: Column(
    children: [
      const Text('Recent orders'),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 500,
        itemBuilder: (context, index) => Text('Order $index'),
      ),
    ],
  ),
);

// Do — one scrollable, laid out lazily
CustomScrollView(
  slivers: [
    const SliverToBoxAdapter(child: Text('Recent orders')),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Text('Order $index'),
        childCount: 500,
      ),
    ),
  ],
);
```

### A fixed-height box is the cheap alternative

When the list really is short and the page really is a `Column`, giving it a height is simpler than restructuring:

```dart
SizedBox(
  height: 240,
  child: ListView.builder(
    itemCount: 4,
    itemBuilder: (context, index) => Text('Order $index'),
  ),
);
```

## Known limitations

Only `ListView` is reported. `GridView`, `SingleChildScrollView` and other `ScrollView` subclasses accept the same argument with the same cost, but are left alone.

`shrinkWrap: someBoolean` is not reported — only a literal `true` is.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  avoid_shrink_wrap_in_lists: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`always_pass_global_key`](/many_lints/docs/rules/widget-best-practices/always-pass-global-key/) — Don't create a GlobalKey inside build.
- [`avoid_conditional_hooks`](/many_lints/docs/rules/widget-best-practices/avoid-conditional-hooks/) — Never call hooks inside conditionals, loops, or ternaries.
- [`avoid_deep_widget_nesting`](/many_lints/docs/rules/widget-best-practices/avoid-deep-widget-nesting/) — Keep a widget tree within a nesting budget.
- [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/) — Only use Flexible and Expanded as direct children of Row, Column, or Flex.
