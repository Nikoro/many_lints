---
title: avoid_unmodified_loop_condition
description: "A while loop whose condition the body can never change"
sidebar:
  label: avoid_unmodified_loop_condition
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

This rule flags a `while` or `do`/`while` loop whose condition reads only variables that the body never assigns. The condition evaluates the same way forever, so the loop either never runs or never stops.

## Why use this rule

An infinite loop is not a subtle failure — it hangs the isolate, freezes the UI, and in a Flutter app looks like a crash. But the *cause* is subtle: a forgotten `i++`, or an increment applied to the wrong variable in a loop that reads a different one.

Static detection is possible because the condition and the body are right next to each other. If no variable the condition reads is ever written in the body, no execution can change the outcome.

**See also:** [Dart: loops](https://dart.dev/language/loops)

## Don't

```dart
var i = 0;
while (i < items.length) {
  print(items[i]);   // `i` is never advanced
}
```

Advancing the wrong variable is the same bug wearing a disguise:

```dart
var i = 0;
var j = 0;
while (i < limit) {
  j++;               // `i` still never changes
}
```

## Do

```dart
var i = 0;
while (i < items.length) {
  print(items[i]);
  i++;
}
```

Or use a construct that advances for you:

```dart
for (final item in items) {
  print(item);
}
```

## Known limitations

The rule is deliberately narrow, because the cost of a false positive here is high.

`while (true)` is not reported — it is the idiomatic infinite loop, ended by a `break`. Any `break`, `return` or `throw` in the body suppresses the report for the same reason: the loop has an exit the condition does not control.

Only locals and parameters are tracked. A condition that reads a field, calls a method, accesses a property, or awaits is treated as opaque: those can change without an assignment in the body, so no conclusion is safe. A closure anywhere in the body also suppresses the report, since it may mutate a captured variable when invoked.

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_unmodified_loop_condition: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
