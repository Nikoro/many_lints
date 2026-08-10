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

This rule flags `ListView` widgets that use `shrinkWrap: true`. When shrink-wrapping is enabled, the ListView lays out all of its children eagerly to determine its own size, which defeats the lazy rendering that makes scrollable lists performant.

The quick fix removes the argument. `shrinkWrap` defaults to `false`, so that restores lazy layout without changing anything else — but if the list was shrink-wrapped because it sits inside another scrollable, removing the argument alone will surface an unbounded-height error. That case needs the `CustomScrollView` restructuring shown below, which is a decision the fix cannot make for you.

## Why use this rule

A `ListView` with `shrinkWrap: true` forces Flutter to measure every single child up front, even the ones that are off-screen. For large lists this is extremely expensive and can cause visible jank or even ANRs. The recommended alternative is to use `CustomScrollView` with `SliverList`, which gives you the same nested-scrollable layout without the performance cost.

**See also:** [ListView.shrinkWrap](https://api.flutter.dev/flutter/widgets/ListView/shrinkWrap.html) | [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)

## Don't

```dart
// ListView with shrinkWrap forces eager layout of all children
final list = ListView(shrinkWrap: true);

final builder = ListView.builder(
  shrinkWrap: true,
  itemCount: 10,
  itemBuilder: (context, index) => Text('$index'),
);
```

## Do

```dart
// ListView without shrinkWrap (default lazy rendering)
final list = ListView(children: const [Text('hello')]);

// CustomScrollView with SliverList for nested scroll scenarios
final scroll = CustomScrollView(
  slivers: [
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Text('$index'),
        childCount: 10,
      ),
    ),
  ],
);
```

## Configuration

This rule is in **no preset**, so it is off unless you enable it — with
`preset: all`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_shrink_wrap_in_lists: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_shrink_wrap_in_lists: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
