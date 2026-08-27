---
title: avoid_single_child_in_multi_child_widgets
description: "Don't use Column, Row, or other multi-child widgets with only one child"
sidebar:
  label: avoid_single_child_in_multi_child_widgets
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

Flags a multi-child widget whose `children` list holds exactly one element.

A `Column` with one child does the same thing as the child on its own, plus a layout pass and a level of nesting. Whatever you actually wanted — alignment, padding, sizing — has a single-child widget that says so in its name.

Reported for `Column`, `Row`, `Wrap`, `Flex`, `SliverList`, `SliverMainAxisGroup`, `SliverCrossAxisGroup`, `SliverChildListDelegate`, and `MultiSliver` from `sliver_tools`.

This rule is in the **`opinionated`** preset, so it is on with `preset: opinionated` and `preset: pedantic`. No configuration.

**See also:** [Column](https://api.flutter.dev/flutter/widgets/Column-class.html) | [Row](https://api.flutter.dev/flutter/widgets/Row-class.html)

## Don't

```dart
Scaffold(
  body: Column(
    children: [Text('I am the only child')],
  ),
)
```

## Do

```dart
Scaffold(
  body: Text('I am the only child'),
)
```

### Reach for the single-child widget that names the intent

Most one-child `Column`s exist for an alignment or spacing property. Each has a direct replacement:

```dart
// Don't
final bad = Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [Text('Loading')],
);

// Do
final good = Center(child: Text('Loading'));
```

```dart
// Don't
final bad = Row(
  children: [
    Padding(padding: EdgeInsets.all(16), child: Text('Total')),
  ],
);

// Do
final good = Padding(padding: EdgeInsets.all(16), child: Text('Total'));
```

### Slivers too

```dart
// Don't
final bad = CustomScrollView(
  slivers: [
    SliverMainAxisGroup(
      slivers: [SliverToBoxAdapter(child: Text('Header'))],
    ),
  ],
);

// Do
final good = CustomScrollView(
  slivers: [SliverToBoxAdapter(child: Text('Header'))],
);
```

## Known limitations

A list whose single element is a spread (`...items`), a collection-`for`, or a map entry is **not** reported — the number of children at run time is not one:

```dart
// Not reported: `...items` may expand to any number of children
Column(children: [...items])
```

An `if` element counts as one child only when every branch it has is itself a plain widget, so `Column(children: [if (isWide) Text('a') else Text('b')])` is reported while `Column(children: [if (isWide) ...wideParts])` is not.

Only a list *literal* is examined. `Column(children: buildRows())` is opaque and left alone.

## Turning this rule off

```yaml
# many_lints.yaml
rules:
  avoid_single_child_in_multi_child_widgets: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_flexible_outside_flex`](/many_lints/docs/rules/widget-best-practices/avoid-flexible-outside-flex/) — Only use Flexible and Expanded as direct children of Row, Column, or Flex.
- [`prefer_for_loop_in_children`](/many_lints/docs/rules/code-organization/prefer-for-loop-in-children/) — Prefer collection-for syntax over functional list building in widget children.
- [`avoid_returning_widgets`](/many_lints/docs/rules/widget-best-practices/avoid-returning-widgets/) — Extract widget helper methods into separate widget classes.
- [`avoid_too_many_widgets_per_build`](/many_lints/docs/rules/widget-best-practices/avoid-too-many-widgets-per-build/) — Keep one build method within a widget budget.
