---
title: avoid_redundant_else
description: "Drop the else when the if branch always exits"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_redundant_else
---

<span class="rule-badge rule-badge--version">v0.8.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Flags an `else` whose matching `if` branch always exits — via `return`, `throw`, `break`, or `continue`. Reaching the code after the `if` already implies the condition was false, so the `else` only adds a level of indentation.

## Don't

```dart
String describe(int value) {
  if (value < 0) {
    return 'negative';
  } else {
    return 'non-negative';
  }
}
```

## Do

```dart
String describe(int value) {
  if (value < 0) {
    return 'negative';
  }
  return 'non-negative';
}
```

### `throw` counts as exiting

A validation guard is the shape this rule pays for itself on — the whole rest of the method loses a level:

```dart
// Don't
double average(List<int> values) {
  if (values.isEmpty) {
    throw ArgumentError('values must not be empty');
  } else {
    var total = 0;
    for (final value in values) {
      total += value;
    }
    return total / values.length;
  }
}
```

```dart
// Do
double average(List<int> values) {
  if (values.isEmpty) {
    throw ArgumentError('values must not be empty');
  }

  var total = 0;
  for (final value in values) {
    total += value;
  }
  return total / values.length;
}
```

### `continue` and `break` inside a loop

The same applies to a loop body, where the `else` wraps everything that follows:

```dart
// Don't
void report(List<String> lines) {
  for (final line in lines) {
    if (line.isEmpty) {
      continue;
    } else {
      print(line.trim());
    }
  }
}
```

```dart
// Do
void report(List<String> lines) {
  for (final line in lines) {
    if (line.isEmpty) {
      continue;
    }
    print(line.trim());
  }
}
```

## Known limitations

`else if` chains are never reported. They read as a single decision, and splitting them into sequential `if` statements usually reads worse than the chain.

The exit check is **syntactic**: a branch counts as exiting when its last statement is a `return`, `throw`, `break`, or `continue`. Two consequences follow:

- A branch that exits through a helper is not recognised, so `if (bad) { _fail(); } else { ... }` is not reported even when `_fail()` returns `Never`.
- A branch whose last statement is a `switch` or `if` where *every* path returns is not recognised either — only the last statement itself is examined.

The quick fix declines to hoist an `else` body that declares a variable, since the name could collide in the enclosing scope. Those cases report without an automatic fix; unindent them by hand, renaming if needed.

## Configuration

This rule is in the **`opinionated`** preset, so it is on with
`preset: opinionated`, or by name:

```yaml
# many_lints.yaml
rules:
  avoid_redundant_else: true
```

To turn it off again:

```yaml
# many_lints.yaml
rules:
  avoid_redundant_else: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`prefer_early_return`](/many_lints/docs/rules/control-flow/prefer-early-return/) — Replace a body-wrapping if with an early-return guard.
- [`prefer_immediate_return`](/many_lints/docs/rules/code-quality/prefer-immediate-return/) — Return an expression directly instead of via a throwaway variable.
- [`no_equal_then_else`](/many_lints/docs/rules/control-flow/no-equal-then-else/) — Both branches of a condition are identical.
