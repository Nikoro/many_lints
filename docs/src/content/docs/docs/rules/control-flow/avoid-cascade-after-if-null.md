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

Flags a cascade (`..`) whose target is an if-null (`??`) expression that is not parenthesised.

`??` binds *tighter* than `..`, so `a ?? B()..m()` parses as `(a ?? B())..m()`. The cascade runs against whichever side `??` produced — including `a` itself when `a` is non-null. That is the opposite of how the line reads.

**See also:** [Cascade notation](https://dart.dev/language/operators#cascade-notation)

## Don't

The intent here is "reuse the spare kettle if there is one, otherwise build one and boil it". What the code does is boil whichever kettle `??` returned — including the caller's spare:

```dart
class Kettle {
  int litres = 1;

  void boil() {}
}

Kettle heat(Kettle? spare) {
  return spare ?? Kettle()..boil();
}
```

## Do

Two readings, two sets of parentheses. Pick the one you meant.

Boil whichever kettle you ended up with:

```dart
class Kettle {
  int litres = 1;

  void boil() {}
}

Kettle heat(Kettle? spare) {
  return (spare ?? Kettle())..boil();
}
```

Boil only the fresh one, and leave the caller's spare untouched:

```dart
class Kettle {
  int litres = 1;

  void boil() {}
}

Kettle heat(Kettle? spare) {
  return spare ?? (Kettle()..boil());
}
```

### Seeing the difference

The two forms are not interchangeable — they mutate different objects:

```dart
void demo() {
  StringBuffer? spare = StringBuffer('spare');

  final a = spare ?? StringBuffer('fresh')..write('!');
  // The cascade hit `spare`: it now reads 'spare!', the fresh buffer was
  // built, never written to, and thrown away. `a` is `spare`.

  final b = spare ?? (StringBuffer('fresh')..write('!'));
  // `spare` is untouched, and `b` is `spare` — the fresh buffer was never
  // built at all.
}
```

### Multiple sections behave the same way

Every section of the cascade lands on the same mis-chosen target:

```dart
class Kettle {
  int litres = 1;

  void boil() {}
}

Kettle heat(Kettle? spare) {
  return (spare ?? Kettle())
    ..litres = 5
    ..boil();
}
```

## Known limitations

Only a bare `??` target is reported. A cascade with no `??` in sight (`Kettle()..boil()`) and one already parenthesised on either side are both left alone — the parentheses are exactly what the rule is asking for, so once they are there the report goes away.

The quick fix wraps the if-null expression, producing `(a ?? B())..m()`. That is the more common intent, but it is not always the one you want; check the result against the "Do" forms above before accepting it.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`avoid_cascade_after_if_null: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_cascade_after_if_null: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_unused_after_null_check`](/many_lints/docs/rules/control-flow/avoid-unused-after-null-check/) — A variable null-checked but never used in the guarded branch.
- [`prefer_simpler_patterns_null_check`](/many_lints/docs/rules/control-flow/prefer-simpler-patterns-null-check/) — Suggest simpler null-check patterns in if-case expressions.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
