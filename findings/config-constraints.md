# Analyzer Config Constraints

What the analyzer and `analysis_server_plugin` **cannot** do for plugin rule configuration.
Verified against analyzer 14.1.0 / analysis_server_plugin 0.3.20.

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
