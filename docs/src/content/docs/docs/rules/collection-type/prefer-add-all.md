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

Flags two ways of adding elements one at a time: a `for-in` loop whose only statement adds the loop variable, and two or more consecutive `add` calls on the same collection. The quick fix collapses either into `addAll`.

## Don't

A copy loop is `addAll` spelled out across three lines. The reader has to follow the control flow to work out it is a single operation:

```dart
List<String> withDefaults(List<String> configured) {
  final result = <String>[];

  for (final tag in configured) {
    result.add(tag);
  }

  return result;
}
```

## Do

```dart
List<String> withDefaults(List<String> configured) {
  final result = <String>[];

  result.addAll(configured);

  return result;
}
```

`addAll` also lets a `List` grow its backing store once instead of on each `add`.

### Consecutive `add` calls

A run of `add` calls on the same receiver is one `addAll` with a literal:

```dart
// Don't
final steps = <String>[];
steps.add('validate');
steps.add('persist');
steps.add('notify');

// Do
final steps = <String>[];
steps.addAll(['validate', 'persist', 'notify']);
```

The run has to be uninterrupted. Any other statement between the calls breaks it, and neither half is reported:

```dart
// Accepted — the log call splits the run
steps.add('validate');
log('validating');
steps.add('persist');
```

## Known limitations

For the loop form, only an exact copy is reported. The rule stays silent whenever the loop does anything else:

- **The added value is not the loop variable unchanged.** `result.add(tag.trim())` is a map, not a copy — reach for `addAll(configured.map((t) => t.trim()))` yourself.
- **The body has more than one statement**, or wraps the `add` in a condition.
- **The loop is indexed** (`for (var i = 0; ...)`) rather than `for-in`, since it may skip or reorder elements.
- **The receiver depends on the loop variable.** `groups.putIfAbsent(key(item), () => []).add(item)` distributes the source across a different target per iteration, and has no `addAll` equivalent.
- **The method is anything other than `add`** — `insert`, `addEntries` and the rest are untouched.

For consecutive calls, the receiver must be a plain variable or property chain. `items[i].add(x)` may denote a different object on each call, so it is left alone — and the receiver must resolve to a collection, since `add` exists on many unrelated types.

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
