# Configurable Lint Rule Cookbook

## About This Document

This cookbook covers **making a lint rule configurable** in the `many_lints` package using **analyzer ^14.1.0** and **analysis_server_plugin ^0.3.20** — per-rule `exclude` patterns and free-form options (modes), e.g. `prefer_single_widget_per_file: {ignore_visible_for_testing: false}`.

**Target Audience:** AI agents and developers adding configuration to lint rules
**Analyzer Version:** ^14.1.0
**Plugin Version:** ^0.3.20
**Last Updated:** August 2026

> **Read this before designing any configuration.** The analyzer's own options system **cannot** carry per-rule options. Several obvious-looking approaches produce user-visible warnings or silently do nothing. The [Constraints](#constraints-what-the-analyzer-cannot-do) section explains exactly why, with source citations — do not re-derive it.

---

## META-INSTRUCTIONS FOR AGENTS

### When to Update This Cookbook

**You MUST update this cookbook when:**
- You discover a new way to reach configuration or file paths from inside a rule
- The analyzer or analysis_server_plugin gains real per-rule options support (check `AnalysisOptionsFileKeys.pluginsOptions` and `RuleConfig` on every dependency bump)
- You add a new option *kind* to `RuleConfig` (e.g. a typed enum accessor beyond bool/int/string-list)
- You find a glob or path-matching edge case that behaves differently from analyzer's own exclude handling
- You hit a caching or invalidation bug caused by rule-instance lifetime

### What to Document

- **Working code example** (tested and verified)
- **File reference** to the real implementation (e.g. `lib/src/rule_config.dart`)
- **Brief explanation** of when to use the pattern
- **Common pitfalls** if any

### How to Update

1. Find the appropriate section (or create a new one)
2. Add your pattern following the existing format
3. Include file references
4. Update the Pattern Index if adding sections
5. Also add a brief mention to `lib/src/rules/AGENTS.md`

---

## Pattern Index

