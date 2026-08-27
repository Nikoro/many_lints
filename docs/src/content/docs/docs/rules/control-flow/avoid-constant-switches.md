---
title: avoid_constant_switches
description: "Detect switch statements on constant expressions"
sidebar:
  label: avoid_constant_switches
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Flags a `switch` statement or switch expression whose subject is a compile-time constant. The value never changes, so one case always wins and every other case is unreachable.

## Don't

Switching on the constant rather than on the value it was meant to be compared with:

```dart
abstract final class Config {
  static const channel = 'stable';
}

String bannerText() {
  switch (Config.channel) {
    case 'stable':
      return 'Welcome';
    case 'beta':
      return 'Thanks for testing';   // Unreachable
    default:
      return '';                     // Unreachable
  }
}
```

## Do

Switch on something that varies at runtime:

```dart
abstract final class Config {
  static const channel = 'stable';
}

String bannerText(String channel) {
  switch (channel) {
    case 'stable':
      return 'Welcome';
    case 'beta':
      return 'Thanks for testing';
    default:
      return '';
  }
}
```

If the value really is fixed, you did not need a switch — say what you meant:

```dart
abstract final class Config {
  static const channel = 'stable';
}

String bannerText() => 'Welcome';
```

### Switch expressions are covered too

The rule registers both forms, so an expression switch on a literal reports the same way:

```dart
void demo() {
  // Don't
  final label = switch (42) {
    42 => 'answer',
    _ => 'other',
  };
}
```

### An enum constant is constant

`Status.active` is a `const` field on the enum, so switching on it takes the same fixed branch every time:

```dart
enum Status { active, archived }

void demo() {
  // Don't — switch on the value, not on the constant you are testing for
  switch (Status.active) {
    case Status.active:
      print('live');
    case Status.archived:
      print('gone');
  }
}
```

Switching on `order.status` reads a property and is never reported.

## Known limitations

The diagnostic lands on the switch *subject*, not on the whole statement, so the highlight points at the expression you need to change.

Constness is read syntactically: literals, `const` variables and static `const` fields (enum constants included), `const` collections and `const` constructor calls. A plain `final` local is **not** treated as constant — `final mode = 'debug'; switch (mode)` is not reported. Neither is a method call, so `switch (buildMode())` stays silent even when the function always returns the same thing.

There is no quick fix: replacing the subject with the right variable is the design decision the rule is asking about.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_constant_switches: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_constant_conditions`](/many_lints/docs/rules/control-flow/avoid-constant-conditions/) — Detect comparisons where both sides are constants.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
- [`avoid_contradictory_expressions`](/many_lints/docs/rules/control-flow/avoid-contradictory-expressions/) — Detect logical AND conditions that always evaluate to false.
