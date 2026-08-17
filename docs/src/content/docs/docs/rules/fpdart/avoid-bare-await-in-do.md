---
title: avoid_bare_await_in_do
description: "Awaiting a raw Future inside a Do block escapes the block's tracking"
sidebar:
  label: avoid_bare_await_in_do
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">fpdart</span>

This rule flags an `await` inside an asynchronous `Do` body whose operand is not an extraction through the block's `$` function.

## Why use this rule

`Do` tracks a block's steps through its extraction function: `$` is what makes a failing step short-circuit the rest of the block, and what turns a thrown error into a `Left`.

A bare `await someFuture` bypasses that machinery entirely. The future runs outside the block's control, and when it fails the exception escapes as an ordinary exception — past every `fold` and `match` the caller wrote, because those only ever see the error channel.

This is one of four `Do` pitfalls that fpdart documents in its own `do_constructor_pitfalls` example.

**See also:** [fpdart: Do notation](https://pub.dev/packages/fpdart#-do-notation)

## Don't

```dart
TaskEither<String, int> f(Future<int> future) => TaskEither.Do(($) async {
  await future; // escapes the Do tracking
  return 1;
});
```

## Do

```dart
TaskEither<String, int> f(Future<int> future) => TaskEither.Do(($) async {
  await $(TaskEither.tryCatch(() => future, (e, s) => '$e'));
  return 1;
});
```

## Known limitations

Only asynchronous blocks are checked. `Option.Do`, `Either.Do` and the `IO*` variants are synchronous and cannot hit this.

An `await` inside a closure declared within the body is not reported: that closure has its own async context, so the `await` was never one of the block's tracked steps.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_bare_await_in_do: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_dollar_outside_do_frame`](/many_lints/docs/rules/fpdart/avoid-dollar-outside-do-frame/) — Calling a Do block's extraction function from a nested callback unwinds through code that cannot handle it.
- [`avoid_nested_do_notation`](/many_lints/docs/rules/fpdart/avoid-nested-do-notation/) — A nested Do block short-circuits on its own instead of failing the outer pipeline.
- [`prefer_do_notation`](/many_lints/docs/rules/fpdart/prefer-do-notation/) — Deeply nested flatMap callbacks read flatter as a Do block.
- [`avoid_ad_hoc_left_type`](/many_lints/docs/rules/fpdart/avoid-ad-hoc-left-type/) — A pipeline only composes when every step shares one error type.
