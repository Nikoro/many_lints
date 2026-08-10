---
title: avoid_untyped_safe_cast
description: "safeCast without explicit type arguments infers dynamic and always succeeds"
sidebar:
  label: avoid_untyped_safe_cast
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">fpdart</span>

This rule flags a call to `Either.safeCast`, `Option.safeCast` or `Either.safeCastStrict` whose target type was inferred as `dynamic` because no type arguments were written and the context supplied none.

## Why use this rule

`safeCast` takes its input as `dynamic` and decides the outcome with `value is R`. When the call carries no type arguments and nothing in the surrounding context constrains inference, `R` lands on `dynamic` — and every value satisfies `is dynamic`.

The cast can therefore never fail. `Either.safeCast` always returns `Right`, `Option.safeCast` always returns `Some`, and a validator written to reject malformed input silently accepts everything. Nothing looks wrong at the call site, the analyzer says nothing, and the bad payload surfaces much later as a cast error on some unrelated field.

fpdart's own API documentation carries this warning on both constructors — *"Make sure to specify the types of `Either` … otherwise this will always return `Right`!"*. This rule enforces it.

**See also:** [fpdart: `Either.safeCast`](https://pub.dev/documentation/fpdart/latest/fpdart/Either/Either.safeCast.html), [fpdart: `Option.safeCast`](https://pub.dev/documentation/fpdart/latest/fpdart/Option/Option.safeCast.html)

## Don't

```dart
// R infers as dynamic — this is always Right, whatever `json` holds.
final result = Either.safeCast(json, (v) => 'not a map');
```

## Do

Write the target type on the call:

```dart
final result = Either<String, Map<String, dynamic>>.safeCast(
  json,
  (v) => 'not a map',
);
```

Letting the context supply it works just as well, and is not reported:

```dart
Either<String, int> parse(dynamic json) =>
    Either.safeCast(json, (v) => 'not an int');
```

## Known limitations

The rule reports on the *inferred* type, not on the absence of type arguments. A call that omits them but sits in a context that constrains the type — a typed variable, a return position, a typed argument — is correct and stays silent.

That is the whole point: `final Either<String, int> r = Either.safeCast(...)` behaves exactly as intended, and flagging it would push authors toward redundant annotations.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: all`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_untyped_safe_cast: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
