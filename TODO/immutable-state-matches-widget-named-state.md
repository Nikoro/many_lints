# `prefer_immutable_state` fires on a `StatelessWidget` named `...State`

**Reported:** 2026-08-26 (found adopting the plugin in a Flutter app)
**Status:** RESOLVED
**Affects:** `lib/src/rules/prefer_immutable_state.dart`
**Follow-up to:** `prefer-immutable-bloc-state-misnamed.md` (RESOLVED in v0.10.0)

## What happens

The rename to `prefer_immutable_state` fixed the misleading "Bloc" wording, but
the name-based strategy — `RegExp(r'State$')` with no type check — is still
doing the matching. It now reports Flutter widgets whose names happen to end in
`State`:

```dart
class PersonPickerEmptyState extends StatelessWidget {   // LINT (false positive)
  const PersonPickerEmptyState({required this.scrollController, super.key});
  final ScrollController scrollController;
  ...
}
```

`StatelessWidget` is already annotated `@immutable` upstream, so the
annotation the rule asks for is redundant — the class inherits it. The name
describes what the widget *renders* (an empty state), not a state object.

## Expected

Skip any class that already inherits `@immutable`, which covers every
`StatelessWidget` and `Widget` subclass, before falling back to the name
pattern. That single check removes this whole category without weakening the
rule for real notifier state.

A narrower alternative: exclude subtypes of `Widget` from the name-based
strategy specifically, leaving the type-based strategy untouched.

## Real call site

- `lib/upcoming_events/presentation/widgets/person_picker_empty_state.dart:5`

Widget names ending in `State` are idiomatic Flutter — `EmptyState`,
`ErrorState`, `LoadingState` are common component names — so this is likely to
recur in most Flutter codebases.

## Suggested test cases

```dart
// no_lint — inherits @immutable from StatelessWidget
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// lint — a mutable notifier state class
class CounterState {
  int count = 0;
}
```

Environment: Dart 3.13.1, Flutter 3.47.1, many_lints 1.1.0.

## Resolved 2026-08-26

`_inheritsImmutable()` in `lib/src/immutable_state_rule.dart` now skips any
class whose supertypes carry `@immutable`, checked before the name pattern.
That covers every `StatelessWidget` (Flutter annotates `Widget`) and any
project base class annotated the same way, without touching the type-based
strategy.

Only *supertypes* are consulted. An annotation on the class itself still falls
through to the existing report path, so the subclass widening below it keeps
seeing the class.

One gotcha, worth knowing before writing any test that asserts on `@immutable`:
`Metadata.hasImmutable` resolves semantically through `package:meta` — it wants
a library *named* `meta` exporting a getter `immutable` or a class `Immutable`.
The fake `meta` these tests had (`class immutable` lowercase, no library name)
satisfied the rule's own syntactic check but was invisible to `hasImmutable`,
so the fix looked broken until the fake was made faithful.

Tests: `test_widgetNamedStateInheritsImmutable`,
`test_classInheritingImmutableFromItsOwnBase`,
`test_mutableStateClassStillReported`.

Verified in the reporting app: the `ignore` on
`lib/upcoming_events/presentation/widgets/person_picker_empty_state.dart` was
removed and `dart analyze --fatal-infos` stays clean.
