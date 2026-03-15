---
title: avoid_accessing_collections_by_constant_index
description: "Avoid accessing a collection by a constant index inside a loop."
sidebar:
  label: avoid_accessing_collections_by_constant_index
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Accessing a collection with a constant index (like `list[0]`) inside a loop is suspicious because the index never changes with the loop iteration. This usually means the access should be moved outside the loop, or the index should depend on the loop variable.

## Why use this rule

A constant index inside a loop always reads the same element on every iteration. This is either redundant work that belongs before the loop, or a bug where the developer forgot to use the loop variable as the index.

**See also:** [Dart collections](https://dart.dev/guides/libraries/library-tour#collections)

## Don't

```dart
const array = [1, 2, 3, 4, 5];

void example() {
  // Constant index inside for-in loop
  for (final element in array) {
    array[0];
  }

  // Constant index inside for loop
  for (var i = 0; i < array.length; i++) {
    array[0];
  }

  // Const variable index inside loop
  const idx = 2;
  for (final element in array) {
    array[idx];
  }

  // Constant index inside while loop
  var j = 0;
  while (j < array.length) {
    array[0];
    j++;
  }
}
```

## Do

```dart
const array = [1, 2, 3, 4, 5];

void example() {
  // Access outside of a loop
  final first = array[0];

  // Loop variable used as index
  for (var i = 0; i < array.length; i++) {
    array[i];
  }

  // Mutable variable used as index
  var idx = 0;
  for (final element in array) {
    array[idx];
    idx++;
  }

  // Expression-based index
  for (var i = 0; i < array.length; i++) {
    array[i + 1];
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_accessing_collections_by_constant_index: false
```
