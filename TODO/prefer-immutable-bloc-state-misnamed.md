# `prefer_immutable_bloc_state` fires on projects that have no Bloc

**Reported:** 2026-08-14 (found while adopting the plugin in a Riverpod-only app)
**Status:** RESOLVED in v0.10.0 — option 2 implemented
**Affects:** `lib/src/rules/prefer_immutable_bloc_state.dart`

## What happens

The rule reports "Bloc state classes should be annotated with @immutable" in a
codebase that does not depend on `bloc` at all. In one Riverpod app it flagged 27
classes, none of them a Bloc state.

## Why

`_Visitor.visitCompilationUnit` collects state classes through two strategies, and
only the first one involves Bloc:

1. **Type-based** — a class used as the state type argument of `Bloc<E, S>` or
   `Cubit<S>`, via `blocChecker` / `cubitChecker`. Correct, and inert without the
   package.
2. **Name-based** — `RegExp(r'State$')` against the class name, with no type check
   whatsoever, then a BFS that pulls in every subclass and implementor.

With no `bloc` dependency, strategy 1 never matches and strategy 2 does all the
work. So the rule degenerates into "every class whose name ends in `State` must be
`@immutable`" — which catches Riverpod notifier state, and any unrelated
`...State` class, under a diagnostic message naming a package the project does
not use.

The `name_pattern` option tunes strategy 2 but cannot switch it off, and the
message is hardcoded to say "Bloc".

## Why it matters beyond the wrong name

The advice itself is reasonable for Riverpod state, so a user who reads past the
name may well want the rule. The problem is discoverability in both directions: a
Riverpod user does not look for a rule called `..._bloc_state`, and a user who
finds it cannot tell whether it is reporting real Bloc state or a name match.

It also lands in the `opinionated` preset, so a project that selects that tier
gets Bloc diagnostics without opting into anything Bloc-shaped.

## Resolution

**Option 2 was implemented.** `prefer_immutable_bloc_state` is now type-based
only; the name-based strategy and its `name_pattern` option moved to a new
`prefer_immutable_state`. Both share `lib/src/immutable_state_rule.dart`, so
the two cannot drift, and both register the (renamed) `AddImmutableAnnotationFix`.

Two things the split turned up that were not in the analysis below:

1. **Flutter `State<T>` subclasses had to be excluded by type.** Every one of
   them is named `...State` and every one is *meant* to be mutable, so the
   name-based rule reported every `StatefulWidget` in the codebase — 27 hits in
   ligex, of which 19 were `_FooPageState`. The exclusion goes through the
   shared `isStateElement`, so `state_base_classes` tunes it.
2. **A latent Cubit bug.** `Cubit` is itself a `Bloc`, and the Bloc branch was
   tested first, so a `Cubit<State>` matched as a Bloc and was then searched for
   a second type argument it does not have. Cubit state was only ever reported
   through the name heuristic; removing that made the gap visible.

Verified on ligex: the Bloc rule now reports **0**, and the name-based rule
reports **8**, all genuine Riverpod notifier state in `application/`. The
downstream `include:` workaround below has been deleted from ligex.

## Options considered

1. **Gate strategy 2 behind an actual Bloc dependency.** Closest to what the name
   promises. Silently drops the rule for anyone relying on the name heuristic today.
2. **Split into two rules** — keep `prefer_immutable_bloc_state` type-based only,
   and add a state-management-agnostic `prefer_immutable_state` that owns the
   name-based strategy and `name_pattern`. Honest naming; costs a rename and a
   tombstone.
3. **Keep the behaviour, fix the wording.** Make the message reflect why the class
   was selected ("class matching `State$`" vs. "Bloc state"), and document that
   strategy 2 is state-management-agnostic.

Option 2 looks right — the name-based half is genuinely useful outside Bloc, and it
is the half that misleads while it stays under a Bloc name.

## Reproducing

Any package with no `bloc` dependency:

```dart
// no bloc anywhere in the project
class LoginEmailState {   // reported: "Bloc state classes should be annotated..."
  const LoginEmailState({required this.email});
  final String email;
}
```

## Downstream workaround

Scoped rather than disabled, so the rule still covers real notifier state:

```yaml
many_lints:
  rules:
    prefer_immutable_bloc_state:
      include:
        - lib/**/application/**
```
