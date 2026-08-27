---
title: avoid_unsafe_collection_methods
description: "Check for emptiness before using first, last, single or reduce"
sidebar:
  label: avoid_unsafe_collection_methods
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection Type</span>

Flags `first`, `last`, `single` and `reduce` on a named collection that has no emptiness check anywhere in the enclosing function. All four throw a `StateError` on an empty iterable.

## Don't

The list is non-empty in every test and every demo, so this ships and crashes on the first user whose account has no activity:

```dart
String latestActivityLabel(List<String> entries) {
  return entries.last;
}
```

Because the throw comes from `dart:core`, the stack trace points at framework code rather than at the line that assumed a value was there.

## Do

Guard the access and say what happens when there is nothing:

```dart
String latestActivityLabel(List<String> entries) {
  if (entries.isEmpty) return 'No activity yet';
  return entries.last;
}
```

Or take the null-returning variant and handle the absence at the call site:

```dart
String latestActivityLabel(List<String> entries) {
  return entries.lastOrNull ?? 'No activity yet';
}
```

`firstOrNull`, `lastOrNull` and `singleOrNull` come from [`package:collection`](https://pub.dev/packages/collection).

### `reduce` needs a seed, not a guard

`reduce` throws for the same reason, but the fix is usually `fold` — a seed value makes the empty case meaningful instead of exceptional:

```dart
// Don't
int totalCents(List<int> amounts) {
  return amounts.reduce((a, b) => a + b);
}
```

```dart
// Do — an empty basket costs zero
int totalCents(List<int> amounts) {
  return amounts.fold(0, (a, b) => a + b);
}
```

## Known limitations

Detection is deliberately narrow, to keep false positives near zero:

- **Only a directly named receiver is checked** — a local, parameter, or field. A chained expression like `items.where(...).first` has no name to match a guard against and is never reported.
- **Any emptiness check on that name anywhere in the function counts as a guard**, even one in an unrelated branch. Reading `.length`, or calling `firstOrNull`/`lastOrNull`/`singleOrNull` on it, counts too. This over-accepts on purpose.
- **A collection literal with elements** (`[1, 2, 3].first`) is treated as provably non-empty.
- **`singleWhere` is excluded**: it throws when no element *matches*, which an emptiness check would not prevent.

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
