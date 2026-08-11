---
title: avoid_cascade_after_if_null
description: "Detect cascades after if-null operators without parentheses"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_cascade_after_if_null
---

<span class="rule-badge rule-badge--version">v0.3.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a cascade expression (`..`) follows an if-null (`??`) operator without parentheses. The precedence is not what it looks like: the cascade applies to the *entire* if-null expression, not to the right-hand side of `??`.

## Why use this rule

The cascade operator binds *looser* than `??`, so `a ?? B()..method()` parses as `(a ?? B())..method()`. The cascade takes the whole if-null expression as its target.

That is the opposite of how the line reads. The natural reading is "if `a` is null, build a `B` and configure it" — but when `a` is non-null, the cascade runs against `a` itself:

```dart
final sb = StringBuffer('LHS');
StringBuffer? maybe = sb;
final out = maybe ?? StringBuffer('RHS')..write('-MUTATED');
// sb is now "LHS-MUTATED": the pre-existing buffer was mutated,
// the fresh StringBuffer('RHS') was discarded untouched,
// and `out` is identical to `sb`.
```

Adding explicit parentheses makes the intent clear and prevents subtle bugs.

**See also:** [Cascade notation](https://dart.dev/language/operators#cascade-notation)

## Don't

```dart
void bad(Kettle? spareKettle) {
  // Unclear whether ..boil() applies to the result of ?? or just Kettle()
  final kettle = spareKettle ?? Kettle()
    ..boil();

  // Multiple cascades after if-null
  final kettle2 = spareKettle ?? Kettle()
    ..boil()
    ..litres = 5;
}
```

## Do

```dart
void good(Kettle? spareKettle) {
  // Cascade applies to the entire if-null expression
  final kettle = (spareKettle ?? Kettle())..boil();

  // Cascade applies only to the new instance
  final kettle2 = spareKettle ?? (Kettle()..boil());

  // No if-null involved, cascade is unambiguous
  final kettle3 = Kettle()..boil();
}
```

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: all`. Add it to `preset: core` with
`avoid_cascade_after_if_null: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_cascade_after_if_null: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
