---
title: avoid_catch_error
description: "Use try/catch instead of Future.catchError"
sidebar:
  label: avoid_catch_error
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule flags calls to `Future.catchError`. The same error handling is expressed more safely with `await` inside a `try`/`catch` block.

## Why use this rule

`catchError` accepts a plain `Function`, not a typed callback. The analyzer therefore cannot check the handler's signature at all: passing a callback that takes the wrong number of parameters compiles cleanly and throws `ArgumentError` at runtime — and only on the error path, which is the path least likely to be exercised by a test.

The `test` parameter adds a second trap. When it returns `false` the error is *not* handled; it flows on to the next handler or to the zone's error handler, even though the code reads as though the error was caught.

`try`/`catch` avoids both problems. The catch clause's parameters are checked at compile time, the control flow is explicit, and `on SomeError catch (e)` expresses the filtering that `test` was doing.

**See also:** [`Future.catchError` API docs](https://api.dart.dev/stable/dart-async/Future/catchError.html), [Dart: asynchronous programming](https://dart.dev/language/async), [Effective Dart: avoid using `Future.catchError`](https://dart.dev/libraries/async/futures-error-handling)

## Don't

```dart
// The handler's signature is unchecked — an arity mistake here throws
// at runtime, not at compile time.
Future<int> load() {
  return repository.fetch().catchError((err, st) {
    log(err, st);
    return 0;
  });
}
```

## Do

```dart
Future<int> load() async {
  try {
    return await repository.fetch();
  } catch (err, st) {
    log(err, st);
    return 0;
  }
}
```

Filtering by error type becomes an `on` clause:

```dart
Future<int> load() async {
  try {
    return await repository.fetch();
  } on TimeoutException catch (err, st) {
    log(err, st);
    return 0;
  }
}
```

## Known limitations

Only invocations are reported. A tear-off such as `future.catchError` is left alone, since there is no call site to rewrite.

The receiver must resolve to a `Future` (or a subtype), so an unrelated user-defined `catchError` method is never flagged. If the receiver's type cannot be resolved, the rule stays silent.

## Configuration

This rule is in the **`opinionated`** preset. With a lower preset, enable it by
name with `avoid_catch_error: true`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  avoid_catch_error: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_future_ignore`](/many_lints/docs/rules/async-safety/avoid-future-ignore/) — Do not silently suppress Future errors with an unexplained ignore call.
- [`avoid_missing_completer_stack_trace`](/many_lints/docs/rules/async-safety/avoid-missing-completer-stack-trace/) — Pass the stack trace to Completer.completeError.
- [`avoid_nested_futures`](/many_lints/docs/rules/async-safety/avoid-nested-futures/) — Don't declare Future&lt;Future&lt;T&gt;&gt;.
- [`avoid_passing_async_when_sync_expected`](/many_lints/docs/rules/async-safety/avoid-passing-async-when-sync-expected/) — Don't pass an async closure where a void-returning function is expected.
