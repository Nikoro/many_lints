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
pipeline.flatMap((body) => decode(body).toTaskEither());
```

## Do

```dart
pipeline.chainEither(decode);
```

The full ladder reads as a sequence of validators, each one an ordinary `Either`:

```dart
TaskEither<Failure, Location> locationSearch(String query) =>
    TaskEither<Failure, http.Response>.tryCatch(
      () => _httpClient.get(uri),
      (e, s) => Failure.from(e),
    )
        .chainEither(checkStatus)
        .chainEither(decodeJson)
        .chainEither(toLocation);
```

## Known limitations

The callback must do nothing but return the lifted step. When it also logs, branches, or computes something first, rewriting to `chainEither` would drop that work, so the rule stays silent.

A `flatMap` whose step genuinely returns a `TaskEither` is correct as written and is never reported.

## Configuration

This rule is in the **`recommended`** preset, so it is on with
`preset: recommended` or `preset: all`. Add it to `preset: core` with
`prefer_chain_either: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_chain_either: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
