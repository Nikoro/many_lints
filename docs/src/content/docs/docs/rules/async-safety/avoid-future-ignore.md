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

Reaching for `.ignore()` to quiet an `unawaited_futures` warning. A failed save now vanishes with no trace anywhere:

```dart
void saveDraft(Future<void> save) {
  save.ignore();
}
```

## Do

Keep unexpected errors observable. `unawaited` says "I am not waiting for this" without also saying "I do not care if it fails":

```dart
import 'dart:async';

void saveDraft(Future<void> save) {
  unawaited(save);
}
```

### When discarding the error really is the contract

Write the reason immediately above the call and the rule accepts it:

```dart
void discardObsoleteRequest(Future<void> request) {
  // The user typed again, so this response is obsolete — including any
  // failure it produces.
  request.ignore();
}
```

An inline block comment before the call works too, which suits a one-liner:

```dart
void pingBeacon(Future<void> ping) {
  /* Best-effort analytics; a failure changes nothing. */ ping.ignore();
}
```

## Known limitations

**The comment must come immediately before the call.** A blank line between them breaks the exemption, and a trailing comment on the same line does not count — the rule only reads comments attached ahead of the call:

```dart
// Not exempt: a blank line separates them.
void a(Future<void> f) {
  // The failure is irrelevant.

  f.ignore();   // still reported
}

// Not exempt: the comment trails the call.
void b(Future<void> f) {
  f.ignore(); // the failure is irrelevant — still reported
}
```

Only Dart's own `FutureExtensions.ignore` is matched, resolved by declaration. A class of your own with an `ignore()` method is never flagged, and neither is a call passing arguments.

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
