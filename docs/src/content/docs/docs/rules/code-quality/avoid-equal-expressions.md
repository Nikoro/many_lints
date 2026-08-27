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

These are typos with a constant result. One side was meant to be a different variable, field, or index, and the mistake is invisible: the code compiles, the analyzer is silent, and the expression quietly always evaluates the same way.

This rule is in the **`core`** preset and takes no configuration.

## Don't

The classic: a hand-written `operator ==` where one side of a field comparison
was never changed. Unequal points now compare equal.

```dart
class Point {
  const Point(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    if (other is! Point) return false;
    // `other.y` was meant on the right — this ignores y entirely.
    return x == other.x && y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
```

## Do

```dart
class Point {
  const Point(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    if (other is! Point) return false;
    return x == other.x && y == other.y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
```

## More examples

### A guard that guards nothing

Copy-pasting a condition and forgetting to change the second half:

```dart
bool canPublish(bool isDraft, bool isApproved) {
  // Reported — this is just `!isDraft`; isApproved is never consulted.
  return !isDraft && !isDraft;
}
```

```dart
bool canPublish(bool isDraft, bool isApproved) => !isDraft && isApproved;
```

### A range check with the same bound twice

```dart
bool isInWindow(int start, int end, int value) {
  // Reported — `start >= start` is always true.
  return value >= start && start >= start;
}
```

```dart
bool isInWindow(int start, int end, int value) =>
    value >= start && value <= end;
```

### A subtraction that is always zero

```dart
int remaining(int quota, int used) {
  // Reported — `quota - quota` is 0 whatever the quota is.
  return quota - quota;
}
```

```dart
int remaining(int quota, int used) => quota - used;
```

## Known limitations

Only operators where identical operands are meaningless are reported: `==`, `!=`, `<`, `<=`, `>`, `>=`, `&&`, `||`, `-`, `/`, `~/`, `%`, `??`. Arithmetic like `a + a` and `a * a` is ordinary and never flagged.

Two exemptions keep the rule quiet on deliberate code:

**NaN checks.** `value != value` is the canonical NaN test, so a self-comparison with `==` or `!=` is skipped whenever the operand's static type is `double`, `num`, or their nullable forms.

```dart
// Not reported — this is the NaN test.
bool isNotANumber(double value) => value != value;
```

**Side-effecting operands.** Only plain reads — identifiers, property access, indexing, literals — are compared. A call may legitimately differ between invocations:

```dart
// Not reported — two calls to next() can return different values.
bool sameTwice(Iterator<int> it) => it.moveNext() == it.moveNext();
```

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_equal_expressions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_self_compare`](/many_lints/docs/rules/code-quality/avoid-self-compare/) — Flag a value compared against itself with compareTo.
- [`avoid_contradictory_expressions`](/many_lints/docs/rules/control-flow/avoid-contradictory-expressions/) — Detect logical AND conditions that always evaluate to false.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
