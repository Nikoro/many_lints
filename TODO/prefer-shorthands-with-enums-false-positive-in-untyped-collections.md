---
title: "Fix prefer_shorthands_with_enums false positive inside collections with no downward context"
type: bug
effort: M
status: open
scope: "lib/src/type_inference.dart"
created: 2026-08-05
branch: "main"
commit: "6eabd79"
---

# Fix prefer_shorthands_with_enums false positive inside collections with no downward context

## What

`prefer_shorthands_with_enums` fires on an enum reference inside a list literal that is passed to a `dynamic` parameter. Applying the suggested fix produces code that does not compile:

```dart
// Reported by the rule:
expect(rankings, equals([LeaderboardType.ligex]));

// After applying the suggestion — COMPILE ERROR:
expect(rankings, equals([.ligex]));
// error: A dot shorthand can't be used where there is no context type.
//        (dot_shorthand_missing_context)
```

`equals()` is `Matcher equals(Object? expected)`, so the list literal has no downward context type.

## Why

The rule already guards on `inferContextType(node) != null`, so the bug is one level down in `resolveCollectionElementType`.

`lib/src/type_inference.dart:69-83` resolves a collection's element type from the literal's **`staticType`**. For a list literal with no downward context, the analyzer infers that type **upward from the elements themselves**: `[LeaderboardType.ligex]` gets `staticType == List<LeaderboardType>`, so `typeArguments.first` is exactly the enum the rule is looking at. `isTypeCompatible` then trivially succeeds and the rule reports.

In other words the check is circular: the "context type" is derived from the very expression whose context we are trying to establish. Upward inference is not a context type, and dot shorthands require a genuine downward one.

This affects any collection literal in a `dynamic`/`Object?` position — `equals([...])`, `containsAll([...])`, `jsonEncode([...])`, `print([...])` — and plausibly the sibling rules that share the same helper (`prefer_shorthands_with_constructors`, `prefer_shorthands_with_static_fields`, `prefer_returning_shorthands`), since `inferContextType` is common to all of them.

## Context Snapshot

Found while updating dependencies in the Ligex project (`~/Projects/ligex`), which consumes `many_lints ^0.7.1` as a workspace-root analyzer plugin. Bumping from 0.4.x to 0.7.1 surfaced this on a previously clean codebase; the finding had to be silenced with `// ignore: many_lints/prefer_shorthands_with_enums` because there is no way to write the suggested code.

Real-world reproduction, `frontend/test/user/infrastructure/standings_repository_test.dart:64`:

```dart
expect([for (final standing in stored) standing.ranking], equals([LeaderboardType.ligex]));
```

## Codebase Anchors

- `lib/src/type_inference.dart:69-83` — `resolveCollectionElementType`, the actual defect: trusts `ListLiteral.staticType` / `SetOrMapLiteral.staticType`
- `lib/src/type_inference.dart:42-43` — the `ListLiteral() || SetOrMapLiteral()` branch of `inferContextType` that routes here
- `lib/src/rules/prefer_shorthands_with_enums.dart:99-103` — the caller; its `contextType == null` guard is correct and needs no change
- `lib/src/rules/prefer_shorthands_with_constructors.dart`, `prefer_shorthands_with_static_fields.dart`, `prefer_returning_shorthands.dart` — same helper, check whether they are affected

## Plan

1. Write the failing test first: an enum inside a list literal passed to a `dynamic` parameter must **not** be reported. Cover `equals([E.a])`, a bare `dynamic` parameter, and `Object?`.
2. Add the positive controls that must keep reporting: `final List<E> x = [E.a];`, `List<E> fn() => [E.a];`, a typed named argument `items: [E.a]`, and a nested `[[E.a]]` under a typed context.
3. Fix `resolveCollectionElementType` so it distinguishes downward context from upward inference. Options, cheapest first:
   - Resolve the collection's own context by recursing (`inferContextType(collectionNode)`) and derive the element type from *that*, returning `null` when the collection itself has no context.
   - If the analyzer exposes it, prefer an explicit downward-context API over `staticType` (check for a `correspondingParameter`/context-type accessor on the literal in analyzer 14).
   - Treat an explicit type argument (`<E>[E.a]`) as a genuine context, since it is written by the user.
4. Re-run the sibling shorthand rules' tests; if they regress, the fix belongs behind a shared helper rather than in each rule.
5. Verify end-to-end against the Ligex repro, then drop the `// ignore:` comment there.

## Open Questions

- Does analyzer 14 expose a real downward-context accessor for collection literals, or must this be reconstructed by walking parents?
- Should an explicit type argument (`<E>[E.a]`) count as context? It compiles, so probably yes.
- Are map literals affected the same way? `resolveCollectionElementType` returns `typeArgs.first`, which for `Map<K,V>` is the **key** type — that looks like a separate latent bug worth its own test.
