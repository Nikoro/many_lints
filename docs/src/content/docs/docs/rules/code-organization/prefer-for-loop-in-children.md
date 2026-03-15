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

Flags functional list-building patterns like `.map().toList()`, `List.generate()`, `.fold()`, and spread with `.map()` that can be replaced with Dart's collection-for syntax. Collection-for is more idiomatic, avoids intermediate allocations, and reads more naturally in widget trees.

## Why use this rule

Collection-for syntax (`[for (final item in items) Widget(item)]`) is the idiomatic Dart way to build lists inline. It avoids creating intermediate iterables, integrates naturally with collection-if for conditional elements, and is easier to read in deeply nested widget trees than chained method calls.

**See also:** [Flutter - Column children](https://api.flutter.dev/flutter/widgets/Column/children.html) | [Flutter - Row children](https://api.flutter.dev/flutter/widgets/Row/children.html)

## Don't

```dart
// .map().toList()
Column(
  children: items.map((item) => Text(item)).toList(),
);

// spread with .map()
Column(
  children: [
    const Text('Header'),
    ...items.map((item) => Text(item)),
  ],
);

// List.generate()
Column(
  children: List.generate(5, (index) => Text('Item $index')),
);

// .fold() to accumulate widgets
final widgets = items.fold<List<Widget>>([], (list, item) {
  list.add(Text(item));
  return list;
});
```

## Do

```dart
// collection-for syntax
Column(
  children: [for (final item in items) Text(item)],
);

// collection-for with index
Column(
  children: [for (var i = 0; i < 5; i++) Text('Item $i')],
);

// mixed with other children
Column(
  children: [
    const Text('Header'),
    for (final item in items) Text(item),
    const Text('Footer'),
  ],
);
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_for_loop_in_children: false
```
