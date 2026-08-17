---
title: avoid_inverted_boolean_checks
description: "Use the opposite operator instead of negating a comparison"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_inverted_boolean_checks
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags a negated relational comparison on integers — `!(a > b)`, `!(a <= b)` — where the opposite operator says the same thing directly.

## Why use this rule

Every relational operator has an exact opposite. Negating the comparison instead of using that opposite forces the reader to invert the condition mentally, which is a small cost that recurs at every read.

## Don't

```dart
if (!(count > limit)) {
  accept();
}
```

## Do

```dart
if (count <= limit) {
  accept();
}
```

## Known limitations

Reporting is restricted to comparisons where **both operands are `int`**, for two reasons:

- **Doubles break the equivalence.** With NaN involved, `!(a > b)` and `a <= b` differ: `!(double.nan > 1)` is `true`, while `double.nan <= 1` is `false`. Rewriting would change behaviour, so doubles and `num` are never reported.
- **User-defined operators need not be consistent.** A type may define `>` and `<=` independently, so the opposite operator is not guaranteed to be the negation.

Equality (`!(a == b)`) is out of scope here; see [`avoid_unnecessary_negations`](/many_lints/docs/rules/control-flow/avoid-unnecessary-negations/) for the double-negation cases.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_inverted_boolean_checks: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_inverted_boolean_checks: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_negated_conditions`](/many_lints/docs/rules/control-flow/avoid-negated-conditions/) — State the positive case first in an if/else.
- [`avoid_unnecessary_negations`](/many_lints/docs/rules/control-flow/avoid-unnecessary-negations/) — Collapse double negations.
- [`prefer_returning_condition`](/many_lints/docs/rules/control-flow/prefer-returning-condition/) — Return the condition instead of true/false branches.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
