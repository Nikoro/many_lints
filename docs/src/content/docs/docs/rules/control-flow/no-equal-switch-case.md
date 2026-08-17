---
title: no_equal_switch_case
description: "Flag two switch branches with identical bodies"
sidebar:
  label: no_equal_switch_case
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags two branches of a `switch` that produce identical bodies, where sharing the patterns would say the same thing once.

## Why use this rule

Repeating a body states the same outcome twice, and the two copies drift: one gets fixed and the other keeps the old behaviour, with nothing to show that they were ever meant to agree. Sharing the patterns (`case a || b`) says the outcome is deliberately the same and can only ever change in one place.

This rule is in the **`pedantic`** preset. Whether two independent enum branches that happen to agree today *should* be merged is a genuine judgement call — the strictest tier deliberately resolves that judgement in favour of one canonical branch.

Three shapes are deliberately not reported, because none of them can be merged into an `||` pattern:

- **A guarded case** (`case int() when x > 10`) — each `when` belongs to its own pattern.
- **The catch-all** (`_` or `default`) — it has to stay last, and folding a specific case into it would change which values it covers.
- **An empty body** — several empty cases in a row are how a fallthrough is written.

## Don't

```dart
String label(int code) => switch (code) {
  1 => 'ok',
  2 => 'ok',
  _ => 'error',
};
```

## Do

```dart
String label(int code) => switch (code) {
  1 || 2 => 'ok',
  _ => 'error',
};
```

## Enabling this rule

This rule is in the **`pedantic`** preset, so it is enabled by `preset: pedantic` or by name:

```yaml
# many_lints.yaml
rules:
  no_equal_switch_case:
    enabled: true
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      no_equal_switch_case: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`no_equal_conditions`](/many_lints/docs/rules/control-flow/no-equal-conditions/) — Flag an if/else-if chain that repeats a condition.
- [`no_equal_then_else`](/many_lints/docs/rules/control-flow/no-equal-then-else/) — Both branches of a condition are identical.
- [`prefer_switch_expression`](/many_lints/docs/rules/control-flow/prefer-switch-expression/) — Suggest converting switch statements to switch expressions.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
