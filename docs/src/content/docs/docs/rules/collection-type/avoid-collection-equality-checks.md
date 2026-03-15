---
title: avoid_collection_equality_checks
description: "Avoid comparing collections with == or != as it checks reference equality, not contents."
sidebar:
  label: avoid_collection_equality_checks
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Collections in Dart (List, Set, Map) use reference equality by default, not structural equality. Comparing two collections with `==` or `!=` almost never produces the intended result because two distinct instances with identical contents are not considered equal.

## Why use this rule

Using `==` on collections is a common source of bugs. Two lists with the same elements will return `false` when compared with `==` because they are different objects in memory. Use `DeepCollectionEquality` from the `collection` package or compare individual elements instead.

**See also:** [Dart collections](https://dart.dev/guides/libraries/library-tour#collections) | [collection package](https://pub.dev/packages/collection)

## Don't

```dart
void example() {
  final list1 = [1, 2, 3];
  final list2 = [1, 2, 3];

  // Reference equality, not deep equality
  final same = list1 == list2; // always false!

  final set1 = {1, 2};
  final set2 = {1, 2};

  // Same problem with sets
  final sameSet = set1 == set2;

  final map1 = {'a': 1};
  final map2 = {'a': 1};

  // Same problem with maps
  final sameMap = map1 != map2;
}
```

## Do

```dart
void example() {
  // Const collections are fine — they are canonicalized
  final same = const [1, 2] == const [1, 2]; // true

  // Null checks are fine
  final List<int>? maybeList = null;
  final isNull = maybeList == null;

  // Non-collection equality is fine
  final a = 1;
  final b = 1;
  final sameInt = a == b;

  // Use DeepCollectionEquality from the `collection` package:
  // import 'package:collection/collection.dart';
  // final eq = DeepCollectionEquality().equals(list1, list2);
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_collection_equality_checks: false
```
