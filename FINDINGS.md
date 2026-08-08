# Findings

Crucial discoveries and "aha moments" captured during development sessions.

## Plugin Configuration

### [GOTCHA] [CRITICAL] Analyzer gives plugin rules only severity — no per-rule options exist
**Area:** `lib/many_lints.dart`
**Tags:** `#architecture` `#tooling`
**Verified:** 2026-08-08

**Symptom:** per-rule configuration (`rule: {option: false}`) looks like it should work in `analysis_options.yaml`, but silently fails to configure anything.

**Root cause:** Verified against analyzer 14.1.0 + analysis_server_plugin 0.3.20:
- `RuleConfig` (aliased as `DiagnosticConfig`) has exactly three fields: `name`, `group`, `severity`. There is no options field, and its constructor is private (`RuleConfig._`), so it cannot be subclassed to add one.
- `_parseRuleConfig` in `analyzer/src/lint/config.dart` accepts **only YAML scalars** (`bool` or severity `String`). A map value returns `null` — worse, a nested map gets reinterpreted as a rule *group*, not as options. So `my_rule: {opt: false}` is read as a group named `my_rule` containing a rule named `opt`.
- `RuleContext` exposes no `analysisOptions`. Options are consumed by `PluginServer` purely to decide *which* rules run and at what severity; the rule instance itself receives nothing.
- `Plugin` base class has only `name`/`register`/`start`/`shutDown` — no diagnostic-filtering hook. `_computeDiagnosticsFromPlugin` is private and `PluginServer` lives under `lib/src/`.

**Workaround:** Parse a separate config file (e.g. `many_lints.yaml` at package root) from within the rule. See the companion finding on obtaining the file path.

---

### [GOTCHA] [CRITICAL] Unknown keys under `plugins: <name>:` produce user-visible warnings
**Area:** `lib/many_lints.dart`
**Tags:** `#tooling` `#gotcha`
**Verified:** 2026-08-08

**Symptom:** Adding a custom config key under the plugin's own `analysis_options.yaml` section seems natural, but emits an `unsupported_option` warning in every consuming project.

**Root cause:** `AnalysisOptionsFileKeys.pluginsOptions` is a closed set: `{diagnostics, git, path, version, hosted}`. `_validatePluginMap` reports anything else as unsupported. Additionally `_validateDiagnostics` hard-rejects any non-scalar value under `diagnostics:`, so `my_rule: {opt: 1}` there is an outright options-file error.

**Workaround:** Custom configuration must live outside the `plugins:` block. Note that *top-level* unknown sections (e.g. a `many_lints:` key alongside `analyzer:`) do **not** warn — the validator only checks inside sections it knows. That makes a top-level section viable, at the cost of having to implement `include:` inheritance yourself, since only analyzer-parsed sections inherit through `include`.

---

### [GOTCHA] [CRITICAL] A plugin cannot report diagnostics against YAML files
**Area:** `lib/src/rule_config.dart`
**Tags:** `#tooling` `#architecture`
**Verified:** 2026-08-08

**Symptom:** Warning a user about a malformed or conflicting plugin configuration seems like it should surface on the config file itself — it cannot.

**Root cause:** `PluginServer._analyzeAllFilesInContextCollection` filters analyzed paths with `file_paths.isDart(...)`, carrying an explicit upstream TODO about someday enabling "YAML files for analysis options and pubspec analysis and quick fixes". `AbstractAnalysisRule` does expose a `pubspecVisitor` hook, but `PluginServer` never invokes it.

**Workaround:** Any configuration-level feedback must either be anchored to a Dart file (visible, but reported far from the actual problem) or handled by documentation and a deterministic precedence rule. This project chose the latter: config conflicts resolve silently and are documented instead.

---

### [NOTE] [GOTCHA] Two config sources are supported; the dedicated file wins outright
**Area:** `lib/src/rule_config.dart`
**Tags:** `#design-decision` `#tooling`
**Verified:** 2026-08-08

**What:** Per-rule configuration is read from `many_lints.yaml` at the package root, falling back to a top-level `many_lints:` section in `analysis_options.yaml`. When both exist, the dedicated file wins and the section is ignored **entirely** — the two are never merged, not even per-rule.

**Why:** Merging `exclude` lists across two files makes "where did this pattern come from" very hard to answer. A clean win keeps resolution predictable. The conflict cannot be signalled with a diagnostic (see the finding above), so precedence is documented rather than warned about.

**Alternatives considered:** Reporting a conflict lint anchored to a Dart file — rejected because the message would appear in a file unrelated to the problem. Supporting only one source — rejected because the `analysis_options.yaml` section is more discoverable, while the dedicated file avoids hand-rolling `include:` inheritance; supporting both lets users pick.

**Caveat to document for users:** the `analysis_options.yaml` section does **not** inherit through `include:`, because the analyzer never parses unknown top-level keys and so has nothing to merge across included files.

---

### [NOTE] [GOTCHA] Per-rule severity override already works with zero code
**Area:** `lib/many_lints.dart`
**Tags:** `#tooling`
**Verified:** 2026-08-08

