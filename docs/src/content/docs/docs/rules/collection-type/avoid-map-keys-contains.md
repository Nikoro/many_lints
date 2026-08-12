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
  final map = {'lat': 52.2, 'lon': 21.0};

  // Use containsKey() instead
  final exists = map.keys.contains('lat');

  // Also in conditions
  if (map.keys.contains('foo')) {
    print('found');
  }
}
```

## Do

```dart
void example() {
  final map = {'lat': 52.2, 'lon': 21.0};

  final exists = map.containsKey('lat');

  if (map.containsKey('foo')) {
    print('found');
  }
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_map_keys_contains: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_map_keys_contains: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
