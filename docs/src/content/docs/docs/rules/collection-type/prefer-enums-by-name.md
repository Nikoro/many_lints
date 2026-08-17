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

Using `.firstWhere((e) => e.name == value)` on enum values can be replaced with the built-in `.byName()` method, available since Dart 2.15. The dedicated method is more concise, more readable, and throws a clear `ArgumentError` when the name is not found.

## Why use this rule

`.byName()` was specifically designed for looking up enum values by their string name. It is shorter, self-documenting, and provides a better error message on failure compared to the `firstWhere` approach which throws a generic `StateError`.

**See also:** [Dart enums](https://dart.dev/language/enums)

## Don't

```dart
enum Style { standard, express, overnight }

void example() {
  // Use .byName() instead of .firstWhere()
  final style = Style.values.firstWhere(
    (speed) => speed.name == 'express',
  );

  // Reversed comparison also detected
  final style2 = Style.values.firstWhere(
    (speed) => 'overnight' == speed.name,
  );

  // Variable comparison
  final name = 'underline';
  final style3 = Style.values.firstWhere((speed) => speed.name == name);
}
```

## Do

```dart
enum Style { standard, express, overnight }

void example() {
  final style = Style.values.byName('express');

  final name = 'underline';
  final style2 = Style.values.byName(name);
}
```

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
