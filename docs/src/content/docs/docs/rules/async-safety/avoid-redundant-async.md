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

`async` without `await` is not automatically redundant — it still wraps a raw
return value and turns a synchronous throw into an asynchronous error. The rule
reports only the case where neither applies: every explicit return already
produces a compatible `Future`, so dropping the keyword changes nothing but the
noise.

**See also:** [Dart asynchrony support](https://dart.dev/language/async)

## Don't

The body already hands back a future, so `async` adds a wrap-and-unwrap round trip and nothing else:

```dart
Future<List<String>> loadAll(List<Future<String>> pending) async {
  return Future.wait(pending);
}
```

## Do

```dart
Future<List<String>> loadAll(List<Future<String>> pending) {
  return Future.wait(pending);
}
```

### Forwarding to another async call

The same shape shows up most often in a thin delegating method:

```dart
// Don't
Future<User> fetchUser(String id) async {
  return _api.getUser(id);
}

// Do
Future<User> fetchUser(String id) {
  return _api.getUser(id);
}
```

Note this is only equivalent because there is no `await`. If you add one — `return await _api.getUser(id);` — the `async` is doing real work and the rule stays quiet.

### What is left alone

`async` is not redundant when it is the thing producing the future, or converting a throw into an asynchronous error:

```dart
Future<int> count() async => 1;              // wraps a raw value

Future<int> mustExist() async {
  throw StateError('missing');               // becomes an async error
}

Future<int> lookup(String id) async {
  return await _cache.read(id);              // has an await
}
```

An `async*` stream generator and an `@override` are both skipped as well — the keyword is load-bearing in the first, and an override's signature is not this rule's to rewrite.

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
