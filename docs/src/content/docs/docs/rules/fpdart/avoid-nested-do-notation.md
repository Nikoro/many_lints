---
title: avoid_nested_do_notation
description: "A nested Do block short-circuits on its own instead of failing the outer pipeline"
sidebar:
  label: avoid_nested_do_notation
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">fpdart</span>

This rule flags an fpdart `Do` block written inside another `Do` block.

## Why use this rule

Each `Do` establishes its own extraction frame, and the inner block shadows the outer block's `$`. An extraction that fails inside the inner body therefore short-circuits only the *inner* block: the outer block receives a perfectly ordinary `None`/`Left` **as a value** and carries on. The pipeline you meant to abort keeps running.

`Do` is sugar over `flatMap`, so a nested block is never necessary — the inner block's steps can be extracted in the outer one directly.

This is one of four `Do` pitfalls that fpdart documents in its own `do_constructor_pitfalls` example. The others are [`avoid_throw_in_fp_callback`](/many_lints/docs/rules/fpdart/avoid-throw-in-fp-callback/), [`avoid_bare_await_in_do`](/many_lints/docs/rules/fpdart/avoid-bare-await-in-do/) and [`avoid_dollar_outside_do_frame`](/many_lints/docs/rules/fpdart/avoid-dollar-outside-do-frame/).

**See also:** [fpdart: Do notation](https://pub.dev/packages/fpdart#-do-notation)

## Don't

```dart
Option.Do(($) => $(Option.Do(($) => $(testOption))));
```

## Do

```dart
Option.Do(($) => $(testOption));
```

With several steps, extract each one in the same frame:

```dart
TaskEither.Do(($) async {
  final file = await $(fileAt(path));
  final content = await $(readAsString(file));
  return content;
});
```

## Known limitations

The rule reports the *inner* block, which is the one to unwrap. In a three-level nest both inner blocks are reported, since each is separately wrong.

Sibling `Do` blocks in the same function are fine and are never reported — only lexical nesting matters.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_nested_do_notation: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_do_notation`](/many_lints/docs/rules/fpdart/prefer-do-notation/) — Deeply nested flatMap callbacks read flatter as a Do block.
- [`avoid_bare_await_in_do`](/many_lints/docs/rules/fpdart/avoid-bare-await-in-do/) — Awaiting a raw Future inside a Do block escapes the block's tracking.
- [`avoid_dollar_outside_do_frame`](/many_lints/docs/rules/fpdart/avoid-dollar-outside-do-frame/) — Calling a Do block's extraction function from a nested callback unwinds through code that cannot handle it.
- [`avoid_ad_hoc_left_type`](/many_lints/docs/rules/fpdart/avoid-ad-hoc-left-type/) — A pipeline only composes when every step shares one error type.
