---
title: avoid_contradictory_expressions
description: "Detect logical AND conditions that always evaluate to false"
sidebar:
  label: avoid_contradictory_expressions
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Flags an `&&` chain containing two comparisons that cannot both hold, so the whole condition is always `false` and the branch is dead.

## Don't

Copy-pasting a bound and changing only the operator gives a range that nothing can be inside. The author meant `>=` on one side, or a second variable:

```dart
void filter(int score) {
  if (score > 80 && score < 80) {
    highlight();
  }
}

void highlight() {}
```

## Do

```dart
void filter(int score) {
  if (score >= 80 && score < 100) {
    highlight();
  }
}

void highlight() {}
```

### Two values for the same variable

Copy-pasting an equality check and forgetting to change the literal gives a condition nothing satisfies. `||` is almost always what was meant:

```dart
void route(int statusCode) {
  // Don't — no code is both 301 and 302
  if (statusCode == 301 && statusCode == 302) {
    followRedirect();
  }

  // Do
  if (statusCode == 301 || statusCode == 302) {
    followRedirect();
  }
}

void followRedirect() {}
```

### A guard that cancels itself out

Adding a defensive check next to an existing one can contradict it. This shows up after a merge, where each side added its own guard:

```dart
void submit(String? token) {
  // Don't — `token` cannot be both null and non-null
  if (token != null && token == null) {
    send(token);
  }
}

void send(String token) {}
```

### Longer chains are flattened

The rule flattens the whole `&&` chain and checks every pair, so a contradiction between non-adjacent terms is still found:

```dart
void process(int size, bool ready, int retries) {
  // Don't — `size < 10` and `size > 10` are three terms apart
  if (size < 10 && ready && retries == 0 && size > 10) {
    run();
  }
}

void run() {}
```

## Known limitations

Only comparisons joined by `&&` are examined. `||` is never reported, and neither is a contradiction spread across nested `if` statements.

Not every impossible pair is detected. The rule finds:

- the same operand pair with contradictory operators (`==`/`!=`, `==`/`<`, `==`/`>`, `<`/`>`);
- two `==` checks that share an operand and compare it against different literals.

Two consequences worth knowing, because they are the cases people expect to be caught:

- **`<=` and `>=` are not in that table.** `x <= 4 && x >= 6` is not reported.
- **Relational operators must share *both* operands.** `x < 4 && x > 4` reports; `x > 80 && x < 50` does not, because the literals differ and the rule does no arithmetic. An impossible range written with two different bounds slips through.

Operands are matched by resolved element, so `this.count` and `count` are recognised as the same variable, while two different variables that happen to share a name are not. There is no quick fix — which half of the contradiction is the bug is not something the analyser can tell.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_contradictory_expressions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_equal_expressions`](/many_lints/docs/rules/code-quality/avoid-equal-expressions/) — Both operands of a binary expression should not be identical.
- [`avoid_self_compare`](/many_lints/docs/rules/code-quality/avoid-self-compare/) — Flag a value compared against itself with compareTo.
- [`avoid_nested_conditional_expressions`](/many_lints/docs/rules/control-flow/avoid-nested-conditional-expressions/) — Flag a conditional nested inside another.
