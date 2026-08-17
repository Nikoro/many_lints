---
title: prefer_any_or_every
description: "Use .any() or .every() instead of .where().isEmpty/.isNotEmpty."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_any_or_every
---

<span class="rule-badge rule-badge--version">v0.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Using `.where(predicate).isNotEmpty` can be replaced with `.any(predicate)`, and `.where(predicate).isEmpty` can be replaced with `.every(negatedPredicate)`. The dedicated methods are more readable and can short-circuit evaluation, avoiding the creation of an intermediate lazy iterable.

## Why use this rule

`.any()` and `.every()` express intent more clearly and stop iterating as soon as the result is determined. `.where()` creates an intermediate `Iterable` that is unnecessary when you only need a boolean check.

**See also:** [Iterable.any](https://api.dart.dev/stable/dart-core/Iterable/any.html) | [Iterable.every](https://api.dart.dev/stable/dart-core/Iterable/every.html) | [Dart lint: prefer_iterable_whereType](https://dart.dev/tools/linter-rules/prefer_iterable_whereType)

## Don't

```dart
class Example {
  final List<int> numbers = [1, 2, 3, 4, 5];

  void checkNumbers() {
    // Use .any() instead of .where().isNotEmpty
    final hasEven = numbers.where((n) => n.isEven).isNotEmpty;

    // Use .every() instead of .where().isEmpty
    final allPositive = numbers.where((n) => n < 0).isEmpty;
  }
}
```

## Do

```dart
class Example {
  final List<int> numbers = [1, 2, 3, 4, 5];

  void checkNumbers() {
    final hasEven = numbers.any((n) => n.isEven);

    final allPositive = numbers.every((n) => n >= 0);
  }
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`prefer_any_or_every: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_any_or_every: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
- [`avoid_duplicate_collection_elements`](/many_lints/docs/rules/collection-type/avoid-duplicate-collection-elements/) — Don't repeat the same element in a collection literal.
