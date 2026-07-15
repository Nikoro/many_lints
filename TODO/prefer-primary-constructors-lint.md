---
title: "Add prefer_primary_constructors lint once the feature ships stable"
type: feature
effort: L
status: open
scope: "root"
created: 2026-07-15
branch: "main"
commit: "cefda5f"
---

# Add prefer_primary_constructors lint once the feature ships stable

## What

Add a `prefer_primary_constructors` lint (with quick fix) that detects classes whose field declarations + boilerplate constructor can be collapsed into a Dart primary constructor (`class Point(final int x, final int y);`).

## Why

Primary constructors are the biggest boilerplate reduction in recent Dart history and will be widely adopted the moment they ship stable — the same dynamic as dot shorthands, which this package covers with four `prefer_shorthands_*` rules. Being early with a migration lint is high-value for users.

**Blocked**: primary constructors are **experimental** in Dart 3.12 (behind a flag). Do not implement until the feature ships in a stable SDK — an experimental-only lint would suggest non-compiling code for everyone else.

## Context Snapshot

While bumping the package to analyzer 13/14 (releases 0.5.0 and 0.6.0) we reviewed what's new in Dart 3.11/3.12 and Flutter 3.41/3.44 for lint opportunities. Dart 3.12 shipped private named parameters stable (covered by the new `prefer_private_named_parameters` rule) and primary constructors as experimental. This TODO tracks the follow-up for when primary constructors stabilize.

## Codebase Anchors

- `lib/src/rules/prefer_private_named_parameters.dart` — feature-gate pattern to copy: `unit.featureSet.isEnabled(Feature.private_named_parameters)`; a `Feature.primary_constructors` (name TBD) gate must guard the new rule the same way
- `lib/src/rules/prefer_returning_shorthands.dart` — closest analogy for a "modern syntax migration" rule family
- `lib/many_lints.dart` — registration point for rule + fix

## Plan

1. Watch the [analyzer CHANGELOG](https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/CHANGELOG.md) / Dart release notes for primary constructors going stable (candidate: Dart 3.13+).
2. Study the final AST shape for primary constructors in the shipped analyzer (new node types around `NameWithTypeParameters` / class headers; the analyzer already has partial support — see `namePart` APIs).
3. Rule: visit `ClassDeclaration`; detect a class whose only constructor is a plain field-assigning constructor (each formal is an initializing formal or matches the private-named-parameter shape) and whose fields have no initializers — then suggest the primary-constructor form. Gate on the language feature flag.
4. Fix: rewrite the class header to `class Name(<params>)`, remove the fields + constructor; preserve metadata, `const`, named constructors, and doc comments — likely the hardest part, consider limiting v1 of the fix to simple classes.
5. Tests + docs page (`shorthand-patterns` or a new category) + example file, following `prefer_private_named_parameters` as the template.

## Open Questions

- Exact stable release and `Feature` enum name for the gate.
- Should the rule also fire for classes with a `const` constructor (`const class Point(...)` syntax?) — depends on the final spec.
- Fix scope for v1: full rewrite vs. report-only until the AST stabilizes.