Severity and enable/disable per rule is natively supported for plugin rules and needs no implementation:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_only_rethrow: error   # error | warning | info | true | false
```

Confirmed empirically with `dart analyze`: the rule reports as `error` instead of its default. Enablement semantics come from `RegistryMixin.enabled` — rules registered via `registerWarningRule` are opt-out, those via `registerLintRule` are opt-in. This project registers everything as warning rules, hence default-on behavior.

---

### [GOTCHA] [CRITICAL] `analyzer: exclude:` is global — there is no native per-rule exclude
**Area:** `lib/src/rules/`
**Tags:** `#tooling` `#architecture`
**Verified:** 2026-08-08

**Symptom:** Users wanting to silence one rule in `test/**` find only the global `analyzer: exclude:`, which disables *every* rule from *every* plugin plus core analyzer diagnostics for those files.

**Root cause:** Exclusion is enforced at the "never analyze this file at all" level, not at diagnostic-reporting level. `ContextRootImpl.isAnalyzed` gates four separate points in `PluginServer`, including a per-unit check inside the rule-running loop. A rule's visitors never even see an excluded unit.

**Workaround:** Implement exclusion inside the rule itself, using the file path available via `RuleContext` (see the next finding).

---

### [GOTCHA] [CRITICAL] `RuleContext.currentUnit` is null during `registerNodeProcessors`
**Area:** `lib/src/rule_config.dart`
**Tags:** `#gotcha` `#architecture`
**Verified:** 2026-08-08

**Symptom:** Resolving per-file configuration once at registration time yields a null unit and thus the wrong (or no) file path.

**Root cause:** `PluginServer` assigns `context.currentUnit` only immediately before `unit.accept(...)`, well after `registerNodeProcessors` has run. The doc comment on `RuleContext.currentUnit` states this explicitly.

**Workaround:** Resolve config lazily *inside* each visitor callback, not at registration. The path chain that works:

```dart
final path = context.currentUnit?.file.path ?? context.definingUnit.file.path;
final root = context.package?.root;                 // Folder?
final relative = root?.relativeIfContains(path);    // e.g. 'test/foo.dart'
```

`relativeIfContains` is the same helper analyzer's own `LocatedGlob.matches` uses, so glob semantics match analyzer's exclude handling. Prefer `currentUnit` over `definingUnit`: a library's parts can live in different directories than its defining unit, and `isInLibDir`/`isInTestDirectory` are both computed from `definingUnit` and so misreport for parts.

---

### [GOTCHA] [GOTCHA] Rule instances are long-lived singletons shared across analysis contexts
**Area:** `lib/src/rule_config.dart`
**Tags:** `#architecture` `#data-integrity`
**Verified:** 2026-08-08

**Symptom:** Caching resolved configuration as a field on the rule object leaks one package's config into another package's analysis.

**Root cause:** `PluginRegistryImpl` stores rules in `Map<String, AbstractAnalysisRule>` once at registration and reuses those same instances for every analysis context root.

**Workaround:** Cache configuration keyed by package root path in a static map, invalidated on the config file's `modificationStamp` so edits are picked up without restarting the analysis server. Never store per-context state on the rule.

## Testing

### [NOTE] [GOTCHA] Config-dependent rule behavior is testable via the PluginServer harness
**Area:** `test/rule_config_test.dart`
**Tags:** `#testing` `#tooling`
**Verified:** 2026-08-08

Unlike fixes and assists — which have no `analyzer_testing` API as of 0.3.4 — per-rule configuration is fully testable end-to-end by driving a real `PluginServer`. Reuse the `_PluginAnalysisHarness` pattern from `test/plugin_diagnostics_config_test.dart`: `ResourceProviderMixin` + `createMockSdk` + `AnalysisSetAnalysisRootsParams`, then assert on the emitted `AnalysisError` codes. Remember `await pluginServer.waitForIdle()` in teardown, since 0.3.18+ analyzes asynchronously.

**Test-design caveat learned the hard way:** exclusion tests pass trivially if the fixture never triggers the rule in the first place. An initial attempt used `avoid_border_all`, whose `TypeChecker` requires real Flutter types that do not resolve under `createMockSdk` — so the rule reported nothing and every "excluded" assertion passed vacuously. Pick a pure-Dart rule for config fixtures, and always pair each negative test with an asymmetric positive one (e.g. `exclude: test/**` on a file in `lib/` must still report).

## Tooling

### [NOTE] [NOTE] `dart analyze <file>.yaml` does not validate analysis options
**Area:** `analysis_options.yaml`
**Tags:** `#tooling`
**Verified:** 2026-08-08

Running `dart analyze analysis_options.yaml` reports "No issues found" even for genuinely invalid options. Options validation only runs when the file is picked up as the options for an analyzed context root — i.e. `dart analyze .` on the containing project. When verifying options-file behavior, always analyze the project, and include a known-bad key as a control to confirm the validator actually ran.
