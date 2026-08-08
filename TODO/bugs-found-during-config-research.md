# Bugs found during configurable-rules research

**Date:** 2026-08-08
**Source:** incidental findings while auditing hardcoded values for
[configurable-rules-research.md](configurable-rules-research.md)
**Status:** all four verified by reading source; none fixed yet

These are **unrelated to the config work** and should be fixed independently. Ordered by severity.

---

## 1. `prefer_container` suggests parameters that do not exist on `Container`

**Severity: HIGH — the rule proposes code that will not compile.**

`lib/src/rules/prefer_container.dart:68-70`

```dart
'IntrinsicHeight' => 'intrinsicHeight',
'IntrinsicWidth' => 'intrinsicWidth',
'LimitedBox' => 'limitedBox',
```

`Container` has no `intrinsicHeight`, `intrinsicWidth`, or `limitedBox` parameter. A user
following the diagnostic gets a compile error.

Compare the correct entries around them (`padding`, `alignment`, `color`, `decoration`,
`constraints`, `transform`) — those are all real `Container` params.

Note that `Opacity => 'opacity'` at `:67` is already flagged in a comment as "no direct Container
param, but still valid", so there is precedent for the mapping being about *collapsibility* rather
than a literal parameter name. Decide which semantics the map actually has:

- **If the map means "real Container parameter"** → remove all three widgets from
  `_containerParamForWidget` **and** from `_containerCompatibleWidgets` (`:90-92`), since
  `Container` genuinely cannot express them.
- **If the map means "collapsible into Container"** → the three entries need a different message,
  and `Opacity` needs the same treatment.

Recommend the first: `IntrinsicHeight`/`IntrinsicWidth`/`LimitedBox` have no `Container`
equivalent at all, so suggesting a merge is wrong regardless of wording.

**Test to add:** a widget chain containing `IntrinsicHeight` must not be reported (or must be
reported with a message that does not name a nonexistent parameter).

---

## 2. `avoid_commented_out_code` misclassifies prose starting with "override"

**Severity: MEDIUM — false positives on ordinary English comments.**

`lib/src/rules/avoid_commented_out_code.dart:350`

```dart
'static ',
'override',      // ← no '@', no trailing space
'Widget ',
```

Every other entry in this keyword list either ends with a space (`'import '`, `'static '`,
`'throw '`) or with punctuation that anchors it (`'if ('`, `'State<'`). `'override'` has neither,
and the check is `line.startsWith(keyword)` (`:357`).

Consequences:
- A comment like `// override this in subclasses to customize behaviour` is flagged as
  commented-out code.
- The actual Dart annotation is `@override`, which this entry does **not** match — so the entry
  fails at its apparent purpose while causing false positives.

**Fix:** change to `'@override'`.

**Test to add:** `// override this method in subclasses` must not be reported; a genuinely
commented-out `// @override` line should be.

---

## 3. `avoid_unnecessary_consumer_widgets` silently skips `HookConsumerWidget`

**Severity: MEDIUM — rule silently under-reports.**

`lib/src/rules/avoid_unnecessary_consumer_widgets.dart:44-56`

```dart
static const _consumerWidgetChecker = TypeChecker.fromName(
  'ConsumerWidget', packageName: 'flutter_riverpod',
);
static const _consumerStatefulWidgetChecker = TypeChecker.fromName(
  'ConsumerStatefulWidget', packageName: 'flutter_riverpod',
);
static const _consumerStateChecker = TypeChecker.any([
  TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),  // ← Hook variant present
]);
```

The `_consumerStateChecker` includes the `hooks_riverpod` variant, but
`_consumerWidgetChecker` does **not** include `HookConsumerWidget`. That asymmetry within the same
class strongly suggests an oversight rather than a deliberate exclusion.

A `HookConsumerWidget` that never uses `ref` is exactly as unnecessary as a `ConsumerWidget` that
never uses `ref`, and users of `hooks_riverpod` get no diagnostic.

**Fix:** wrap `_consumerWidgetChecker` in `TypeChecker.any([...])` adding
`TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod')`.

⚠️ **Care needed:** `avoid_unnecessary_hook_widgets` is an adjacent rule. Check the two do not
double-report on a `HookConsumerWidget` that uses neither hooks nor `ref`. Add a test covering
that overlap.

---

## 4. `isStableReference` is dead code

**Severity: LOW — no behavioural impact, but misleading.**

`lib/src/async_builder_utils.dart:73-77`

```dart
bool isStableReference(Element? element) => switch (element) { ... };
```

A grep across `lib/` and `test/` returns exactly this declaration and zero call sites. Neither
`pass_existing_future_to_future_builder` nor `pass_existing_stream_to_stream_builder` uses it —
both go through `createsNewAsyncSource()` instead.

**Decide:** either it encodes an intended refinement that was never wired up (in which case
document the gap), or it is leftover from an earlier approach and should be deleted. Deleting is
the default; the file's own docstring describes `createsNewAsyncSource` as the entry point.

---

## Suggested order

1. **#1** first — it is the only one that makes the tool actively produce broken code.
2. **#2** — cheap one-character-class fix with a clear test.
3. **#3** — needs the overlap check with `avoid_unnecessary_hook_widgets`.
4. **#4** — housekeeping, bundle with any future touch of `async_builder_utils.dart`.

Each fix needs a regression test; #1 and #2 are both currently untested in the direction that
would have caught them.
