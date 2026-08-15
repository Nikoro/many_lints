---
title: avoid_redundant_async
description: "Flag an async function that never awaits"
sidebar:
  label: avoid_redundant_async
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule flags a function marked `async` whose body never awaits.

## Why use this rule

`async` without `await` is not free. The body stops running synchronously up to its first suspension, the result is wrapped in an extra `Future`, and a `throw` becomes a rejected future rather than a synchronous error a caller can catch at the call site. None of that is what the author wanted when the keyword is simply left over from a body that used to await.

A function already returning a `Future` needs no `async` for its callers to await it, so removing the keyword keeps the signature intact.

Three cases are left alone: `async*`, where the keyword is what makes the function a stream generator; an `@override`, whose `async` may be required by the supertype; and a body with nothing to return, where dropping `async` would turn `Future<void>` into `void` — a signature change rather than a cleanup.

**See also:** [Dart asynchrony support](https://dart.dev/language/async)

## Don't

```dart
Future<Config> load() async {
  return _cached;
}
```

## Do

```dart
Future<Config> load() {
  return _cached;
}
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_redundant_async: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