- [Constraints: What the Analyzer Cannot Do](#constraints-what-the-analyzer-cannot-do)
- [What Works Without Any Code: Severity](#what-works-without-any-code-severity)
- [The Configuration Mechanism](#the-configuration-mechanism)
- [Recipe: Adding `exclude` to a Rule](#recipe-adding-exclude-to-a-rule)
- [Recipe: Adding a Mode Option](#recipe-adding-a-mode-option)
- [Reading Options: Typed Accessors](#reading-options-typed-accessors)
- [Testing a Configurable Rule](#testing-a-configurable-rule)
- [Documenting a Configurable Rule](#documenting-a-configurable-rule)
- [Common Gotchas](#common-gotchas)

---

## Constraints: What the Analyzer Cannot Do

All verified 2026-08-08 by reading analyzer 14.1.0 / analysis_server_plugin 0.3.20 sources and confirming empirically with `dart analyze`.

### ❌ Per-rule options in `analysis_options.yaml` do not exist

```yaml
# THIS DOES NOT WORK — do not propose it
plugins:
  many_lints:
    diagnostics:
      my_rule:
        some_option: false     # ← reported as an options-file error
```

Why:

- `RuleConfig` (aliased `DiagnosticConfig`, `analyzer/src/lint/config.dart:134`) has exactly three fields — `name`, `group`, `severity`. No options field, and its constructor is private (`RuleConfig._`), so it cannot be subclassed to add one.
- `_parseRuleConfig` accepts **only YAML scalars** (`bool` or a severity `String`) and returns `null` for a map. Worse, a nested map is reinterpreted as a rule **group**, so `my_rule: {opt: false}` is read as a group named `my_rule` containing a rule named `opt`.
- `_validateDiagnostics` hard-rejects any non-scalar value under `diagnostics:`, making the above an outright reported error.

### ❌ Custom keys under `plugins: many_lints:` warn

```yaml
plugins:
  many_lints:
    exclude:            # ← "The option 'exclude' isn't supported by 'plugins'"
      - test/**
```

`AnalysisOptionsFileKeys.pluginsOptions` is a closed set: `{diagnostics, git, path, version, hosted}`. `_validatePluginMap` reports anything else as `unsupported_option`.

### ❌ A rule cannot reach `AnalysisOptions`

`RuleContext` exposes exactly: `allUnits`, `currentUnit`, `definingUnit`, `isInLibDir`, `isInTestDirectory`, `libraryElement`, `package`, `typeProvider`, `typeSystem`, `isFeatureEnabled`. **No `analysisOptions`.** `PluginServer` holds the `AnalysisOptionsImpl` in a local scope and deliberately drops it when constructing the context — options are used only to pick *which* rules run and at what severity.

### ❌ There is no diagnostic-filtering hook

`Plugin` has only `name` / `register` / `start` / `shutDown`. `_computeDiagnosticsFromPlugin` is private, and `PluginServer` lives under `lib/src/`.

### ❌ A plugin cannot report diagnostics against YAML files

`PluginServer._analyzeAllFilesInContextCollection` filters analyzed paths with `file_paths.isDart(...)`, with an explicit upstream TODO about someday enabling "YAML files for analysis options and pubspec analysis". `AbstractAnalysisRule` exposes a `pubspecVisitor` hook, but **`PluginServer` never invokes it**.

**Consequence:** you cannot warn the user about a malformed or conflicting config file on the file itself. Config problems must degrade gracefully and be documented, not diagnosed.

### ❌ `analyzer: exclude:` is global, not per-rule

It is enforced at the "never analyze this file at all" level (`ContextRootImpl.isAnalyzed` gates four points in `PluginServer`), so it disables *every* rule from *every* plugin plus core analyzer diagnostics. A rule's visitors never see an excluded unit.

### ✅ What *is* safe: a top-level custom section

An unrecognized **top-level** key in `analysis_options.yaml` produces no warning — the analyzer only validates the interior of sections it knows.

```yaml
many_lints:            # ← no warning; analyzer ignores it entirely
  rules:
    my_rule:
      exclude: [test/**]
```

The trade-off: because the analyzer never parses it, this section does **not** inherit through `include:`.

---

## What Works Without Any Code: Severity

Before adding configuration, check whether severity alone solves the user's problem. Enable/disable and severity override are natively supported and need **zero** implementation:

```yaml
plugins:
  many_lints:
    diagnostics:
      my_rule: error      # error | warning | info | true | false
```

This works because every rule in this project is registered via `_registerWarningRule`, and `RegistryMixin.enabled` treats warning rules as opt-out.

**Do not build configuration for something severity already covers.**

---

## The Configuration Mechanism

Implemented in [`lib/src/rule_config.dart`](../../../lib/src/rule_config.dart). Two sources are supported, read in this order:

1. **`many_lints.yaml`** at the package root (takes precedence)
2. A top-level **`many_lints:`** section in `analysis_options.yaml` (fallback)

```yaml
# many_lints.yaml
rules:
  my_rule:
    exclude:
      - test/**
      - "**/*.g.dart"
    some_mode_option: true
```

```yaml
# analysis_options.yaml — equivalent, nested one level deeper
many_lints:
  rules:
    my_rule:
      exclude: [test/**]
      some_mode_option: true
```

**Precedence is a clean win, never a merge.** When both exist, the dedicated file is used and the section is ignored *entirely* — not merged per-rule. Merging `exclude` lists across two files makes "where did this pattern come from" nearly impossible to answer. The conflict resolves silently because it cannot be diagnosed (see constraints), so it is documented instead.

Key types:

| Type | Role |
|------|------|
| `RuleConfig` | One rule's config: `exclude` list + free-form `options` map, with typed accessors |
| `ManyLintsConfig` | All rules for one package; `.parse()` / `.parseOptionsFile()` |
| `ConfigLoader` | Loads + caches per package root, keyed on both files' modification stamps |
| `ResolvedRuleConfig` | Per-callback resolution: the config plus whether the current file is excluded |

---

## Recipe: Adding `exclude` to a Rule

Two changes to any existing rule. Reference implementation: [`lib/src/rules/avoid_only_rethrow.dart`](../../../lib/src/rules/avoid_only_rethrow.dart).

### 1. Pass the `RuleContext` into the visitor

```dart
import '../rule_config.dart';

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);   // ← pass context
    registry.addTryStatement(this, visitor);
  }
```

```dart
class _Visitor extends SimpleAstVisitor<void> {
  final AvoidOnlyRethrow rule;
  final RuleContext context;                   // ← store it

  _Visitor(this.rule, this.context);
```

### 2. Resolve **inside** the callback and bail when excluded

```dart
  @override
  void visitTryStatement(TryStatement node) {
    // Resolved per node rather than once at registration time: the lookup
    // needs `RuleContext.currentUnit`, which is null while
    // `registerNodeProcessors` runs.
    final resolved = ResolvedRuleConfig.of(context, rule.name);
    if (resolved.isExcluded) return;

    // ... existing detection logic
  }
```

> 🚨 **Never resolve config in `registerNodeProcessors`.** `RuleContext.currentUnit` is `null` there — `PluginServer` assigns it immediately before `unit.accept(...)`. Resolving early yields the wrong file path or none at all.

For a rule with several registered callbacks, add the same two lines to each entry point, or factor them into a private `_shouldReport(node)` helper.

### How exclusion resolves internally

```dart
final path = context.currentUnit?.file.path ?? context.definingUnit.file.path;
final root = context.package?.root;                  // Folder?
final relative = root?.relativeIfContains(path);     // e.g. 'test/foo.dart'
```

`relativeIfContains` is the same helper analyzer's own `LocatedGlob.matches` uses, so glob semantics match analyzer's exclude handling. Matching uses `Glob('/', pattern)` from `analyzer/src/util/glob.dart` (an implementation import — hence `ignore_for_file: implementation_imports` in `rule_config.dart`).

Prefer `currentUnit` over `definingUnit`: a library's parts can live in different directories than its defining unit. For the same reason, `RuleContext.isInLibDir` and `isInTestDirectory` are computed from `definingUnit` and **misreport for part files** — do not use them as a substitute for path matching.

---

## Recipe: Adding a Mode Option

A mode narrows or widens what the rule reports. Read it from the resolved config and branch:

```dart
  @override
  void visitTryStatement(TryStatement node) {
    final resolved = ResolvedRuleConfig.of(context, rule.name);
    if (resolved.isExcluded) return;

    // `ignore_typed_catches: true` limits the rule to untyped `catch (e)`
    // clauses, leaving `on SomeError catch (e) { rethrow; }` alone — that
    // form narrows which exceptions propagate, so it is not always redundant.
    final ignoreTyped = resolved.config.boolOption(
      'ignore_typed_catches',
      defaultValue: false,
    );

    for (final catchClause in node.catchClauses) {
      if (ignoreTyped && catchClause.exceptionType != null) continue;
      // ... existing detection
    }
  }
```

Design rules for options:

- **Default must preserve current behavior.** Every `defaultValue` should reproduce exactly what the rule did before it became configurable, so upgrading never changes results silently.
- **Name the option for what it does, not how.** `ignore_typed_catches` beats `mode: 2`.
- **Prefer narrowing over widening.** An option that makes a rule quieter is safe; one that makes it noisier will surprise users on upgrade.
- **Use snake_case** to match Dart lint naming and the rest of the file.
- **Do not add an option that duplicates `exclude` or severity.** "Turn this off in tests" is `exclude: [test/**]`; "make this an error" is `diagnostics:`.

---

## Reading Options: Typed Accessors

`RuleConfig` provides accessors that fall back to the default when the key is absent **or** the YAML value has the wrong type — a user typo can never crash analysis or produce a `TypeError`:

```dart
config.boolOption('ignore_typed_catches', defaultValue: false)
config.intOption('max_count', defaultValue: 10)
config.stringListOption('allowed_names')            // defaults to const []
```

Reach into `config.options` directly only for a shape none of these covers — and if you do, add a typed accessor to `RuleConfig` rather than parsing inline, then document it here.

---

## Testing a Configurable Rule

`AnalysisRuleTest` **cannot** test configuration — it has no package root with a config file. Drive a real `PluginServer` instead, following [`test/rule_config_test.dart`](../../../test/rule_config_test.dart).

The harness writes `analysis_options.yaml` (with the `plugins:` block), optionally `many_lints.yaml`, then the Dart file, and asserts on emitted diagnostic codes:

```dart
test('exclude pattern silences the rule in a matching file', () async {
  final errors = await harness.analyze(
    _rethrowCode,
    config: '''
rules:
  avoid_only_rethrow:
    exclude:
      - lib/**
''',
  );

  expect(errors.map((e) => e.code), isNot(contains('avoid_only_rethrow')));
});
```

Harness requirements (analysis_server_plugin 0.3.18+):

- Use `AnalysisSetAnalysisRootsParams(included, excluded)` — `analysis.setContextRoots` was renamed.
- `tearDown` must `await pluginServer.waitForIdle()` **before** `channel.close()`.
- Call `ConfigLoader.clearCache()` in `setUp` — the cache is static and survives across tests.

### 🚨 Two mandatory test-design rules

**1. Pick a pure-Dart rule fixture.** Rules whose `TypeChecker` needs Flutter types do **not** resolve under `createMockSdk`. A first attempt at these tests used `avoid_border_all`; the rule reported nothing at all, so every "excluded" assertion passed **vacuously** while proving nothing. If the rule under test needs external types, mock them, and always include a no-config test asserting the rule *does* fire.

**2. Pair every negative test with an asymmetric positive one.** A test that only asserts silence cannot distinguish "exclusion worked" from "the rule never fired":

```dart
// Negative: pattern matches the file → silence
config: 'rules:\n  my_rule:\n    exclude: [lib/**]'
expect(codes, isNot(contains('my_rule')));

// Positive: pattern does NOT match the file → still reports
config: 'rules:\n  my_rule:\n    exclude: [test/**]'
expect(codes, contains('my_rule'));
```

Apply the same logic to modes: assert both that the option suppresses the case it targets **and** that it leaves other cases reporting.

### Coverage checklist

- [ ] Rule fires with no config file present
- [ ] `exclude` matching the file → silent
- [ ] `exclude` **not** matching the file → still reports (asymmetric)
- [ ] Suffix glob (`**/*.g.dart`) works
- [ ] Excluding one rule leaves other rules reporting
- [ ] Mode option suppresses its target case
- [ ] Mode option leaves non-target cases reporting (asymmetric)
- [ ] Config via the `analysis_options.yaml` section works
- [ ] Precedence: dedicated file wins, and the losing source is ignored **outright** (assert a merge would have produced a different result)
- [ ] Unit tests for parsing: malformed YAML, wrong-typed option, absent rule

---

## Documenting a Configurable Rule

Extend the standard `## Configuration` section of the rule's docs page (Step 9 of SKILL.md) with the options it supports:

````markdown
## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      avoid_only_rethrow: false
```

### Options

Configure in `many_lints.yaml` at your package root:

```yaml
rules:
  avoid_only_rethrow:
    exclude:
      - test/**
    ignore_typed_catches: true
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `exclude` | list of globs | `[]` | Paths, relative to the package root, where this rule is skipped |
| `ignore_typed_catches` | bool | `false` | Only report untyped `catch (e)` clauses |

Alternatively, use a top-level `many_lints:` section in `analysis_options.yaml`.
Note this section does **not** inherit through `include:`; when both sources
exist, `many_lints.yaml` wins and the section is ignored entirely.
````

Always state the default and always mention the `include:` caveat when showing the section form.

---

## Common Gotchas

### Rule instances are long-lived singletons

`PluginRegistryImpl` stores rules in a `Map` once at registration and reuses the **same instances** for every analysis context root. Caching resolved config as a field on the rule leaks one package's configuration into another package's analysis.

`ConfigLoader` handles this correctly — a static cache keyed by package root path, invalidated on both files' `modificationStamp`. **Never store per-context state on a rule object.**

### `currentUnit` is null at registration

Covered above, but it is the single most likely mistake: resolve config inside the visitor callback, not in `registerNodeProcessors`.

### `dart analyze <file>.yaml` does not validate options

Running `dart analyze analysis_options.yaml` reports "No issues found" even for genuinely invalid options — validation only runs when the file is picked up as the options for an analyzed context root. Always verify with `dart analyze .` on a probe project, and include a known-bad key (e.g. `analyzer: {bogus_key: true}`) as a **control** to confirm the validator actually ran.

### Malformed config must degrade, never throw

A broken `many_lints.yaml` must not take down analysis of the whole package, and (per the constraints) cannot be reported to the user. `ManyLintsConfig.parse` catches `YamlException` and returns `empty`; `ConfigLoader` catches `FileSystemException`. Preserve this behavior in any extension.

### Do not claim a rule "cannot be silenced"

Plugin diagnostics **do** respect `// ignore: many_lints/<rule>` and `// ignore_for_file: many_lints/<rule>` (the plugin-name prefix is required). Never justify a config option — or a rule change — with the claim that a pattern cannot be suppressed. Justify it by the pattern being legitimate and common enough that users should not have to annotate it. See the project `AGENTS.md` "Diagnostic Suppression" table.

### When *not* to add configuration

Configuration is a maintenance cost and a combinatorial testing burden. Skip it when:

- Severity or `diagnostics: false` already covers the need
- The "option" encodes a decision the rule should just make correctly
- Only one project would ever set it — fix the rule's heuristic instead

Prefer a rule that is right by default over a rule with knobs.
