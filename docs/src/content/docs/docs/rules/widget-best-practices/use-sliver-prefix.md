---
title: use_sliver_prefix
description: "Name widgets that return slivers with a Sliver prefix"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_sliver_prefix
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Widget Best Practices</span>

This rule warns when a widget's `build` method returns a sliver widget (like `SliverList`, `SliverAppBar`, `SliverToBoxAdapter`) but the class name does not start with `Sliver`. Slivers and non-sliver widgets are not interchangeable, so making the distinction visible in the name prevents layout errors.

## Why use this rule

If you drop a sliver-returning widget into a `Column` or `Row`, Flutter throws a confusing runtime error about "RenderSliver" not being a "RenderBox". A `Sliver` prefix on the class name makes it immediately obvious that the widget belongs inside a `CustomScrollView`, not a regular box layout. This naming convention is used throughout the Flutter framework itself.

**See also:** [Slivers](https://api.flutter.dev/flutter/widgets/CustomScrollView-class.html)

## Don't

```dart
// Returns a sliver but name does not indicate it
class MyAdapter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Text('hello'));
  }
}

class ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: SliverChildListDelegate([]));
  }
}
```

## Do

```dart
// Sliver prefix makes the contract clear
class SliverMyAdapter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: Text('hello'));
  }
}

class SliverProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: SliverChildListDelegate([]));
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      use_sliver_prefix: false
```
