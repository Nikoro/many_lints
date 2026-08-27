---
title: prefer_add_all
description: "Replace an add-only loop with addAll"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_add_all
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection Type</span>

This rule flags two ways of adding elements one at a time: a `for-in` loop whose only statement adds the loop variable, and several consecutive `add` calls on the same collection.

## Why use this rule

`for (final x in source) target.add(x);` is `target.addAll(source)` spelled out across three lines. The loop form makes the reader decode control flow to recognise a single operation, and it hides the intent from anyone skimming.

The same applies to `target.add(a); target.add(b);` — one `addAll([a, b])` states the intent in a single call.

`addAll` is also free to be more efficient — a `List` can grow its backing store once instead of on each `add`.

## Don't

```dart
List<String> merge(List<String> newItems) {
  final selected = <String>[];

  for (final item in newItems) {
    selected.add(item);
  }

  selected.add('first');
  selected.add('second');

  return selected;
}
```

## Do

```dart
List<String> merge(List<String> newItems) {
  final selected = <String>[];

  selected.addAll(newItems);
  selected.addAll(['first', 'second']);

  return selected;
}
```

## Known limitations

For the loop form, only the exact copy pattern is reported. The rule stays silent whenever the loop does anything else:

- The added value is not the loop variable unchanged — `target.add(x.name)` is a map, not a copy.
- The body has more than one statement, or wraps the `add` in a condition.
- The loop is indexed (`for (var i = 0; ...)`) rather than `for-in`, since it may skip or reorder elements.
- The method is anything other than `add`.

For consecutive calls, a run is broken by any other statement, so `add(a); log(); add(b);` is left alone. The receiver must also be a plain variable or property chain — `items[i].add(x)` may denote a different object on each call — and it must be a collection, since `add` exists on many unrelated types.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_add_all: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`list_all_equatable_fields`](/many_lints/docs/rules/collection-type/list-all-equatable-fields/) — Ensure all fields are listed in Equatable props.
- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
