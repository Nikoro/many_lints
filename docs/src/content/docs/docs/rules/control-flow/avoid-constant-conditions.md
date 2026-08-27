---
title: avoid_constant_conditions
description: "Detect comparisons where both sides are constants"
sidebar:
  label: avoid_constant_conditions
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Flags a comparison (`==`, `!=`, `<`, `>`, `<=`, `>=`) whose operands are *both* compile-time constants. The answer is fixed before the program runs, so one branch is dead and the other always taken.

## Don't

The usual shape is a constant that used to be a variable, or a constant compared against the value it was defined as:

```dart
abstract final class Config {
  static const channel = 'stable';
  static const maxRetries = 3;
}

void configure() {
  // Always true — `channel` is `'stable'` by definition.
  if (Config.channel == 'stable') {
    enableCrashReporting();
  }
}

void enableCrashReporting() {}
```

## Do

Compare the constant against something that varies — a parameter, a field, a value read at runtime:

```dart
abstract final class Config {
  static const channel = 'stable';
  static const maxRetries = 3;
}

void configure(String buildChannel) {
  if (buildChannel == Config.channel) {
    enableCrashReporting();
  }
}

void enableCrashReporting() {}
```

### A constant threshold is fine on one side

Comparing a variable against a named constant is the whole point of naming it, and is never reported:

```dart
void retry(int attempt) {
  const maxRetries = 3;

  if (attempt < maxRetries) {
    // Only `maxRetries` is constant, so nothing is reported.
  }
}
```

### The leftover from a debugging session

Hard-coding both sides to force a branch is the fastest way to test one, and the easiest thing to forget to undo:

```dart
void render() {
  // Don't — left over from "let me see the empty state"
  if (1 == 1) {
    showEmptyState();
  }
}

void showEmptyState() {}
```

### Two `const` locals, one comparison

Naming both sides does not make the comparison meaningful — it is still decided at compile time:

```dart
void check() {
  const limit = 4;
  const ceiling = 4;

  // Don't — `4 != 4`, written in two steps
  if (limit != ceiling) {
    print('never');
  }
}
```

## Known limitations

Only the six comparison operators are checked. `&&`, `||` and arithmetic are out of scope — see [`avoid_contradictory_expressions`](/many_lints/docs/rules/control-flow/avoid-contradictory-expressions/) for conjunctions that can never be true.

Constness is read syntactically: literals, `const` variables and static `const` fields, `const` collections and `const` constructor calls, plus prefix operators over those. A plain `final` local is **not** treated as constant, so `final limit = 4; if (limit != 4)` is not reported. Neither is a function call, so `f() == 3` stays silent even when `f` is trivially constant.

There is no quick fix. Which operand should have been a variable is a question only the author can answer.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_constant_conditions: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_contradictory_expressions`](/many_lints/docs/rules/control-flow/avoid-contradictory-expressions/) — Detect logical AND conditions that always evaluate to false.
- [`avoid_equal_expressions`](/many_lints/docs/rules/code-quality/avoid-equal-expressions/) — Both operands of a binary expression should not be identical.
- [`avoid_self_compare`](/many_lints/docs/rules/code-quality/avoid-self-compare/) — Flag a value compared against itself with compareTo.
- [`avoid_constant_switches`](/many_lints/docs/rules/control-flow/avoid-constant-switches/) — Detect switch statements on constant expressions.
