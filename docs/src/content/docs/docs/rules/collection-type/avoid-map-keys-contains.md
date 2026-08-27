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

Flags `map.keys.contains(key)`, which walks every key in order. `map.containsKey(key)` asks the hash table directly. The quick fix rewrites it.

## Don't

`Map.keys` is an `Iterable`, so `contains` on it is a linear scan — O(n) per call, and this one runs once per row:

```dart
List<String> missingTranslations(
  Map<String, String> translations,
  List<String> requiredKeys,
) {
  return requiredKeys
      .where((key) => !translations.keys.contains(key))
      .toList();
}
```

## Do

```dart
List<String> missingTranslations(
  Map<String, String> translations,
  List<String> requiredKeys,
) {
  return requiredKeys.where((key) => !translations.containsKey(key)).toList();
}
```

### Any map-typed expression counts

The receiver does not have to be a plain variable — a field or any map-typed expression is matched just the same:

```dart
class Response {
  const Response(this.headers);

  final Map<String, String> headers;

  // Don't
  bool get isCached => headers.keys.contains('etag');

  // Do
  bool get isCachedFixed => headers.containsKey('etag');
}
```

## Known limitations

**Only `.keys` is checked.** `map.values.contains(x)` genuinely has no hash-backed equivalent — `containsValue` is linear too — so it is never reported.

**The receiver's static type must resolve to a `Map`.** A `dynamic` receiver, or one whose type the analyzer cannot infer, is left alone.

**See also:** [Map.containsKey](https://api.dart.dev/stable/dart-core/Map/containsKey.html)

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

## Related rules

- [`avoid_missing_enum_constant_in_map`](/many_lints/docs/rules/collection-type/avoid-missing-enum-constant-in-map/) — Cover every enum constant in a map keyed by that enum.
- [`map_keys_ordering`](/many_lints/docs/rules/code-organization/map-keys-ordering/) — Keep map literal keys in a configured order.
- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
