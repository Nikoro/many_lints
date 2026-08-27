---
title: use_existing_variable
description: "Use an existing variable instead of repeating its initializer expression."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: use_existing_variable
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

This rule flags an expression that repeats, character for character, the initializer of a `final` or `const` variable declared earlier in the same block. The quick fix replaces the expression with the variable's name.

## Why use this rule

The repeated copy is the one that gets missed. Change the rule for what counts as a valid order and you update the guard clause, ship it, and leave the same expression in the log line saying something else — a discrepancy nothing in the type system can catch.

**See also:** [Dart patterns](https://dart.dev/language/patterns)

## Don't

```dart
class Order {
  Order(this.items, this.discount);

  final List<String> items;
  final double discount;

  double total() => items.length * 10.0;
}

void submit(Order order) {
  final isEmpty = order.items.isEmpty;

  if (order.items.isEmpty) {                  // LINT: use isEmpty
    print('nothing to submit');
    return;
  }

  final label = 'Order of ${order.items.length}';
  print('Order of ${order.items.length}');    // LINT: use label
}
```

## Do

```dart
void submit(Order order) {
  final isEmpty = order.items.isEmpty;

  if (isEmpty) {
    print('nothing to submit');
    return;
  }

  final label = 'Order of ${order.items.length}';
  print(label);
}
```

## More places it fires

### A second variable with the same initializer

```dart
// Don't — the second declaration recomputes what the first already holds
void report(Order order) {
  final subtotal = order.total() - order.discount;
  final displayed = order.total() - order.discount;   // LINT: use subtotal
  print('$subtotal / $displayed');
}

// Do
void report(Order order) {
  final subtotal = order.total() - order.discount;
  final displayed = subtotal;
  print('$subtotal / $displayed');
}
```

### Inside a return, a condition, or an argument

The scan covers the whole statement, not just top-level expressions:

```dart
// Don't
bool isDiscounted(Order order) {
  final rate = order.discount / order.total();
  return order.discount / order.total() > 0.1;   // LINT: use rate
}

// Do
bool isDiscounted(Order order) {
  final rate = order.discount / order.total();
  return rate > 0.1;
}
```

## Known limitations

The rule compares **source text**, so it cannot tell a value that was already computed from one that is deliberately produced afresh. It stays deliberately silent in these cases:

| Not reported | Why |
|--------------|-----|
| `var` variables | The value may have been reassigned between the declaration and the repeat, so the two are not interchangeable. |
| Constructor calls — `Database(file)`, `List<int>.filled(10, 0)` | Each evaluation allocates a new instance. Reusing the variable could hand back an already-closed or already-consumed resource. |
| `await` expressions | Re-running async work is a separate operation, and the earlier result may be single-use. |
| Cascades — `[]..add(1)` | Each evaluation builds and mutates a distinct object. |
| Literals and bare identifiers | `final x = 42; print(42);` is not worth a diagnostic. |
| A repeat that appears *before* the declaration | The variable does not exist yet at that point. |
| A repeat inside a nested function or closure | Different execution context; the value may be stale by the time it runs. |
| A repeat in a different block | Each block is scanned on its own. |

That first constructor exemption is what makes acquire-release-reacquire safe to write:

```dart
// Not reported — the second Database is a new connection, not the old one
void migrate(String file) async {
  final old = Database(file);
  await old.close();
  final upgraded = Database(file);
  print(upgraded);
}
```

An ordinary method call is still reported: `order.total()` is assumed to be a
computation you would rather do once. If yours is not — if calling it twice is
the point — silence the line with `// ignore: many_lints/use_existing_variable`.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  use_existing_variable: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  use_existing_variable: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`use_existing_destructuring`](/many_lints/docs/rules/pattern-matching/use-existing-destructuring/) — Add properties to an existing destructuring instead of accessing them directly.
- [`avoid_single_field_destructuring`](/many_lints/docs/rules/pattern-matching/avoid-single-field-destructuring/) — Avoid destructuring a single field when direct property access is simpler.
- [`avoid_wildcard_cases_with_enums`](/many_lints/docs/rules/pattern-matching/avoid-wildcard-cases-with-enums/) — Keep exhaustiveness checking by listing enum cases explicitly.
- [`prefer_switch_with_enums`](/many_lints/docs/rules/pattern-matching/prefer-switch-with-enums/) — Use a switch instead of an if-else chain over enum constants.
