# `require_atomic_async_updates` matches a read in another method

**Reported:** 2026-08-26 (found adopting the plugin in a Flutter app)
**Status:** RESOLVED
**Affects:** `lib/src/rules/require_atomic_async_updates.dart`

## What happens

The rule reports a field whose read and write both sit *after* the same await,
with no suspension point between them. The "read before the await" it pairs
with the write lives in a **different method** — typically `dispose()`.

```dart
Timer? _feedbackTimer;

@override
void dispose() {
  _feedbackTimer?.cancel();   // <- the rule treats this as the "read before"
  super.dispose();
}

Future<void> _copy() async {
  await Clipboard.setData(...);
  if (!mounted) return;
  _feedbackTimer?.cancel();   // read, after the await
  _feedbackTimer = Timer(...); // write, no await in between  // LINT (false positive)
}
```

Nothing can interleave between the read and the write inside `_copy`: they are
separated by ordinary synchronous statements. `dispose()` is not a concurrent
writer either — after it runs the State is gone and `mounted` is false, which
the `if (!mounted) return;` above already handles.

## Expected

Only pair a read with a write when **both occur in the same function body** and
at least one `await` (or other suspension point) separates them. A read in a
sibling method is not evidence of an interleaved update.

## Real call sites

Two in one app, both already correct:

- `lib/core/presentation/copyable_url_field.dart:36` (`_feedbackTimer`)
- `lib/event_detail/presentation/widgets/generated_wishes_bubble.dart:92` (`_copyFeedbackTimer`)

Both follow the same shape: `dispose()` cancels the timer, and an async handler
cancels-then-reassigns it after its only await.

## Suggested test cases

```dart
// no_lint — read and write both after the await, nothing suspends between them
Timer? t;
void dispose() { t?.cancel(); }
Future<void> f() async {
  await g();
  t?.cancel();
  t = Timer(d, () {});
}

// lint — a real gap: the read is before the await, the write after it
Future<void> f() async {
  final current = t;
  await g();
  t = current ?? Timer(d, () {});
}
```

Environment: Dart 3.13.1, Flutter 3.47.1, many_lints 1.1.0.

## Resolved 2026-08-26 — but the diagnosis above was wrong

The report is real and the fix is in, however `dispose()` had nothing to do
with it. The rule never crossed a method boundary: `_scan` is called per
function body, so a read in a sibling method was never in the tracked set.
Deleting `dispose()` entirely leaves the false positive exactly where it was.

The actual cause is one visitor that failed to stop at a closure.
`_StaleReadFinder` — used by `_dependsOnStaleValue` to decide whether a write
reuses the pre-await read — was the only visitor in the rule without a
`visitFunctionExpression` override. So in:

```dart
_feedbackTimer = Timer(d, () {
  _feedbackTimer?.cancel();   // <- counted as "the write depends on the read"
});
```

the mention of the field inside the **callback being installed** made the write
look dependent on the stale value. Both real call sites have exactly that
shape, which is why they looked like the read-in-`dispose()` story: the two
happen to name the same field.

The tell is that the false positive survives deleting `dispose()` and vanishes
when the callback names a *different* field.

Fix: `_StaleReadFinder` stops at `visitFunctionExpression`, like every other
visitor in the file. A closure is not part of the value being written — it is a
callback that runs later, on its own timeline.

Tests: `test_callbackNamingTheFieldIsNotADependency` (the actual shape) and
`test_readAndWriteBothAfterTheSameAwait` (the shape this file described,
which was already passing and now guards against a regression).

Verified in the reporting app: both `ignore` comments removed, analyzer clean.
