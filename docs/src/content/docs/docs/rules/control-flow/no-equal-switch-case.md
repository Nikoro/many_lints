---
title: no_equal_switch_case
description: "Flag two switch branches with identical bodies"
sidebar:
  label: no_equal_switch_case
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags two branches of a `switch` that produce identical bodies, where sharing the patterns would say the same thing once.

Two copies of a body drift: one gets fixed and the other keeps the old behaviour, with nothing to show they were ever meant to agree. `case a || b` says the outcome is deliberately the same and can only ever change in one place.

## Don't

A switch expression with a body written twice:

```dart
enum DeliveryStage { packed, shipped, delivered, returned }

String tracking(DeliveryStage stage) => switch (stage) {
  DeliveryStage.packed => 'In the warehouse',
  DeliveryStage.shipped => 'On its way',
  DeliveryStage.delivered => 'Complete',
  DeliveryStage.returned => 'Complete',
};
```

Switch statements are checked the same way:

```dart
enum DeliveryStage { packed, shipped, delivered, returned }

void notify(DeliveryStage stage) {
  switch (stage) {
    case DeliveryStage.packed:
      print('In the warehouse');
    case DeliveryStage.shipped:
      print('On its way');
    case DeliveryStage.delivered:
      print('Complete');
    case DeliveryStage.returned:
      print('Complete');
  }
}
```

## Do

Share the patterns with `||`:

```dart
enum DeliveryStage { packed, shipped, delivered, returned }

String tracking(DeliveryStage stage) => switch (stage) {
  DeliveryStage.packed => 'In the warehouse',
  DeliveryStage.shipped => 'On its way',
  DeliveryStage.delivered || DeliveryStage.returned => 'Complete',
};
```

## Known limitations

Bodies are compared by source text, so two branches that reach the same result
by different code are not reported.

Three shapes are never reported, because none of them can be merged into an
`||` pattern:

```dart
enum DeliveryStage { packed, shipped, delivered, returned }

String tracking(DeliveryStage stage, int retries) => switch (stage) {
  // A guarded case — each `when` belongs to its own pattern.
  DeliveryStage.packed when retries > 3 => 'Stuck',
  DeliveryStage.shipped when retries > 3 => 'Stuck',
  DeliveryStage.packed => 'In the warehouse',
  DeliveryStage.shipped => 'On its way',
  DeliveryStage.delivered => 'Complete',
  // The catch-all has to stay last, so folding a case into it would change
  // which values it covers.
  _ => 'Complete',
};
```

An **empty body** is skipped too: several empty cases in a row are how a
fallthrough is written in a switch statement.

## Configuration

This rule is in the **`pedantic`** preset — whether two independent branches
that happen to agree today *should* be merged is a genuine judgement call, and
the strictest tier resolves it in favour of one canonical branch.

Enable it by name:

```yaml
# many_lints.yaml
rules:
  no_equal_switch_case: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  no_equal_switch_case: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`no_equal_conditions`](/many_lints/docs/rules/control-flow/no-equal-conditions/) — Flag an if/else-if chain that repeats a condition.
- [`no_equal_then_else`](/many_lints/docs/rules/control-flow/no-equal-then-else/) — Both branches of a condition are identical.
- [`prefer_switch_expression`](/many_lints/docs/rules/control-flow/prefer-switch-expression/) — Suggest converting switch statements to switch expressions.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
