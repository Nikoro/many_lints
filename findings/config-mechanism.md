# Config Mechanism

How `many_lints` actually reaches per-rule configuration at runtime.

### [GOTCHA] [CRITICAL] `analyzer: exclude:` is global — there is no native per-rule exclude
**Area:** `lib/src/rules/`
**Tags:** `#tooling` `#architecture`
**Verified:** 2026-08-08

**Symptom:** Users wanting to silence one rule in `test/**` find only the global `analyzer: exclude:`, which disables *every* rule from *every* plugin plus core analyzer diagnostics for those files.

**Root cause:** Exclusion is enforced at the "never analyze this file at all" level, not at diagnostic-reporting level. `ContextRootImpl.isAnalyzed` gates four separate points in `PluginServer`, including a per-unit check inside the rule-running loop. A rule's visitors never even see an excluded unit.

**Workaround:** Implement exclusion inside the rule itself, using the file path available via `RuleContext` (see the `currentUnit` finding below).

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

---
