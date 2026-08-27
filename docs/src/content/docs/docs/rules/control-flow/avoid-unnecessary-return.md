---
title: avoid_unnecessary_return
description: "Remove a bare `return;` that ends a void function"
sidebar:
  label: avoid_unnecessary_return
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags a bare `return;` written as the last statement of a function that returns nothing. Control leaves the function whether it is there or not, but `return` reads as an early exit, so a reader stops to look for what is being skipped and finds the closing brace.

It is usually left behind by a change that moved or deleted the statements it once guarded.

## Don't

```dart
class Order {
  bool get isCancelled => false;
}

void send(Order order) {}

void process(Order order) {
  send(order);
  return;
}
```

`Future<void>` counts the same — an `async` function with nothing left to run:

```dart
Future<void> flush(List<String> pending) async {
  await Future<void>.delayed(Duration.zero);
  pending.clear();
  return;
}
```

## Do

Drop the statement:

```dart
class Order {
  bool get isCancelled => false;
}

void send(Order order) {}

void process(Order order) {
  send(order);
}
```

An early `return;` that genuinely skips later statements is doing real work, and stays:

```dart
class Order {
  bool get isCancelled => false;
}

void send(Order order) {}

void process(Order order) {
  if (order.isCancelled) return;

  send(order);
}
```

## Known limitations

Only a `return` with **no value** is reported, and only when the return type is
written as `void` or `Future<void>`.

An **omitted** return type is not treated as `void` — it means `dynamic`, where
`return;` may be deliberate. So this is not reported:

```dart
process(List<String> pending) {
  pending.clear();
  return;
}
```

A bare closure is skipped too, for the same reason: its return type would have
to be inferred.

## Turning this rule off

This rule is in the **`opinionated`** preset.

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_return: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_early_return`](/many_lints/docs/rules/control-flow/prefer-early-return/) — Replace a body-wrapping if with an early-return guard.
- [`prefer_return_await`](/many_lints/docs/rules/control-flow/prefer-return-await/) — Detect missing await on returned Futures inside try-catch.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
