---
title: avoid_unnecessary_continue
description: "Remove a `continue` that ends a loop body"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_unnecessary_continue
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Flags a `continue` written as the **last** statement of a loop body. Control reaches the next iteration whether it is there or not, but the keyword still announces that something below is being skipped — and a reader stops to look for what.

## Don't

The usual origin: the statements this `continue` was skipping were moved or deleted, and the guard stayed behind.

```dart
class Order {
  bool isCancelled = false;
}

void run(List<Order> orders) {
  for (final order in orders) {
    process(order);
    continue;
  }
}

void process(Order order) {}
```

## Do

```dart
class Order {
  bool isCancelled = false;
}

void run(List<Order> orders) {
  for (final order in orders) {
    process(order);
  }
}

void process(Order order) {}
```

The quick fix deletes the statement, leaving the rest of the body untouched.

### A `continue` that skips something is left alone

Only the last statement is examined, so the guard-clause form — the reason `continue` exists — is never reported:

```dart
class Order {
  bool isCancelled = false;
}

void run(List<Order> orders) {
  for (final order in orders) {
    if (order.isCancelled) continue;
    process(order);
  }
}

void process(Order order) {}
```

### Ending an `if` branch is real work too

A `continue` at the end of a `then` branch skips the `else` and everything after the `if`, so it is not the last statement of the loop body and is not reported:

```dart
class Order {
  bool isCancelled = false;
}

void run(List<Order> orders) {
  for (final order in orders) {
    if (order.isCancelled) {
      archive(order);
      continue;
    }

    process(order);
  }
}

void process(Order order) {}

void archive(Order order) {}
```

### `while` and `do`/`while` are covered

The rule registers all three loop forms, so a trailing `continue` reports the same way in each:

```dart
void drain(int count) {
  var remaining = count;
  while (remaining > 0) {
    remaining--;
    continue;   // LINT
  }
}
```

## Known limitations

A **labelled** `continue` is never reported. `continue outer;` targets an enclosing loop, so it does change where control goes even when written last.

A loop with no braces is still checked: `for (final o in orders) continue;` is a body consisting of exactly one `continue`, and reports.

A `continue` inside a `switch` case within the loop body is not the loop body's last statement, so it is left alone.

## Turning this rule off

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated` or `preset: pedantic`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_continue: true
```

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_continue: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_constant_switches`](/many_lints/docs/rules/control-flow/avoid-constant-switches/) — Detect switch statements on constant expressions.
