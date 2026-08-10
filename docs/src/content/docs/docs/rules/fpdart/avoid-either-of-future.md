---
title: avoid_either_of_future
description: "A Future nested in Either or Option escapes the error channel"
sidebar:
  label: avoid_either_of_future
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">fpdart</span>

This rule flags a `Future` nested inside the synchronous `Either` or `Option` — either written as a type (`Either<Failure, Future<League>>`) or produced by mapping with an async function.

## Why use this rule

`Either` and `Option` are synchronous wrappers. Mapping one with a function that returns a `Future` does not make the pipeline async — it makes an `Either<L, Future<R>>`.

That type is a trap. The future is created and starts running immediately, but it sits *inside* the success channel, so the error channel no longer covers it. A rejection becomes an unhandled async error rather than a `Left`, and callers receive a `Right` holding a future that may already have failed. Every `fold` written downstream still reports success.

The pipeline has to enter the async world at that point, which is exactly what `toTaskEither()` is for.

**See also:** [fpdart: TaskEither](https://pub.dev/documentation/fpdart/latest/fpdart/TaskEither-class.html), [From sync to async functional programming](https://www.sandromaglione.com/articles/from-sync-to-async-functional-programming)

## Don't

```dart
Either<Failure, Future<League>> save(LeagueDraft draft) =>
    validate(draft).map((valid) => api.saveLeague(valid));
```

## Do

Convert once, early, then keep chaining in the async world:

```dart
TaskEither<Failure, League> save(LeagueDraft draft) =>
    validate(draft).toTaskEither().flatMap(
          (valid) => TaskEither.tryCatch(
            () => api.saveLeague(valid),
            (e, s) => Failure.from(e),
          ),
        );
```

`chainEither` is the counterpart when a synchronous validation step joins an already-async pipeline.

## Known limitations

`TaskEither`, `TaskOption` and the other async wrappers are unaffected — a `Future` belongs inside them.

An `Iterable.map` returning futures is ordinary Dart and is never reported; only fpdart's synchronous wrappers are.

This rule is about a `Future` nested *inside* `Either`. The reverse nesting, `Future<Either<L, R>>`, is a different matter — it is correct, merely not idiomatic — and is covered by [`avoid_future_of_either`](/many_lints/docs/rules/fpdart/avoid-future-of-either/).

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: all`. Add it to `preset: core` with
`avoid_either_of_future: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_either_of_future: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
