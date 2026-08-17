---
title: avoid_unsafe_collection_methods
description: "Check for emptiness before using first, last, single or reduce"
sidebar:
  label: avoid_unsafe_collection_methods
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection Type</span>

This rule flags `first`, `last`, `single` and `reduce` used on a collection that has no emptiness check anywhere in the enclosing function.

## Why use this rule

All four throw a `StateError` on an empty iterable. Because the throw originates in `dart:core`, the stack trace points at framework code rather than the line that made the assumption — and the failure only appears once real data happens to be empty, which is usually in production rather than in tests.

Dart offers direct replacements: `firstOrNull`, `lastOrNull` and `singleOrNull` from `package:collection`, or `fold` instead of `reduce` when a seed value makes sense.

## Don't

```dart
String firstName(List<User> users) {
  // Throws when the list is empty
  return users.first.name;
}

int total(List<int> amounts) {
  return amounts.reduce((a, b) => a + b);
}
```

## Do

```dart
String? firstName(List<User> users) {
  if (users.isEmpty) return null;
  return users.first.name;
}

// Or use the null-returning variant
String? firstNameOrNull(List<User> users) {
  return users.firstOrNull?.name;
}

// fold supplies a seed, so an empty list is fine
int total(List<int> amounts) {
  return amounts.fold(0, (a, b) => a + b);
}
```

## Known limitations

Detection is deliberately narrow, to keep false positives near zero:

- Only a directly named receiver is checked — a local, parameter, or field. A chained expression like `items.where(...).first` has no name to match a guard against and is never reported.
- Any emptiness check on that name anywhere in the function counts as a guard, even one in an unrelated branch. This over-accepts on purpose.
- A collection literal with elements (`[1, 2, 3].first`) is treated as provably non-empty.
- `singleWhere` is excluded: it throws when no element *matches*, which an emptiness check would not prevent.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_unsafe_collection_methods: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_unsafe_collection_methods: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`prefer_safe_collection_access`](/many_lints/docs/rules/fpdart/prefer-safe-collection-access/) — list.first throws where list.head returns None.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
