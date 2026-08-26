# `banned_usage` cannot ban a top-level function

**Reported:** 2026-08-26 (found trying to enforce a project's own `Future` extension)
**Status:** OPEN
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
