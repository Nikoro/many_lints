# `use_setstate_synchronously` fires on `if (mounted) setState(...)`

**Reported:** 2026-08-26 (found adopting the plugin in a Flutter app)
**Status:** RESOLVED
**Affects:** `lib/src/rules/use_setstate_synchronously.dart`

## What happens

The rule reports correctly guarded code. Both shapes below are safe, but only
the first one is recognised:

```dart
// Recognised — clears the after-await flag.
await something();
if (!mounted) return;
setState(() => _loading = false);

// REPORTED, though it cannot call setState on a disposed State.
await something();
if (mounted) setState(() => _loading = false);        // LINT (false positive)

// REPORTED too.
await something();
if (mounted) {
  setState(() { ... });
}
```

Two real call sites in one app, both already correct:

- `lib/core/presentation/app_web_view_document_page.dart:35`
  `await _applyAppPresentation(); if (mounted) setState(() => _isLoading = false);`
- `lib/licenses/presentation/package_license_page.dart:50`
  `if (mounted) { setState(() { ... }); }`

A third shape misses too — an early return whose condition is a disjunction:

```dart
final succeeded = await widget.onDelete!();
if (!mounted || succeeded) return;   // establishes mounted on the path below
setState(() => _deleteFailed = true);            // LINT (false positive)
```

`isMountedGuardWithReturn` evidently matches the bare `if (!mounted) return;`
and not `!mounted || other`, even though reaching the next line still proves
`mounted`.

## Why

`_SetStateAfterAwaitFinder.visitBlock` tracks `afterAwait` and clears it only
for `isMountedGuardWithReturn(statement)` — the early-return form. Any other
statement goes to `_reportSetStateIn`, which walks the whole statement for
`setState` invocations without asking whether that statement *is* a `mounted`
guard wrapping them:

```dart
if (afterAwait && isMountedGuardWithReturn(statement)) {
  afterAwait = false;
  continue;
}

if (afterAwait) _reportSetStateIn(statement);   // <-- an `if (mounted) …` lands here
```

So the positive guard is treated as ordinary code that happens to contain a
`setState`.

## Why it matters

`if (mounted) setState(...)` is idiomatic and common — it is what you write when
there is nothing to do after the guard, so an early `return` would be noise.
Reporting it pushes people to either restructure working code or switch the rule
off, and the rule is worth keeping on: its true positives are real crashes.

## Suggested fix

Before reporting, check whether the statement is an `if` whose condition
establishes `mounted` and whose `setState` calls all sit in the *then* branch.
The condition check already exists in whatever `isMountedGuardWithReturn` uses
to recognise `!mounted`; this needs the un-negated counterpart.

Cases to keep reporting, so the fix does not overshoot:

- `if (mounted) { … } else { setState(…); }` — the else branch is unguarded.
- `if (mounted || other) setState(…);` — the disjunction does not establish it.
- `if (mounted) { await x(); setState(…); }` — a fresh gap opens *inside* the
  guard, so the guard no longer holds at the `setState`.
- `if (!mounted && other) return;` — a conjunction does not establish it.

## Suggested tests

```dart
// no_lint
await f();
if (mounted) setState(() {});

// no_lint
await f();
if (mounted) {
  setState(() {});
}

// lint — gap reopened inside the guard
await f();
if (mounted) {
  await g();
  setState(() {});
}

// lint — else branch is not guarded
await f();
if (mounted) {} else { setState(() {}); }

// no_lint — reaching this line proves mounted
await f();
if (!mounted || other) return;
setState(() {});   // still REPORTED as of 1.1.0 (see note below)

// lint — a conjunction does not prove it
await f();
if (!mounted && other) return;
setState(() {});
```

Environment: Dart 3.13.1, Flutter 3.47.1, many_lints 1.1.0.

## Update 2026-08-26 — the disjunction case is still reported

The `if (!mounted || other) return;` shape above is listed as `no_lint`, but
1.1.0 still reports the `setState` that follows it:

```dart
Future<void> _delete() async {
  await allowNextPop();
  final succeeded = await widget.onDelete!();
  if (!mounted || succeeded) return;
  blockPop();
  setState(() => _deleteFailed = true);   // LINT (false positive)
}
```

Reaching the line proves `mounted`: the early return fires whenever `mounted`
is false, whatever `succeeded` is. Worth a regression test alongside the
wrapper case, since the two are likely the same missing analysis.

Real call site: `test/core/presentation/unsaved_changes_guard_test.dart:51`.

## Resolved 2026-08-26

Both shapes are handled, in `lib/src/async_guard_utils.dart`:

- `isMountedGuardWithReturn` now reads the condition structurally instead of
  insisting on a bare `!mounted`. A **disjunction** counts —
  `if (!mounted || succeeded) return;` returns whenever `mounted` is false,
  whatever the other operand says. A conjunction still does not.
- `isPositiveMountedGuard` is new, recognising the wrapper form
  `if (mounted) …`. A **conjunction** counts there (`mounted && ready` cannot
  be entered while unmounted); a disjunction does not. The mirror image of the
  early-return rule, which is what the two forms are.

`use_setstate_synchronously` consumes the wrapper guard and deliberately keeps
reporting the three overshoot cases: the `else` branch is reported directly,
and a non-block branch that awaits re-opens the gap. A block branch needs no
special handling — `visitBlock` already re-scans it from a clean slate, so an
await inside it puts the later `setState` after a fresh gap on its own.

Parenthesised conditions are unwrapped, so `if (!(mounted)) return;` reads the
same as the bare form.

The two sibling rules sharing the helper (`use_ref_read_synchronously`,
`use_ref_and_state_synchronously`) get the widened early-return guard for free;
their suites still pass unchanged.

Tests: four `no_lint` cases (wrapper, block wrapper, conjunction, disjunction
early return) and four that must keep reporting (await inside the guard, else
branch, positive disjunction, negative conjunction).

Verified in the reporting app: all three `ignore` comments removed, analyzer
clean.
