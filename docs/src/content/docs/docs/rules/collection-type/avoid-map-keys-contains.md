---
title: avoid_map_keys_contains
description: "Use containsKey() instead of .keys.contains()."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_map_keys_contains
---

| Property | Value |
|----------|-------|
| **Rule name** | `avoid_map_keys_contains` |
| **Category** | Collection & Type |
| **Severity** | Warning |
| **Has quick fix** | Yes |

## Problem

Use containsKey() instead of .keys.contains().

## Suggestion

Replace with containsKey() for better performance.

## Example

```dart
// ignore_for_file: unused_local_variable

// avoid_map_keys_contains
//
// Warns when using .keys.contains() instead of containsKey().
// .keys.contains is significantly slower than containsKey.

// ❌ Bad: Using .keys.contains()
void bad() {
  final map = {'hello': 'world', 'foo': 'bar'};

  // LINT: Use containsKey() instead
  final exists = map.keys.contains('hello');

  // LINT: Also in conditions
  if (map.keys.contains('foo')) {
    print('found');
  }
}

// ✅ Good: Using containsKey()
void good() {
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
