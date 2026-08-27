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

Flags `.where(predicate).isNotEmpty` and `.where(predicate).isEmpty`. Both build a lazy `Iterable` only to ask a yes/no question that `any` and `every` answer directly, stopping at the first decisive element. The quick fix rewrites it.

## Don't

`isNotEmpty` after a `where` is `any` written out:

```dart
class Invoice {
  const Invoice({required this.isOverdue, required this.isPaid});

  final bool isOverdue;
  final bool isPaid;
}

bool hasOverdueInvoice(List<Invoice> invoices) {
  return invoices.where((invoice) => invoice.isOverdue).isNotEmpty;
}
```

## Do

```dart
class Invoice {
  const Invoice({required this.isOverdue, required this.isPaid});

  final bool isOverdue;
  final bool isPaid;
}

bool hasOverdueInvoice(List<Invoice> invoices) {
  return invoices.any((invoice) => invoice.isOverdue);
}
```

`any` returns as soon as one invoice matches. The `where` form still has to build the iterable and ask it whether it produced anything.

### `isEmpty` is `every`, with the predicate flipped

This is where the rewrite needs care: "nothing matches `p`" is "everything matches `not p`", so the predicate has to be negated, not copied.

```dart
// Don't — no invoice is unpaid
bool isFullySettled(List<Invoice> invoices) {
  return invoices.where((invoice) => !invoice.isPaid).isEmpty;
}
```

```dart
// Do
bool isFullySettled(List<Invoice> invoices) {
  return invoices.every((invoice) => invoice.isPaid);
}
```

## Known limitations

**Only `where` is matched.** `.map(...).isNotEmpty` and `.whereType<T>().isNotEmpty` are not reported, since neither has an `any`/`every` equivalent that keeps the same meaning.

**The `where` must take exactly one argument**, and its receiver must resolve to an `Iterable`. A `dynamic` receiver is left alone.

**`length > 0` is not matched.** Only the `isEmpty` and `isNotEmpty` getters are, so `items.where(p).length > 0` passes — though `any` is the better call there too.

**See also:** [Iterable.any](https://api.dart.dev/stable/dart-core/Iterable/any.html) | [Iterable.every](https://api.dart.dev/stable/dart-core/Iterable/every.html)

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
