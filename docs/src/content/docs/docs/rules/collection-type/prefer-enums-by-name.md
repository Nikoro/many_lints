---
title: prefer_enums_by_name
description: "Use .byName() instead of .firstWhere() to look up enum values by name."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_enums_by_name
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Flags `EnumType.values.firstWhere((e) => e.name == value)`, which the built-in `.byName()` does in one call. The quick fix rewrites it.

## Don't

The usual place this appears is decoding an enum out of JSON or a query parameter:

```dart
enum ShippingSpeed { standard, express, overnight }

ShippingSpeed parseSpeed(String raw) {
  return ShippingSpeed.values.firstWhere((speed) => speed.name == raw);
}
```

## Do

```dart
enum ShippingSpeed { standard, express, overnight }

ShippingSpeed parseSpeed(String raw) {
  return ShippingSpeed.values.byName(raw);
}
```

`.byName()` throws an `ArgumentError` naming the enum and the bad value, where `firstWhere` throws a bare `StateError` with no clue which lookup failed.

### The comparison written the other way round

```dart
// Don't
final speed = ShippingSpeed.values.firstWhere(
  (s) => 'express' == s.name,
);

// Do
final speed = ShippingSpeed.values.byName('express');
```

### Supplying a fallback instead of throwing

`firstWhere` with an `orElse` is still reported — pair `.byName()` with a
`try`/`catch`, or reach for the null-returning form from `package:collection`:

```dart
// Don't
final speed = ShippingSpeed.values.firstWhere(
  (s) => s.name == raw,
  orElse: () => ShippingSpeed.standard,
);

// Do
final speed = ShippingSpeed.values.asNameMap()[raw] ?? ShippingSpeed.standard;
```

## Known limitations

Only a comparison against `.name` is matched. A lookup keyed on a custom field — `Currency.values.firstWhere((c) => c.code == raw)` — has no `byName` equivalent and is never reported.

The callback must be a single-parameter function expression whose body is one comparison — `(e) { return e.name == raw; }` counts, a multi-statement body does not. A tear-off passed as the predicate is left alone.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`prefer_enums_by_name: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_enums_by_name: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_missing_enum_constant_in_map`](/many_lints/docs/rules/collection-type/avoid-missing-enum-constant-in-map/) — Cover every enum constant in a map keyed by that enum.
- [`enum_constants_ordering`](/many_lints/docs/rules/code-organization/enum-constants-ordering/) — Keep enum constants in a configured order.
- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
