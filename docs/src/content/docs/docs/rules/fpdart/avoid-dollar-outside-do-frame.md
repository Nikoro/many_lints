---
title: avoid_dollar_outside_do_frame
description: "Calling a Do block's extraction function from a nested callback unwinds through code that cannot handle it"
sidebar:
  label: avoid_dollar_outside_do_frame
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">fpdart</span>

This rule flags a call to a `Do` block's extraction function (`$`) that sits inside a callback nested within the block, rather than in the block's own frame.

## Why use this rule

`$` short-circuits by throwing a private marker that the `Do` constructor catches. That mechanism only works while control is still inside the block's own frame.

Called from a `map` or `flatMap` callback, the marker unwinds through fpdart's own combinator machinery, which never expects it. Instead of the `Left` the code appears to produce, the caller gets a raw exception — or, when an intermediate layer swallows it, a silently wrong result.

This is one of four `Do` pitfalls that fpdart documents in its own `do_constructor_pitfalls` example.

**See also:** [fpdart: Do notation](https://pub.dev/packages/fpdart#-do-notation)

## Don't

```dart
Option.Do(($) => $(testOption).map(
      (value) => $(optionOf(value)), // `$` outside the Do's own frame
    ));
```

## Do

Extract in the block itself, then use the plain value in the callback:

```dart
Option.Do(($) {
  final value = $(testOption);
  return $(optionOf(value));
});
```

## Known limitations

A `$` tear-off passed to another function and called from there is not reported. The rule is about lexical position, and an escaped `$` is a different — and much rarer — problem.

An inner `Do` block's `$` belongs to that inner frame, so the outer block is not blamed for it. The nesting itself is reported by [`avoid_nested_do_notation`](/many_lints/docs/rules/fpdart/avoid-nested-do-notation/).

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_dollar_outside_do_frame: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_bare_await_in_do`](/many_lints/docs/rules/fpdart/avoid-bare-await-in-do/) — Awaiting a raw Future inside a Do block escapes the block's tracking.
- [`avoid_nested_do_notation`](/many_lints/docs/rules/fpdart/avoid-nested-do-notation/) — A nested Do block short-circuits on its own instead of failing the outer pipeline.
- [`prefer_do_notation`](/many_lints/docs/rules/fpdart/prefer-do-notation/) — Deeply nested flatMap callbacks read flatter as a Do block.
- [`avoid_ad_hoc_left_type`](/many_lints/docs/rules/fpdart/avoid-ad-hoc-left-type/) — A pipeline only composes when every step shares one error type.
