---
title: "Port the riverpod_lint rules into many_lints so both plugins are not needed"
type: feature
effort: XL
status: open
scope: "lib/src/rules, lib/src/assists"
created: 2026-08-05
branch: "main"
commit: "6eabd79"
---

# Port the riverpod_lint rules into many_lints so both plugins are not needed

## What

Reimplement `riverpod_lint`'s diagnostics and assists as native `many_lints` rules, so a Riverpod project gets full coverage from this package alone.

## Why

**The two plugins cannot currently coexist.** Every analyzer plugin declared under `plugins:` resolves into a single shared isolate, so all of them must agree on one `analyzer` version:

| plugin | analyzer constraint |
|--------|---------------------|
| `many_lints` >= 0.6.0 | `^14.1.0` |
| `riverpod_lint` 3.1.8 | `^13.0.0` |

Enabling both fails at plugin setup, not at analysis time:

```
Because riverpod_lint >=3.1.6 depends on analyzer ^13.0.0 and many_lints >=0.6.0
depends on analyzer ^14.1.0, riverpod_lint >=3.1.6 is incompatible with
many_lints >=0.6.0.
```

The only overlap is `many_lints 0.5.0` (`analyzer ^13.3.0`), i.e. giving up 0.6.0/0.7.x. Users must pick one plugin or freeze this one — and since `riverpod_lint` tracks the analyzer more slowly, this recurs at every analyzer major.

Two things make the port the right response rather than a workaround:

1. **`riverpod_lint` 3.1.0+ already left `custom_lint` for `analysis_server_plugin`** — the same framework this package uses. Its rules are no longer written against a foreign plugin API, so they are readable as a direct reference.
2. **This package is already drifting into Riverpod territory.** It ships `avoid_public_notifier_properties`, `avoid_ref_inside_state_dispose`, `avoid_unnecessary_consumer_widgets`, `avoid_ref_read_inside_build`, `avoid_notifier_constructors`, `use_notifier_suffix`, `use_ref_read_synchronously`, `use_ref_and_state_synchronously` and `dispose_provided_instances`. Release 0.7.1 was largely Riverpod-rule fixes. Finishing the coverage consolidates a split that already exists.

## Context Snapshot

Surfaced while updating dependencies in the Ligex project (`~/Projects/ligex`), a Riverpod 3 app that uses `many_lints` at the workspace root. The intent was to add `riverpod_lint` alongside it; the resolution conflict above made that impossible, and `many_lints ^0.7.1` was kept. The stale comment in Ligex's `frontend/analysis_options.yaml` (claiming a `custom_lint` conflict and an analyzer ^12 cap) was corrected to point at this port.

Environment: Dart 3.12.2, Flutter 3.44.8, analyzer 14.1.0 latest, riverpod 3.4.2.

## Rule Inventory

Already covered by `many_lints` — verify parity, do not duplicate:

- `avoid_public_notifier_properties`
- `avoid_ref_inside_state_dispose`

To port (13 diagnostics):

| riverpod_lint rule | Notes |
|---|---|
| `missing_provider_scope` | Flutter-only; app root without `ProviderScope` |
| `notifier_extends` | Notifier must extend the generated base |
| `notifier_build` | `build` must be present/correctly shaped |
| `functional_ref` | Functional provider's first parameter must be the right `Ref` |
| `provider_parameters` | Provider parameter shape/equality |
| `provider_dependencies` | `dependencies:` completeness — the hardest; needs whole-graph analysis |
| `scoped_providers_should_specify_dependencies` | Pairs with the above |
| `only_use_keep_alive_inside_keep_alive` | keepAlive propagation |
| `unsupported_provider_value` | Rejects unsupported provider return types |
| `protected_notifier_properties` | `state` etc. accessed from outside the notifier |
| `avoid_build_context_in_providers` | No `BuildContext` in provider bodies |
| `async_value_nullable_pattern` | Null-check pattern vs. `hasData`; fix code `remove_null_check_pattern_and_add_has_data_check` |
| `riverpod_syntax_error` | Reports malformed Riverpod declarations |

