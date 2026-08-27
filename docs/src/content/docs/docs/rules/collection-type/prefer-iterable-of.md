---
title: prefer_iterable_of
description: "Use List.of() / Set.of() instead of .from() for type-safe copies."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_iterable_of
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Flags `List.from()` and `Set.from()` where the source element type already fits the target. `.from()` takes `Iterable<dynamic>` and casts at runtime; `.of()` is statically typed, so a mismatch is a compile error instead of a crash. The quick fix rewrites it.

## Don't

Copying a list to make it mutable is the everyday case, and `.from()` throws away the element type on the way through:

```dart
List<String> editableCopy(List<String> tags) {
  return List<String>.from(tags);
}
```

## Do

```dart
List<String> editableCopy(List<String> tags) {
  return List<String>.of(tags);
}
```

Same result, but the compiler now checks that `tags` really holds `String`s. Under `.from()` a `List<Object>` slips in and fails later, at the first read.

### Widening to a supertype

`.of()` accepts a subtype source, so an upcast copy needs no runtime check either:

```dart
// Don't
final scores = <int>[90, 85];
final asNums = List<num>.from(scores);

// Do
final asNums = List<num>.of(scores);
```

### Sets behave the same way

```dart
// Don't
final unique = Set<String>.from(tags);

// Do
final unique = Set<String>.of(tags);
```

### When `.from()` is the right call

`.from()` earns its runtime cast when you are genuinely narrowing — the source holds a supertype and you are asserting the contents are narrower. That is not reported:

```dart
final mixed = <num>[1, 2, 3];

// Accepted: int is not guaranteed by the source type, so the cast is the point
final ints = List<int>.from(mixed);
```

## Known limitations

**Only `List` and `Set` are checked.** `Map.from()` has no `.of()` counterpart with the same signature and is never reported.

**A `dynamic` target always reports.** `List.from(source)` with no type argument infers `List<dynamic>`, where `.from()` and `.of()` are equivalent — so `.of()` is preferred as the clearer default.

**The source must have a resolvable element type.** A `dynamic` source, or one the analyzer cannot infer, is left alone.

**See also:** [List.of](https://api.dart.dev/stable/dart-core/List/List.of.html) | [Set.of](https://api.dart.dev/stable/dart-core/Set/Set.of.html)

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`prefer_iterable_of: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_iterable_of: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
- [`avoid_duplicate_collection_elements`](/many_lints/docs/rules/collection-type/avoid-duplicate-collection-elements/) — Don't repeat the same element in a collection literal.
