---
title: prefer_return_await
description: "Detect missing await on returned Futures inside try-catch"
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_return_await
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Control Flow</span>

Warns when a `Future` is returned without `await` inside a try-catch block in an async function. Without `await`, any exception thrown by the Future will not be caught by the surrounding catch block, silently bypassing your error handling.

## Why use this rule

When you write `return asyncOp()` inside a try-catch, the Future is returned to the caller without being awaited. If `asyncOp()` throws, the exception propagates to the caller instead of being caught by the local catch block. Adding `await` ensures the Future completes within the try-catch scope, so exceptions are properly caught and handled.

**See also:** [Asynchronous programming](https://dart.dev/libraries/async/async-await) | [Dart lint: unnecessary_await_in_return](https://dart.dev/tools/linter-rules/unnecessary_await_in_return)

## Don't

```dart
Future<String> fetchToken() async => 'token';

Future<String> token() async {
  try {
    // fetchToken() completes after this function has already returned, so
    // its exception never reaches the catch below.
    return fetchToken();
  } catch (e) {
    return 'anonymous';
  }
}
```

## Do

```dart
Future<String> fetchToken() async => 'token';

Future<String> token() async {
  try {
    return await fetchToken();
  } catch (e) {
    return 'anonymous';
  }
}
```

A `return` inside a `catch` clause escapes an outer `try` just as easily, so it needs the `await` too:

```dart
Future<String> fetchToken() async => 'token';
Future<String> retryToken() async => 'token';

Future<String> token() async {
  try {
    return await fetchToken();
  } catch (e) {
    // Don't — this Future escapes any enclosing try as well.
    return retryToken();
  }
}
```

## Known limitations

Three shapes are deliberately not reported:

**Outside any try-catch.** There is no local scope to keep the Future inside, and the caller owns the error:

```dart
Future<String> fetchToken() async => 'token';

Future<String> token() async => fetchToken();
```

**A non-`async` function.** It has no try-catch scope for the Future to complete in, so returning it unawaited is the only option:

```dart
Future<String> fetchToken() async => 'token';

Future<String> token() {
  try {
    return fetchToken();
  } catch (e) {
    return Future.value('anonymous');
  }
}
```

**A `finally` block.** A `return` there is already outside the guarded region.

Recent Dart SDKs ship a built-in `unawaited_return_in_try_block` warning that
covers the **try body** case, so you may see two diagnostics on the same line
there. The `catch` clause is this rule's alone.

## Configuration

This rule is in the **`core`** preset, so it is on with `preset: core`,
`preset: recommended` or `preset: opinionated`.

To turn it off:

```yaml
# many_lints.yaml
rules:
  prefer_return_await: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_unnecessary_return`](/many_lints/docs/rules/control-flow/avoid-unnecessary-return/) — Remove a bare `return;` that ends a void function.
- [`prefer_early_return`](/many_lints/docs/rules/control-flow/prefer-early-return/) — Replace a body-wrapping if with an early-return guard.
- [`avoid_cascade_after_if_null`](/many_lints/docs/rules/control-flow/avoid-cascade-after-if-null/) — Detect cascades after if-null operators without parentheses.
- [`avoid_collapsible_if`](/many_lints/docs/rules/control-flow/avoid-collapsible-if/) — Merge nested if statements with &amp;&amp;.