Assists to port (5): `class_based_to_functional_provider`, `functional_to_class_based_provider`, `convert_to_stateless_base_widget`, `convert_to_stateful_base_widget`, `wrap_with_consumer`, `wrap_with_provider_scope`.

## Codebase Anchors

- `lib/src/riverpod_type_checkers.dart` — existing shared Riverpod `TypeChecker` constants; the port will grow this substantially (Ref, ProviderScope, AsyncValue, WidgetRef)
- `lib/src/rules/avoid_public_notifier_properties.dart` — closest existing analogue to copy for notifier-shaped rules
- `lib/src/rules/avoid_unnecessary_consumer_widgets.dart` — recently taught to correlate a `ConsumerStatefulWidget` with its `ConsumerState` (0.7.1); the same correlation is needed by several ported rules
- `lib/src/assists/AGENTS.md` — assist patterns, for the six assists
- `lib/many_lints.dart` — registration point
- Reference source: `~/.pub-cache/hosted/pub.dev/riverpod_lint-3.1.8/lib/src/lints/` and `.../assists/`
- `riverpod_analyzer_utils` (1.0.0-dev.11) — riverpod_lint's semantic layer; the key build-vs-buy decision below

## Plan

1. **Decide the dependency question first** (see Open Questions) — whether to depend on `riverpod_analyzer_utils` or hand-roll the detection. Everything else follows from this; do not start rules until it is settled.
2. Port in waves, each wave = rule + fix (where riverpod_lint has one) + test + docs page + example file, per the standard checklist in `CLAUDE.md`:
   - **Wave 1, self-contained AST checks:** `avoid_build_context_in_providers`, `protected_notifier_properties`, `notifier_extends`, `notifier_build`, `functional_ref`. These need little more than the type checkers already present.
   - **Wave 2, Flutter-tree rules:** `missing_provider_scope`, `async_value_nullable_pattern` (+ its fix), `unsupported_provider_value`.
   - **Wave 3, graph-level rules:** `provider_dependencies`, `scoped_providers_should_specify_dependencies`, `only_use_keep_alive_inside_keep_alive`, `provider_parameters`. These need cross-provider reasoning and are where the effort concentrates.
   - **Wave 4, assists:** the six listed above.
3. Skip `riverpod_syntax_error` unless the semantic layer is adopted — it mostly reports malformed declarations that the generator already rejects.
4. Gate every rule on the project actually using Riverpod (types resolve), so it stays silent in non-Riverpod packages. Note that Ligex declares plugins at the pub-workspace root, meaning these rules also load over pure-Dart backend packages and must not fire there.
5. Cross-check each ported rule against riverpod_lint's own test suite for behavioural parity before considering it done.
6. Release as a minor bump; document in the README that `riverpod_lint` is no longer needed alongside, and that the two cannot be enabled together.

## Open Questions

- **Depend on `riverpod_analyzer_utils`, or hand-roll?** It is what makes riverpod_lint's graph-level rules tractable, but it is pinned at `1.0.0-dev.11` (a prerelease) and pulls `riverpod` itself as a dependency — a heavy, unstable transitive load for a lint package, and possibly its own analyzer-version treadmill. Hand-rolling keeps this package dependency-light but makes Wave 3 significantly more expensive. **This decision sets the true effort of the whole task.**
- Is Wave 3 worth it at all? Waves 1-2 plus the existing rules may cover most day-to-day value; `provider_dependencies` is the most complex rule in riverpod_lint by a wide margin.
- Codegen scope: does the port target `riverpod_annotation`/`@riverpod` projects, plain Riverpod 3, or both? Ligex uses `riverpod_annotation ^4.0.6`, so generated providers matter there.
- Licensing/attribution: riverpod_lint is MIT. A port derived from reading its source should carry attribution — decide where (per-file header vs. README/NOTICE).
- Naming: keep riverpod_lint's rule names for familiarity and easy migration, or rename to this package's conventions? Keeping them means a user's existing `diagnostics:` config and `// ignore:` comments mostly carry over, modulo the `many_lints/` prefix.
