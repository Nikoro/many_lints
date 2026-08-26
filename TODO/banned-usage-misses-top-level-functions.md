# `banned_usage` cannot ban a top-level function

**Reported:** 2026-08-26 (found trying to enforce a project's own `Future` extension)
**Status:** CLOSED — not reproducible (see 2026-08-26); one real follow-up split out below
**Affects:** `lib/src/rules/banned_usage.dart`

## What happens

`banned_usage` matches members of a type (`DateTime.now`, `Iterable.first`).
A top-level function is silently unmatchable, whether written qualified or bare:

```yaml
banned_usage:
  banned:
    - deny: ['unawaited']          # no effect
      message: 'Use future.unawaited() instead.'
```

```dart
import 'dart:async';

void run() {
  unawaited(work());   // not reported
}
```

Verified against a real project: the config parses, the rule runs, nothing is
reported.

## Why

`_qualifiedNamesOf` gives up as soon as the element has no enclosing interface:

```dart
List<String> _qualifiedNamesOf(Element element, String memberName) {
  final enclosing = element.enclosingElement;
  if (enclosing is! InterfaceElement) return const [];
  …
}
```

A top-level function's enclosing element is the library, not an
`InterfaceElement`, so the candidate-name list comes back empty and the entry
can never match. The doc comment's "a bare `member` name bans it on any type"
is true for *members*, which is easy to read as covering plain functions too.

## Why it matters

The `avoid_banned_*` family exists to enforce a project's own vocabulary, and
"prefer our helper over the SDK's free function" is a normal thing to want:

- `unawaited(f())` → a project's own trailing `f().unawaited()`
- `print(…)` → the project's logger
- `debugPrint`, `jsonDecode`, `compute` → a wrapped seam that can be faked

None of these are reachable today. `avoid_banned_imports` is not a substitute:
banning `dart:async` also bans `Timer`, `Completer` and `StreamSubscription`,
which are usually fine.

## Suggested fix

Extend `_qualifiedNamesOf` (and `_displayNameOf`) to handle a library-level
element by emitting the bare name, so a `deny: ['unawaited']` entry matches a
top-level function as well as a member.

Worth deciding explicitly: whether a library-qualified form should also be
accepted, e.g. `dart:async/unawaited` or `async.unawaited`, so a project can
ban the SDK's function without also banning its own same-named helper. That
distinction matters for exactly the case that prompted this — an extension
method named `unawaited` should keep working while the free function is
refused.

## Suggested tests

```dart
// lint — top-level function, bare name
import 'dart:async';
void f() => unawaited(g());

// no_lint — an extension member of the same name is a different declaration
void f() => g().unawaited();

// no_lint — not configured
void f() => scheduleMicrotask(g);
```

Environment: Dart 3.13.1, Flutter 3.47.1, many_lints 1.1.0.

## Not reproducible 2026-08-26 — the rule already bans top-level functions

Retested at HEAD, three ways. All three report:

1. **A top-level function declared in the analyzed file** — reports.
2. **An imported one** (`import 'dart:async'; unawaited(g());`), which is the
   exact snippet above — reports.
3. **The real project that prompted this.** Adding

   ```yaml
   banned_usage:
     banned:
       - deny: ['unawaited']
         message: 'PROBE.'
   ```

   to that app's `analysis_options.yaml` and analyzing a single real file gives
   **14 `banned_usage` findings** on its `unawaited(...)` call sites.

So "the config parses, the rule runs, nothing is reported" does not hold.

### Why the reasoning in the report looked sound but was not

`_qualifiedNamesOf` really does bail out for a library-level element — that part
is accurate. But it is not the only lookup. `_check` tries the qualified names
*and then falls back to the bare name*:

```dart
final banned =
    _find(entries, _qualifiedNamesOf(element, memberName)) ??
    _find(entries, [memberName]);
```

A `deny: ['unawaited']` entry is a bare name, so it matches through the second
call regardless of what the first returns. Reading only `_qualifiedNamesOf`
makes the empty list look fatal; it is just the qualified path declining, as it
should for something that has no enclosing type.

### What was probably really going on

Almost certainly the cache bug in
[`plugin-silently-skipped-on-large-projects.md`](plugin-silently-skipped-on-large-projects.md):
this was verified with a whole-project `dart analyze`, which serves cached
results with plugin diagnostics stripped on every run after the first. A rule
that works reports nothing, which is exactly the symptom described here. Verify
with explicit file arguments before concluding a rule is silent.

### The one real gap left

The open design question at the end of the original report still stands and is
untouched by this: there is **no way to distinguish** `dart:async`'s
`unawaited` from a project's own same-named declaration, because only the bare
name is ever matched. If `many_extensions` gains a trailing `.unawaited()`, a
`deny: ['unawaited']` entry would refuse both the SDK function and the
extension member.

That is worth a separate, accurately-scoped TODO: **a library-qualified deny
form** (`dart:async/unawaited`), applying to the whole `banned_*` family rather
than to top-level functions specifically. Nothing to fix in `_qualifiedNamesOf`.

**Status: closing this as not-a-bug.**

## Correction 2026-08-26 — `many_extensions` *does* ship `.unawaited()`

The paragraph above says the trailing form was hypothetical. That was wrong,
and the mistake was mine: I searched `~/Projects/many_extensions/lib/`, which
holds only a four-line barrel, and concluded the extension did not exist. It
lives in a sub-package —
`dart_extensions/future_extensions/lib/future_extensions.dart` — and is
re-exported through the barrel, so it is importable today.

That makes the collision real rather than theoretical, and it is worth stating
precisely because it is the one defect this file's investigation did turn up:

```dart
extension FutureManyExtensions<T> on Future<T> {
  void unawaited() => async.unawaited(this);
}
```

With `deny: ['unawaited']` configured, `banned_usage` reports **both**
`unawaited(g())` *and* `g().unawaited()` — it flags the very call the ban
exists to steer people toward. Confirmed by test.

The cause is narrower than "top-level functions are unmatchable". An
`ExtensionElement` is an `InstanceElement` but **not** an `InterfaceElement`,
so `_qualifiedNamesOf` declines for an extension member exactly as it does for
a top-level function, leaving only the bare-name lookup — and by bare name the
two are indistinguishable.

Two things would fix it, and they are independent:

1. **Qualified spellings for extension members**, so `FutureManyExtensions.unawaited`
   or `Future.unawaited` can be denied precisely. Straightforward: read
   `ExtensionElement.extendedType` alongside the extension's own name.
2. **A library-qualified deny form** (`dart:async/unawaited`), so the SDK
   function can be banned without touching a same-named project declaration.
   This is the more general fix and applies to the whole `banned_*` family.

Neither is implemented. Both are worth their own TODO rather than being
smuggled into this one, whose headline claim is still false.

**In practice this specific need is now served by `match_pattern`**, which
matches `^unawaited\((.+)\)$` — a call shape, so the trailing form cannot match
it — and rewrites it. See
[user-defined-pattern-rule-with-fix.md](user-defined-pattern-rule-with-fix.md).
