---
title: avoid_equal_expressions
description: "Both operands of a binary expression should not be identical"
sidebar:
  label: avoid_equal_expressions
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags a binary expression whose left and right operands are textually identical — `a == a`, `flag && flag`, `total - total`.

## Why use this rule

These are typos with a constant result. One side was meant to be a different variable, field, or index, and the mistake is invisible: the code compiles, the analyzer is silent, and the expression quietly always evaluates the same way.

The damage depends on where it lands. `p.x == p.x` in an `operator ==` makes unequal objects compare equal. `flag && flag` in a guard makes the guard useless. Neither fails loudly.

## Don't

```dart
class Point {
  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    if (other is! Point) return false;
    // `y` was meant on one side — this ignores y entirely
    return x == other.x && y == y;
  }
}
```

## Do

```dart
@override
bool operator ==(Object other) {
  if (other is! Point) return false;
  return x == other.x && y == other.y;
}
```

## Known limitations

The rule only reports operators where identical operands are meaningless: `==`, `!=`, `<`, `<=`, `>`, `>=`, `&&`, `||`, `-`, `/`, `~/`, `%`, `??`. Arithmetic like `a + a` and `a * a` is ordinary and never flagged.

Two further exemptions keep it quiet on deliberate code:

- **NaN checks.** `value != value` is the canonical NaN test, so a self-comparison is skipped when the operand may be a `double` or `num`.
- **Side-effecting operands.** Only plain reads — identifiers, property access, indexing, literals — are compared. `next() == next()` may legitimately differ between calls and is never reported.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: all`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_equal_expressions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
