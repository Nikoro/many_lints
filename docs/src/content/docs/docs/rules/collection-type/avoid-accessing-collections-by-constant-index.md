---
title: avoid_accessing_collections_by_constant_index
description: "Avoid accessing a collection by a constant index inside a loop."
sidebar:
  label: avoid_accessing_collections_by_constant_index
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

Flags a collection read with a constant index — `list[0]`, or `list[kFirst]` where `kFirst` is a `const` — inside a loop body. The index never changes with the iteration, so either the read belongs outside the loop, or it was meant to use the loop variable.

## Don't

The classic form is a forgotten loop variable: the loop runs `n` times and every iteration reads the same row.

```dart
class Order {
  const Order(this.id, this.total);

  final String id;
  final double total;
}

void printTotals(List<Order> orders) {
  for (var i = 0; i < orders.length; i++) {
    print('${orders[0].id}: ${orders[0].total}');
  }
}
```

## Do

```dart
class Order {
  const Order(this.id, this.total);

  final String id;
  final double total;
}

void printTotals(List<Order> orders) {
  for (var i = 0; i < orders.length; i++) {
    print('${orders[i].id}: ${orders[i].total}');
  }
}
```

A `for-in` loop sidesteps the index entirely, which is why it is the usual fix:

```dart
void printTotals(List<Order> orders) {
  for (final order in orders) {
    print('${order.id}: ${order.total}');
  }
}
```

### The read really is loop-invariant

Sometimes the constant index is deliberate — a header row, a base currency, a default. Hoist it above the loop so it is read once and the intent is on the page:

```dart
// Don't — re-read on every iteration, and it reads like a bug
for (final row in rows) {
  applyFormat(row, columns[0].format);
}

// Do
final headerFormat = columns[0].format;
for (final row in rows) {
  applyFormat(row, headerFormat);
}
```

### A `const` index counts as constant

A named constant is no less fixed than a literal, so this reports too:

```dart
const kSelectedTab = 0;

// Don't
for (final event in events) {
  refresh(tabs[kSelectedTab]);
}

// Do — a mutable variable the loop advances is fine
var cursor = 0;
for (final event in events) {
  refresh(tabs[cursor]);
  cursor++;
}
```

## Known limitations

**Only a literal or a constant identifier is treated as constant.** Any computed index — `list[i + 1]`, `list[offset]`, `list[values.length - 1]` — is left alone, even when it happens to be invariant.

**Nested functions are their own scope.** A closure declared inside a loop body is not reported for its constant index, since the loop above it says nothing about how the closure is called.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_accessing_collections_by_constant_index: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_accessing_collections_by_constant_index: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_unsafe_collection_methods`](/many_lints/docs/rules/collection-type/avoid-unsafe-collection-methods/) — Check for emptiness before using first, last, single or reduce.
- [`prefer_safe_collection_access`](/many_lints/docs/rules/fpdart/prefer-safe-collection-access/) — list.first throws where list.head returns None.
- [`avoid_missing_enum_constant_in_map`](/many_lints/docs/rules/collection-type/avoid-missing-enum-constant-in-map/) — Cover every enum constant in a map keyed by that enum.
- [`avoid_collection_equality_checks`](/many_lints/docs/rules/collection-type/avoid-collection-equality-checks/) — Avoid comparing collections with == or != as it checks reference equality, not contents.
