---
title: avoid_future_ignore
description: "Do not silently suppress Future errors with an unexplained ignore call"
sidebar:
  label: avoid_future_ignore
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Async Safety</span>

This rule flags `Future.ignore()` when no adjacent comment explains why both
the result and any asynchronous error are intentionally irrelevant. It only
matches Dart's `FutureExtensions.ignore`, so an unrelated class with its own
`ignore()` method is left alone.

The rule is part of the **`recommended`** preset.

## Why use this rule

`unawaited(future)` documents fire-and-forget execution while leaving an
unexpected error visible to the current zone. `future.ignore()` goes further:
it installs an error handler that deliberately consumes the error. That is
occasionally correct, but it should be a reviewed decision rather than a
convenient way to silence `unawaited_futures`.

An immediately preceding line or block comment exempts the call. This keeps
best-effort cleanup and obsolete requests expressible while making the reason
visible beside the suppression.

**See also:** [Dart `Future.ignore()`](https://api.dart.dev/dart-async/FutureExtensions/ignore.html), [DCM `avoid-future-ignore`](https://dcm.dev/docs/rules/common/avoid-future-ignore/), [`unawaited_futures`](https://dart.dev/tools/diagnostics/unawaited_futures)

## Don't

```dart
void saveInBackground(Future<void> save) {
  save.ignore(); // failures disappear
}
```

## Do

Keep unexpected errors observable:

```dart
import 'dart:async';

void saveInBackground(Future<void> save) {
  unawaited(save);
}
```

When suppressing errors is genuinely part of the contract, document it:

```dart
void discardObsoleteRequest(Future<void> request) {
  // The response is obsolete, including any failure it produces.
  request.ignore();
}
```

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_future_ignore: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_correct_future_return_type`](/many_lints/docs/rules/async-safety/prefer-correct-future-return-type/) — Expose async results as non-nullable Future values.
- [`avoid_nested_futures`](/many_lints/docs/rules/async-safety/avoid-nested-futures/) — Don't declare Future&lt;Future&lt;T&gt;&gt;.
- [`avoid_passing_async_when_sync_expected`](/many_lints/docs/rules/async-safety/avoid-passing-async-when-sync-expected/) — Don't pass an async closure where a void-returning function is expected.
- [`avoid_redundant_async`](/many_lints/docs/rules/async-safety/avoid-redundant-async/) — Flag an async function that never awaits.
