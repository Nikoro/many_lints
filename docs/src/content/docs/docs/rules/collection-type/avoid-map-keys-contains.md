---
title: avoid_map_keys_contains
description: "Use containsKey() instead of .keys.contains() for better performance."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_map_keys_contains
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Using `map.keys.contains(key)` iterates through all keys to check for existence, while `map.containsKey(key)` performs a direct hash lookup. This rule catches the slower pattern and suggests the more efficient alternative.

## Why use this rule

`Map.keys` returns an `Iterable` that must be traversed linearly to check for a key, making it O(n). `Map.containsKey()` uses the map's hash table directly and runs in O(1). For large maps, the performance difference is significant.

**See also:** [Map.containsKey](https://api.dart.dev/stable/dart-core/Map/containsKey.html)

## Don't

```dart
void example() {
  final map = {'hello': 'world', 'foo': 'bar'};

  // Use containsKey() instead
  final exists = map.keys.contains('hello');

  // Also in conditions
  if (map.keys.contains('foo')) {
    print('found');
  }
}
```

## Do

```dart
void example() {
  final map = {'hello': 'world', 'foo': 'bar'};

  final exists = map.containsKey('hello');

  if (map.containsKey('foo')) {
    print('found');
  }
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_map_keys_contains: false
```
