---
title: "Fix use_existing_variable reporting expressions whose re-evaluation is the point"
type: bug
effort: M
status: open
scope: "lib/src/rules/use_existing_variable.dart"
created: 2026-08-05
branch: "main"
commit: "6eabd79"
---

# Fix use_existing_variable reporting expressions whose re-evaluation is the point

## What

`use_existing_variable` compares expressions by their **source text** alone. When an identical expression is deliberately evaluated a second time — because the first result was consumed, closed, or invalidated — the rule tells the user to reuse a variable that is no longer valid. Following the advice changes behaviour, and in the case below it inverts what the test proves:

```dart
final old = Database.forTesting(DatabaseConnection(NativeDatabase(file)));
await old.into(old.leaguesTable).insert(_league);
await old.customStatement('PRAGMA user_version = ${database.schemaVersion - 1}');
await old.close();                       // <- `old` is now a closed connection

// LINT: "The expression duplicates the initializer of 'old'. Use 'old' instead."
final upgraded = Database.forTesting(DatabaseConnection(NativeDatabase(file)));
```

Reopening the database is the entire subject of the test — it asserts that a schema bump drops the caches. Reusing `old` would test nothing and operate on a closed connection.

## Why

`_Visitor.visitBlock` (`lib/src/rules/use_existing_variable.dart:47-90`) records `initializer.toSource()` for every `final`/`const` declaration, then reports any later expression with a matching source string. Two things are missing:

1. **No side-effect analysis.** A constructor call, a factory, or any method invocation may allocate a fresh resource; re-evaluating it is not equivalent to reusing the previous result. Only genuinely pure expressions can be safely deduplicated.
2. **No liveness analysis.** Even for a pure expression, the rule does not ask whether the existing variable is still usable at the second site. Here `old.close()` makes it unusable, and the rule cannot see that.

Source-text equality is a fine cheap *prefilter*, but it cannot be the whole test. As written, the rule is most likely to fire exactly where the duplication is intentional: acquire → release → re-acquire, which is a standard shape in resource and database tests.

Per `CLAUDE.md`, "never justify a rule change by claiming a false positive cannot be silenced" — it can, and was. The justification here is different: the pattern is legitimate, common in test code, and the suggested rewrite is semantically wrong rather than merely noisy.

## Context Snapshot

Found while updating dependencies in the Ligex project (`~/Projects/ligex`), which consumes `many_lints ^0.7.1` as a workspace-root analyzer plugin. Bumping from 0.4.x to 0.7.1 surfaced this on a previously clean codebase; it had to be silenced with `// ignore: many_lints/use_existing_variable` at `frontend/test/core/database/database_test.dart:38`.

Ligex runs `dart analyze --fatal-infos` as a hard-fail pre-commit gate, so a false positive is a hard block rather than background noise.

## Codebase Anchors

- `lib/src/rules/use_existing_variable.dart:47-90` — `visitBlock`: collects declarations and reports duplicates in one pass
- `lib/src/rules/use_existing_variable.dart` — `_DuplicateExpressionFinder`, matches on `initializerSource` string equality
- `lib/src/rules/use_existing_variable.dart` — `_isTrivialExpression`, the existing (and currently only) exclusion filter
- `lib/src/constant_expression.dart` — `isConstantExpression` / `isConstantIdentifier`, the natural basis for a purity check
- `test/use_existing_variable_test.dart` — where the regression tests go

## Plan

1. Write the failing tests first, from the repro above:
   - constructor call re-evaluated after the first variable was passed to a `close()`/`dispose()`-style call → must not report;
   - constructor call re-evaluated with no intervening use → decide via Open Questions, but pin the behaviour with a test either way.
2. Add a purity gate before reporting. Report only when the duplicated expression is free of side effects — constant expressions, pure getters and simple property access chains. Exclude `InstanceCreationExpression` and `MethodInvocation` by default; `lib/src/constant_expression.dart` already has the primitives.
3. Add a liveness gate: suppress the report when, between the declaration and the duplicate, the variable is passed to a disposal-shaped method. `lib/src/disposal_utils.dart` already knows `cleanupMethods` — reuse it rather than duplicating the list.
4. Re-run the full suite; the purity gate will likely narrow existing positive cases, so confirm each remaining one is genuinely pure and update the docs page with the narrowed scope.
5. Verify against the Ligex repro, then drop the `// ignore:` comment there.

## Open Questions

- How far should the purity gate go? Strict (constants and simple property access only) is safe and probably still catches the intended target — a repeated `context.theme.textTheme` style chain — but it does shrink the rule considerably.
- Should an intervening *any* method call on the variable suppress the report, or only known disposal names? Known names risk missing custom teardown; any call risks gutting the rule.
- Is the reverse case worth a separate diagnostic — a truly pure expression repeated many times in one block — where the current rule genuinely adds value?
- Does the rule handle a variable reassigned between the two sites (non-`final` shadowing in a nested block)? Not covered by the current tests.
