---
title: prefer_correct_edge_insets_constructor
description: "Use the simplest EdgeInsets constructor for the given values."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_correct_edge_insets_constructor
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Flags an `EdgeInsets` constructor whose arguments a simpler constructor expresses exactly. The quick fix names the replacement — `EdgeInsets.fromLTRB(8, 8, 8, 8)` becomes `EdgeInsets.all(8)`.

## Don't

`fromLTRB` with four equal values is uniform padding written the long way. The reader has to compare all four numbers to see it:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
  child: child,
)
```

## Do

```dart
Padding(
  padding: const EdgeInsets.all(16),
  child: child,
)
```

### Equal opposite sides are symmetric

```dart
// Don't
Container(
  margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
  child: child,
);

// Do
Container(
  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  child: child,
);
```

When one axis is zero, name only the other:

```dart
// Don't — vertical is 0 on both sides
Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), child: child);

// Do
Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);
```

### `only` that is really `all` or `symmetric`

Listing every side by name is no clearer than the constructor that means it:

```dart
// Don't
Padding(
  padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 12),
  child: child,
);

// Do
Padding(padding: const EdgeInsets.all(12), child: child);
```

```dart
// Don't
Padding(padding: const EdgeInsets.only(left: 20, right: 20), child: child);

// Do
Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);
```

The reverse also reports — `symmetric` whose two axes are equal is `all`:

```dart
// Don't
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  child: child,
);

// Do
Padding(padding: const EdgeInsets.all(8), child: child);
```

### Everything zero is `EdgeInsets.zero`

Any constructor that works out to no padding at all is reported, since `EdgeInsets.zero` is a const singleton and says so at a glance:

```dart
// Don't
Padding(padding: const EdgeInsets.all(0), child: child);
Padding(padding: const EdgeInsets.fromLTRB(0, 0, 0, 0), child: child);

// Do
Padding(padding: EdgeInsets.zero, child: child);
```

### `fromLTRB` with a zero side is `only`

```dart
// Don't
Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: child);

// Do
Padding(
  padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
  child: child,
);
```

## Known limitations

**Arguments are compared as written text, not as values.** `EdgeInsets.fromLTRB(8, 8.0, 8, 8)` is not reported, because `8` and `8.0` are different source text — even though they produce the same insets. The upside is that a named constant works: `fromLTRB(kGap, kGap, kGap, kGap)` reports and the fix suggests `EdgeInsets.all(kGap)`.

**Only zero is recognised as zero.** `0` and `0.0` count; a `const` named zero does not, so `EdgeInsets.all(kNone)` is left alone.

**`EdgeInsetsDirectional` is not checked.** The rule matches `EdgeInsets` exactly, so `EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8)` is never reported.

**Nothing simpler means no report.** `EdgeInsets.fromLTRB(1, 2, 3, 4)` and `EdgeInsets.only(left: 8, top: 4)` already use the tightest constructor for their values.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  prefer_correct_edge_insets_constructor: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  prefer_correct_edge_insets_constructor: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_collections_by_constant_index`](/many_lints/docs/rules/collection-type/avoid-accessing-collections-by-constant-index/) — Avoid accessing a collection by a constant index inside a loop.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
- [`avoid_collection_methods_with_unrelated_types`](/many_lints/docs/rules/collection-type/avoid-collection-methods-with-unrelated-types/) — Avoid calling collection methods with arguments whose types are unrelated to the collection's type parameter.
- [`avoid_duplicate_collection_elements`](/many_lints/docs/rules/collection-type/avoid-duplicate-collection-elements/) — Don't repeat the same element in a collection literal.
