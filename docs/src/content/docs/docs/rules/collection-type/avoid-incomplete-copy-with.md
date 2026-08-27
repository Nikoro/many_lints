---
title: avoid_incomplete_copy_with
description: "Ensure copyWith methods include all constructor parameters."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_incomplete_copy_with
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Flags a `copyWith` whose parameters do not cover every parameter of the class's unnamed constructor. The diagnostic names the missing ones, and the quick fix adds them.

## Don't

This is what adding a field looks like when `copyWith` is not updated with it. Nothing breaks at the definition; the loss shows up at every call site, silently:

```dart
class Filters {
  const Filters({
    required this.query,
    required this.category,
    required this.inStockOnly,
  });

  final String query;
  final String category;
  final bool inStockOnly;

  Filters copyWith({String? query, String? category}) {
    return Filters(
      query: query ?? this.query,
      category: category ?? this.category,
      inStockOnly: inStockOnly,
    );
  }
}
```

`filters.copyWith(inStockOnly: true)` does not compile, so the caller writes the whole constructor out by hand — or, worse, drops the toggle.

## Do

```dart
class Filters {
  const Filters({
    required this.query,
    required this.category,
    required this.inStockOnly,
  });

  final String query;
  final String category;
  final bool inStockOnly;

  Filters copyWith({String? query, String? category, bool? inStockOnly}) {
    return Filters(
      query: query ?? this.query,
      category: category ?? this.category,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }
}
```

### A class with no `copyWith` is left alone

The rule never asks you to add one — it only keeps an existing `copyWith` in step with the constructor:

```dart
// No warning: nothing to keep in sync
class Coordinates {
  const Coordinates({required this.lat, required this.lon});

  final double lat;
  final double lon;
}
```

## Known limitations

**Only the unnamed constructor is compared.** A class whose primary constructor is named — `const Filters.initial({...})` — is not checked, since the rule finds no default constructor to compare against.

**Parameters are matched by name only.** A `copyWith` that declares the right names but ignores one in its body is not reported; the check is on the signature.

**Nullable fields need a sentinel, and the rule does not know that.** Adding `String? note` to `copyWith` makes `copyWith(note: null)` indistinguishable from "leave it alone". The rule asks for the parameter; choosing a sentinel or a wrapper to express "set to null" is yours.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_incomplete_copy_with: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_incomplete_copy_with: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
- [`avoid_duplicate_collection_elements`](/many_lints/docs/rules/collection-type/avoid-duplicate-collection-elements/) — Don't repeat the same element in a collection literal.
