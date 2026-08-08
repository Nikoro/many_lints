---
title: "Roll out per-rule exclude to all lint rules"
type: feature
effort: L
status: open
scope: "root"
created: 2026-08-08
branch: "main"
commit: "d743060"
---

# Roll out per-rule exclude to all lint rules

## What

Wire the existing `ResolvedRuleConfig` mechanism into all 132 remaining lint rules so every rule honours per-rule `exclude` globs from `many_lints.yaml`. Then make it the default for new rules, so `/new-lint` produces a rule with `exclude` support already in place.

## Why

`exclude` is the configuration users actually need. The analyzer's only native per-rule control is enable/disable/severity, and its `analyzer: exclude:` is global — it silences *every* rule from *every* plugin for those paths. Without per-rule exclude, a user who wants one noisy rule off in `test/**` or `**/*.g.dart` has to either disable it everywhere or annotate every occurrence.

The mechanism is built and verified end-to-end; only one rule (`avoid_only_rethrow`) currently uses it. Until the rollout happens, the feature is effectively invisible to users, and every new rule added meanwhile increases the backlog.

## Context Snapshot

We researched whether many_lints could support another linter-style per-rule configuration. Reading analyzer 14.1.0 and analysis_server_plugin 0.3.20 sources established that the analyzer cannot carry per-rule options at all: `RuleConfig` holds only `name`/`group`/`severity` with a private constructor, `_parseRuleConfig` rejects map values (reinterpreting them as rule *groups*), custom keys under `plugins: many_lints:` emit `unsupported_option`, and `RuleContext` exposes no path to `AnalysisOptions`. A plugin also cannot report diagnostics against YAML files, so config errors cannot be surfaced to users.

The viable route — parsing our own config file and matching the current file's path inside the rule — was built in `lib/src/rule_config.dart` and proven end-to-end through a real `PluginServer` (21 tests). It reads `many_lints.yaml` at the package root, falling back to a top-level `many_lints:` section in `analysis_options.yaml`; the dedicated file wins outright with no merging.

`avoid_only_rethrow` was converted as the proof of concept, gaining both `exclude` and a mode option. It was chosen over `avoid_border_all` because Flutter-typed rules do not resolve under `createMockSdk` — an early attempt with `avoid_border_all` made every exclusion test pass vacuously, which is the main trap in testing this.

This TODO covers the remaining rollout only. The mechanism itself, the cookbook, and the docs are done.

## Codebase Anchors

- `lib/src/rule_config.dart` — the mechanism: `ResolvedRuleConfig.of(context, ruleName)`, `RuleConfig` typed accessors, `ConfigLoader` caching keyed by package root
- `lib/src/rules/avoid_only_rethrow.dart` — reference implementation; copy this shape
- `lib/src/class_suffix_validator.dart:49` — `registerNodeProcessors` constructing `_ClassSuffixVisitor(this)`; converting this **one** file covers `use_bloc_suffix`, `use_cubit_suffix`, and `use_notifier_suffix` at once
- `test/rule_config_test.dart` — `PluginServer` harness and the asymmetric-test pattern
- `.agents/skills/new-lint/config-cookbook.md` — full recipe, constraints, and testing checklist
- `.agents/skills/new-lint/SKILL.md` — Step 4b, which currently frames configuration as opt-in and will need rewording once `exclude` is universal

## Plan

Measured scope: 133 rule files, 1 already converted. 129 use the plain `_Visitor(this)` shape; 3 route through `ClassSuffixValidator`; 42 register more than one AST callback (up to 3), which is where the real risk sits.

1. **Convert the base class first.** Change `lib/src/class_suffix_validator.dart` to pass `RuleContext` into `_ClassSuffixVisitor` and resolve config in the callback. This handles three rules in one edit and validates the approach on the non-standard shape.

2. **Mechanical sweep of the 129 single-visitor rules.** Per file: add the `../rule_config.dart` import, change `_Visitor(this)` to `_Visitor(this, context)`, add the `RuleContext context` field, and add the guard at the top of the visit callback:
   ```dart
   final resolved = ResolvedRuleConfig.of(context, rule.name);
   if (resolved.isExcluded) return;
   ```
   Consider scripting the common case, but review every diff — the callback bodies vary.

3. **Handle the 42 multi-registration rules carefully.** Every registered callback needs the guard, or the rule leaks diagnostics from the unguarded entry point. Prefer a private `_shouldReport(node)` helper over repeating the two lines. Rules registering 3 callbacks (`prefer_wildcard_pattern`, `prefer_type_over_var`, `prefer_returning_shorthands`, `prefer_for_loop_in_children`, `dispose_provided_instances`, `avoid_unsafe_collection_methods`) deserve individual attention.

4. **Watch `addCompilationUnit` and `afterLibrary` rules.** File-level rules (e.g. `prefer_single_widget_per_file`) and cross-unit rules resolve against a different unit than per-node rules; verify the path used is the file actually being reported on, not the defining unit.

5. **Test coverage.** A per-rule exclusion test for all 133 rules would be enormous and low-value. Instead: keep the thorough suite in `test/rule_config_test.dart` for the mechanism, then add a representative-sample test covering one rule from each visitor shape — single-callback, multi-callback, `ClassSuffixValidator`, and `addCompilationUnit`. Always pair negative assertions with asymmetric positives (see the cookbook's checklist) so tests cannot pass vacuously.

6. **Make it the default for new rules.** Update `/new-lint`: put the `exclude` guard into the Step 4 rule template, and rewrite Step 4b so it covers only *mode options* as opt-in. Update the templates in `config-cookbook.md` and the quick reference in `lib/src/rules/AGENTS.md` to match.

7. **Documentation.** The per-rule docs pages each carry a `## Configuration` section; decide whether `exclude` gets documented once centrally (in `docs/.../configuration.md`, linked from each rule) or repeated per page. Centralised is preferable — 133 near-identical blocks will drift.

8. **Verify.** `dart analyze` clean, full `dart test` green (currently 2047 tests; allow ~2.5 min), `dart format` clean, and the `example/` analysis gate from SKILL.md Step 11.

## Open Questions

- **Release framing.** Is universal `exclude` a minor bump on its own, or held until a batch of mode options lands with it? The mechanism is additive and default-off, so nothing breaks either way.
- **Should `exclude` live on the base `AnalysisRule` instead?** A shared wrapper or mixin could apply the guard once rather than editing 133 files. Worth a spike before step 2 — it would shrink the change dramatically, but rules report from inside visitors, so the interception point is not obvious. If a clean seam exists, the whole sweep collapses.
- **Mode options are out of scope here.** Adding those is per-rule design work, not a sweep; capture separately when specific rules justify them.

## Related Findings

`FINDINGS.md` — "Plugin Configuration" section documents the analyzer constraints behind this design, notably that per-rule options cannot live in `analysis_options.yaml`, that a plugin cannot report diagnostics against YAML files, and that rule instances are long-lived singletons shared across analysis contexts.
