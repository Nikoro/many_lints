---
title: avoid_unused_after_null_check
description: "A variable null-checked but never used in the guarded branch"
sidebar:
  label: avoid_unused_after_null_check
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags `if (x != null) { ... }` where the guarded branch never mentions `x`. The check exists to make `x` usable, so a branch that ignores it is usually operating on the wrong variable — a copy-paste slip between two similarly named values. Nothing in the type system objects, because the variable actually used may be perfectly non-null on its own.

**See also:** [Dart: understanding null safety](https://dart.dev/null-safety/understanding-null-safety)

## Don't

`name` is checked, `fallbackName` is used:

```dart
void greet(String? name, String fallbackName) {
  if (name != null) {
    print(fallbackName);
  }
}
```

The inverted form has the same problem — for `x == null`, the `else` is the guarded branch:

```dart
void greet(String? name, String fallbackName) {
  if (name == null) {
    print('anonymous');
  } else {
    print(fallbackName);
  }
}
```

## Do

```dart
void greet(String? name, String fallbackName) {
  if (name != null) {
    print(name);
  } else {
    print(fallbackName);
  }
}
```

## Known limitations

Only locals and parameters are checked. A field can be read through `this`, passed implicitly, or mutated by any call inside the branch, so the absence of its bare name proves nothing.

The condition must be a direct comparison against `null` — `x != null` or `null != x`. Compound conditions, `is` checks, and null-aware operators are not analysed.

For `x == null`, only the `else` branch is examined, since that is the branch where the variable is known non-null. An `if (x == null)` with no `else` is not reported.

## Configuration

This rule is in the **`pedantic`** preset, because checking whether a value
exists can legitimately select behaviour without reading the value inside the
selected branch.

Enable it by name:

```yaml
# many_lints.yaml
rules:
  avoid_unused_after_null_check: true
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`prefer_simpler_patterns_null_check`](/many_lints/docs/rules/control-flow/prefer-simpler-patterns-null-check/) — Suggest simpler null-check patterns in if-case expressions.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
