---
title: prefer_and_then
description: "andThen says that the previous value is not used"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_and_then
---

<span class="rule-badge rule-badge--version">v1.1.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">fpdart</span>

This rule flags `flatMap` whose callback never reads the value it is handed, which is what `andThen` expresses.

## Why use this rule

fpdart declares `andThen` as literally `flatMap((_) => then())`, so this is not a behaviour change — it is the same call under the name that says what it does.

The cost of the long form is what a reader has to do to understand a pipeline. Every `flatMap` in a chain raises the question "does this step use the previous result?", and the only way to answer it is to open the callback and look for the parameter. `andThen` answers it in the name, which is why the same two-line shape keeps reappearing across unrelated features once someone notices it.

Only the provably-ignored case is reported. A callback that reads its parameter has a real dependency on the previous step, and `andThen` throws that value away.

**See also:** [fpdart `andThen`](https://pub.dev/documentation/fpdart/latest/fpdart/TaskEither/andThen.html)

## Don't

```dart
// The callback ignores its argument, so the name says less than it could.
resetter.reset().flatMap((_) => authRepository.logout());

// A named parameter nothing reads is the same situation.
catalog.clear().flatMap((value) => catalog.seed());
```

## Do

```dart
resetter.reset().andThen(authRepository.logout);

catalog.clear().andThen(catalog.seed);
```

## Not reported

A callback that uses its parameter is a real `flatMap`, and converting it would discard a value the next step depends on:

```dart
pipeline.flatMap((value) => parse(value));
```

A block-bodied callback is a real function and is left alone:

```dart
pipeline.flatMap((_) {
  return next();
});
```

An unrelated class with a `flatMap` method is never reported. The rule resolves the receiver's type rather than matching the name.

## Configuration

This rule is in the **`opinionated`** preset. With a lower preset, enable it by
name with `prefer_and_then: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_and_then: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_chain_either`](/many_lints/docs/rules/fpdart/prefer-chain-either/) — chainEither lifts a synchronous Either step for you.
- [`avoid_throw_in_fp_callback`](/many_lints/docs/rules/fpdart/avoid-throw-in-fp-callback/) — A throw inside an fpdart callback escapes the error channel the pipeline is built to carry.
