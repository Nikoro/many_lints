---
title: avoid_redundant_async
description: "Flag an async function that never awaits"
sidebar:
  label: avoid_redundant_async
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule flags a function marked `async` whose body never awaits or throws,
and whose return paths already produce compatible `Future` values. Removing
`async` is therefore a cleanup that keeps the code compiling.

The rule is part of the **`opinionated`** preset.

## Why use this rule

`async` without `await` is not automatically redundant. It still wraps a raw
return value in a future and converts a synchronous throw into an asynchronous
error. In both cases removing it would change semantics or produce code that
does not compile, so the rule deliberately stays silent.

A function whose paths already return futures needs no `async` for callers to
await it. The rule checks the resolved types of every explicit return before
reporting and leaves fall-through or bare-return bodies alone.

Other cases left alone include `async*`, where the keyword makes the function
a stream generator, and an `@override`, whose implementation details should
not be rewritten by this cleanup rule.

**See also:** [Dart asynchrony support](https://dart.dev/language/async)

## Don't

```dart
Future<List<Config>> loadAll() async {
  return Future.wait(_pending);
}
```

## Do

```dart
Future<List<Config>> loadAll() {
  return Future.wait(_pending);
}
```

Returning a raw value is valid and is not reported, because `async` performs
the required wrapping:

```dart
Future<int> count() async => 1;
```

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_redundant_async: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_passing_async_when_sync_expected`](/many_lints/docs/rules/async-safety/avoid-passing-async-when-sync-expected/) — Don't pass an async closure where a void-returning function is expected.
- [`avoid_future_ignore`](/many_lints/docs/rules/async-safety/avoid-future-ignore/) — Do not silently suppress Future errors with an unexplained ignore call.
- [`avoid_nested_futures`](/many_lints/docs/rules/async-safety/avoid-nested-futures/) — Don't declare Future&lt;Future&lt;T&gt;&gt;.
- [`prefer_correct_future_return_type`](/many_lints/docs/rules/async-safety/prefer-correct-future-return-type/) — Expose async results as non-nullable Future values.
