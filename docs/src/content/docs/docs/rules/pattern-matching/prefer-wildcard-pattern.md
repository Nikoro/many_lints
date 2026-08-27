---
title: prefer_wildcard_pattern
description: "Use the wildcard pattern '_' instead of 'Object()' for catch-all cases."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_wildcard_pattern
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Pattern Matching</span>

This rule flags a bare `Object()` pattern used as a catch-all. It matches everything non-null, exactly like `_`, but reads as if it were testing for something. The quick fix replaces it with `_`.

It applies in switch expressions, switch statements, and `if-case` conditions.

**See also:** [Dart patterns](https://dart.dev/language/patterns)

## Don't

```dart
String describe(Object value) {
  return switch (value) {
    int() => 'a number',
    String() => 'text',
    Object() => 'something else',    // LINT
  };
}

void log(Object value) {
  switch (value) {
    case int():
      print('int');
    case Object():                   // LINT
      print('other');
  }
}

void guard(Object value) {
  if (value case Object()) {         // LINT
    print('always runs');
  }
}
```

## Do

```dart
String describe(Object value) {
  return switch (value) {
    int() => 'a number',
    String() => 'text',
    _ => 'something else',
  };
}

void log(Object value) {
  switch (value) {
    case int():
      print('int');
    case _:
      print('other');
  }
}

void guard(Object value) {
  print('always runs');
}
```

That last one is the case worth noticing: `if (x case Object())` is a condition that is always true for a non-null value, so the `if` itself was doing nothing.

## Known limitations

**`Object()` with fields is left alone.** Once the pattern destructures something it is doing real work, and `_` cannot replace it:

```dart
// Not reported — the pattern extracts a value
String describe(Object value) => switch (value) {
  Object(hashCode: final h) => 'hash: $h',
};
```

**Named types other than `Object` are not the target.** `int()`, `String()`, or your own `Response()` narrow the match and are never reported.

**Nested inside `&&` and `||` still counts.** `Object() && Object()` reports both operands, since each one is independently a catch-all.

**The type name is matched textually.** A class of your own named `Object` in scope would be reported as well.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: opinionated`. Add it to `preset: core` with
`prefer_wildcard_pattern: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_wildcard_pattern: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_wildcard_cases_with_enums`](/many_lints/docs/rules/pattern-matching/avoid-wildcard-cases-with-enums/) — **Opposing convention.** Keep exhaustiveness checking by listing enum cases explicitly.
- [`prefer_switch_with_enums`](/many_lints/docs/rules/pattern-matching/prefer-switch-with-enums/) — Use a switch instead of an if-else chain over enum constants.
- [`avoid_single_field_destructuring`](/many_lints/docs/rules/pattern-matching/avoid-single-field-destructuring/) — Avoid destructuring a single field when direct property access is simpler.
- [`use_existing_destructuring`](/many_lints/docs/rules/pattern-matching/use-existing-destructuring/) — Add properties to an existing destructuring instead of accessing them directly.
