---
title: avoid_duplicate_cascades
description: "Detect duplicate cascade sections in cascade expressions"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: avoid_duplicate_cascades
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Flags a cascade section that repeats an earlier one exactly — the same assignment with the same value, or the same call with the same arguments.

**See also:** [Cascade notation](https://dart.dev/language/operators#cascade-notation)

## Don't

A long cascade is built by copying the line above and editing it, and one edit gets missed:

```dart
class RequestBuilder {
  String url = '';
  String method = '';
  int timeoutMs = 0;

  void header(String name, String value) {}
}

RequestBuilder build() {
  return RequestBuilder()
    ..url = '/orders'
    ..method = 'POST'
    ..header('accept', 'application/json')
    ..header('accept', 'application/json')
    ..timeoutMs = 5000;
}
```

## Do

Either drop the repeat, or supply the value that was meant:

```dart
class RequestBuilder {
  String url = '';
  String method = '';
  int timeoutMs = 0;

  void header(String name, String value) {}
}

RequestBuilder build() {
  return RequestBuilder()
    ..url = '/orders'
    ..method = 'POST'
    ..header('accept', 'application/json')
    ..header('content-type', 'application/json')
    ..timeoutMs = 5000;
}
```

### Assigning the same field twice

A repeated assignment with the *same* value is dead. A repeated assignment with a *different* value is legal and never reported, so the rule does not stop you from overwriting on purpose:

```dart
class Config {
  String name = '';
}

void demo() {
  // Don't — the second write changes nothing
  final a = Config()
    ..name = 'test'
    ..name = 'test';

  // Fine — the second write is the one that matters
  final b = Config()
    ..name = 'draft'
    ..name = 'final';
}
```

### Repeated calls can have side effects

For a method the duplicate is worse than dead code: it runs twice. Two `add` calls on a list mean two elements:

```dart
void demo() {
  final numbers = <int>[]
    ..add(1)
    ..add(1);   // LINT — and `numbers` really does hold [1, 1]
}
```

If the repetition is deliberate, write it in a way that says so — a loop, or two distinct calls — rather than relying on the reader to notice.

## Known limitations

Duplicates are matched on **source text**, not on meaning. `..name = 'a'` and `..name = "a"` are different keys and neither is reported; so are `..header('x', y)` and `..header('x', y as String)`.

The comparison is per cascade expression. Two identical sections in two separate cascades on the same object are not compared with each other.

The report lands on the *second* occurrence, and the quick fix removes that section. When the same section appears three times, the second and third are each reported.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_duplicate_cascades: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_constant_switches`](/many_lints/docs/rules/control-flow/avoid-constant-switches/) — Detect switch statements on constant expressions.
