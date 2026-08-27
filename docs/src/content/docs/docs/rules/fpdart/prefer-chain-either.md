---
title: prefer_chain_either
description: "chainEither lifts a synchronous Either step for you"
sidebar:
  label: prefer_chain_either
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">fpdart</span>

This rule flags `flatMap` on a `TaskEither` whose callback does nothing but call `toTaskEither()` on a synchronous `Either` step.

## Why use this rule

`chainEither` is `flatMap` for a step that is synchronous and failable. It takes the `Either`-returning function directly and does the lifting itself, so the manual `toTaskEither()` re-implements a method the package already provides.

In a decoding pipeline these steps come in runs — status check, decode, cast, key lookup, model mapping — and each one carrying its own `.toTaskEither()` turns a readable ladder into noise. `chainEither` lets each validator stay a small, separately testable `Either`.

**See also:** [Real-world fpdart: decoding an API response](https://www.sandromaglione.com/articles/real_example_fpdart_open_meteo_api_part_1)

## Don't

```dart
TaskEither<String, String> fetchBody() => TaskEither.of('{"id":1}');

Either<String, int> decode(String body) => Either.of(body.length);

TaskEither<String, int> load() =>
    fetchBody().flatMap((body) => decode(body).toTaskEither());
```

## Do

```dart
TaskEither<String, int> load() => fetchBody().chainEither(decode);
```

A run of validators reads as a ladder, each rung an ordinary `Either`:

```dart
Either<String, String> checkStatus(String body) => Either.of(body);

Either<String, int> decodeJson(String body) => Either.of(body.length);

Either<String, int> toId(int raw) => Either.of(raw);

TaskEither<String, int> load() => fetchBody()
    .chainEither(checkStatus)
    .chainEither(decodeJson)
    .chainEither(toId);
```

## Known limitations

The callback must do nothing but return the lifted step. When it also logs, branches, or computes something first, rewriting to `chainEither` would drop that work, so the rule stays silent.

A `flatMap` whose step genuinely returns a `TaskEither` is correct as written and is never reported.

## Configuration

This rule is in the **`opinionated`** preset. With a lower preset, enable it by
name with `prefer_chain_either: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_chain_either: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_get_or_else_swallowing_failure`](/many_lints/docs/rules/fpdart/avoid-get-or-else-swallowing-failure/) — getOrElse is handed the failure; ignoring it should be a visible decision.
- [`avoid_throw_in_fp_callback`](/many_lints/docs/rules/fpdart/avoid-throw-in-fp-callback/) — A throw inside an fpdart callback escapes the error channel the pipeline is built to carry.
- [`prefer_and_then`](/many_lints/docs/rules/fpdart/prefer-and-then/) — andThen says that the previous value is not used.
- [`avoid_either_of_future`](/many_lints/docs/rules/fpdart/avoid-either-of-future/) — A Future nested in Either or Option escapes the error channel.
