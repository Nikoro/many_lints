---
title: avoid_collection_equality_checks
description: "Avoid comparing collections with == or != as it checks reference equality, not contents."
sidebar:
  label: avoid_collection_equality_checks
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Flags `==` or `!=` where either side is a `List`, `Set`, `Map` or `Iterable`. Collections have no deep equality in Dart: two distinct instances are never equal, however identical their contents.

## Don't

The comparison compiles and always answers `false`, so the branch it guards never runs:

```dart
bool hasSelectionChanged(List<String> previous, List<String> current) {
  return previous != current;
}
```

Here `hasSelectionChanged` returns `true` for every call — including when nothing changed — because `previous` and `current` are separate objects.

## Do

Compare contents with `DeepCollectionEquality` from `package:collection`:

```dart
import 'package:collection/collection.dart';

bool hasSelectionChanged(List<String> previous, List<String> current) {
  return !const DeepCollectionEquality().equals(previous, current);
}
```

For a flat list, `ListEquality` is cheaper and states the depth you expect:

```dart
import 'package:collection/collection.dart';

bool hasSelectionChanged(List<String> previous, List<String> current) {
  return !const ListEquality<String>().equals(previous, current);
}
```

### Comparing a field inside a model

The same trap sits in a hand-written `==`, where it silently makes every instance unequal:

```dart
// Don't
class Cart {
  const Cart(this.items);

  final List<String> items;

  @override
  bool operator ==(Object other) => other is Cart && items == other.items;
}
```

```dart
// Do
import 'package:collection/collection.dart';

class Cart {
  const Cart(this.items);

  final List<String> items;

  @override
  bool operator ==(Object other) =>
      other is Cart && const ListEquality<String>().equals(items, other.items);

  @override
  int get hashCode => const ListEquality<String>().hash(items);
}
```

## Known limitations

Three shapes are deliberately accepted:

- **A null check.** `items == null` and `items != null` are the normal way to test presence and are never reported.
- **Two compile-time constants.** `const [1, 2] == const [1, 2]` is `true`, because constant collections are canonicalized to one instance. Both sides must be `const` for the exemption to apply.
- **Neither side a collection.** At least one operand must be a `List`, `Set`, `Map` or `Iterable`, so ordinary value comparisons are untouched.

**See also:** [collection package](https://pub.dev/packages/collection)

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_collection_equality_checks: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_overriding_parent_equality`](/many_lints/docs/rules/collection-type/prefer-overriding-parent-equality/) — Override == and hashCode when the parent class overrides them.
- [`list_all_equatable_fields`](/many_lints/docs/rules/collection-type/list-all-equatable-fields/) — Ensure all fields are listed in Equatable props.
- [`prefer_equatable_mixin`](/many_lints/docs/rules/type-annotations/prefer-equatable-mixin/) — Prefer using EquatableMixin instead of extending Equatable.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
