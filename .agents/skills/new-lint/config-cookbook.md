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
- [Recipe: A Policy Rule That Ships With No Policy](#recipe-a-policy-rule-that-ships-with-no-policy)
- [Naming Conventions](#naming-conventions-decide-nothing-per-rule)
- [Reading Options: Typed Accessors](#reading-options-typed-accessors)
- [Prefer Configuration Over a Hardcoded Constructor Argument](#prefer-configuration-over-a-hardcoded-constructor-argument)
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
| `ResolvedRuleConfig` | Resolution for one file: the config plus whether that file is excluded |
| `ManyLintsRule` | Base class for every rule; applies `exclude` automatically |

---

## `exclude` Is Automatic — Do Not Hand-Write It

Every rule in this package extends [`ManyLintsRule`](../../../lib/src/many_lints_rule.dart) instead of `AnalysisRule`, and that base class applies `exclude` for you. **A new rule needs no code at all to support it.**

The only difference when writing a rule: override `registerManyLintsProcessors` rather than `registerNodeProcessors`.

```dart
import '../many_lints_rule.dart';

class MyRule extends ManyLintsRule {
  // ...

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addTryStatement(this, visitor);
  }
}
```

`registerNodeProcessors` is `final`-in-spirit here: `ManyLintsRule` implements it to capture the package root, then delegates. Overriding it directly skips that capture and silently disables `exclude` for the rule.

### Why it intercepts the reporter

`ManyLintsRule` overrides `set reporter`, the single field every reporting method (`reportAtNode`, `reportAtToken`, `reportAtOffset`, `reportAtSourceRange`, `reportAtPubNode`) funnels through. Both drivers — analyzer's `LibraryAnalyzer` and `PluginServer` — assign it once per compilation unit, immediately before visiting that unit. When the file is excluded, the rule is handed a reporter backed by `DiagnosticListener.nullListener`: visitors still run and still "report", but the diagnostics go nowhere.

The alternative — a `ResolvedRuleConfig.of(context, rule.name)` guard at the top of each callback — was rejected. It has to be repeated in *every* registered callback, and 42 rules here register more than one. A single missed callback leaks diagnostics from an excluded file, and no rule's own tests would catch it, because they never configure an exclude. Suppressing at the sink is structural: it cannot be forgotten, and it is independent of how a rule's visitors are shaped (per-node, `addCompilationUnit`, or `afterLibrary`).

`ResolvedRuleConfig.of()` still exists for code that holds a `RuleContext` and needs the answer directly. If you ever call it, do so **inside** a callback — `RuleContext.currentUnit` is `null` during `registerNodeProcessors`.

### How exclusion resolves internally

```dart
final relative = packageRoot.relativeIfContains(path);   // e.g. 'test/foo.dart'
Glob('/', pattern).matches(relative.replaceAll(r'\', '/'));
```

`relativeIfContains` is the same helper analyzer's own `LocatedGlob.matches` uses, so glob semantics match analyzer's exclude handling. `Glob` comes from `analyzer/src/util/glob.dart` (an implementation import — hence `ignore_for_file: implementation_imports` in `rule_config.dart`).

The path comes from the reporter's own `source.fullName`, which is always the file being reported on. That sidesteps a trap in the context-based route: `RuleContext.isInLibDir` and `isInTestDirectory` are computed from `definingUnit` and **misreport for part files**, so they are not a substitute for path matching.

---

## Recipe: Adding a Mode Option

`exclude` is free; a *mode* option is the only thing a rule implements by hand. A mode narrows or widens what the rule reports. Read it from `rule.config` — already resolved for the current file — and branch:

```dart
  @override
  void visitTryStatement(TryStatement node) {
    // No exclude guard needed: `ManyLintsRule` handles it at the reporter.

    // `ignore_typed_catches: true` limits the rule to untyped `catch (e)`
    // clauses, leaving `on SomeError catch (e) { rethrow; }` alone — that
    // form narrows which exceptions propagate, so it is not always redundant.
    final ignoreTyped = rule.config.boolOption(
      'ignore_typed_catches',
      defaultValue: false,
    );

    for (final catchClause in node.catchClauses) {
      if (ignoreTyped && catchClause.exceptionType != null) continue;
      // ... existing detection
    }
  }
```

`rule.config` is refreshed per file, so read it inside the callback rather than caching it in the visitor's constructor.

Design rules for options:

- **Default must preserve current behavior.** Every `defaultValue` should reproduce exactly what the rule did before it became configurable, so upgrading never changes results silently.
- **Name the option for what it does, not how.** `ignore_typed_catches` beats `mode: 2`.
- **Prefer narrowing over widening.** An option that makes a rule quieter is safe; one that makes it noisier will surprise users on upgrade.
- **Use snake_case** to match Dart lint naming and the rest of the file.
- **Do not add an option that duplicates `exclude` or severity.** "Turn this off in tests" is `exclude: [test/**]`; "make this an error" is `diagnostics:`.

---

## Naming Conventions (decide nothing per-rule)

Large rule catalogues are the cautionary tale here: one ships six spellings for "a numeric limit" (`max-number`, `max-length`, `threshold`, `acceptable-level`, `min-sequence`, `break-on`) and three for "list of names to skip" (`ignored-names`, `exceptions`, `excluded`). `avoid-long-files` uses `max-length` for *lines* while `prefer-correct-type-name` uses it for *characters*.

This package uses one fixed vocabulary. **Do not invent a new key shape for a new rule.**

| Concept | Key | Notes |
|---------|-----|-------|
| Numeric upper bound | `max_<unit>` | Always name the unit — `max_lines`, not `max_number` |
| Numeric lower bound | `min_<unit>` | `min_sequence`, `min_occurrences` |
| Toggle skipping a class of thing | `ignore_<singular>` | `ignore_private`, `ignore_nested` |
| List of specific exclusions | `ignored_<plural>` | `ignored_names`, `ignored_types` |
| **Replace** a built-in list | `<plural>` | `cleanup_methods`, `classes` |
| **Append** to a built-in list | `additional_<plural>` | `additional_cleanup_methods` |
| Regex on a name | `name_pattern` | one spelling only |

## Reading Options: Typed Accessors

`RuleConfig` provides accessors that fall back to the default when the key is absent **or** the YAML value has the wrong type — a user typo can never crash analysis or produce a `TypeError`:

```dart
config.boolOption('ignore_typed_catches', defaultValue: false)
config.intOption('max_count', defaultValue: 10)
config.stringListOption('allowed_names')            // defaults to const []
config.nameSetOption('classes', defaultValue: _defaults)   // replace + append
```

### `nameSetOption` — the replace/append pair

`nameSetOption('classes', defaultValue: ...)` reads **two** keys: `classes` replaces the default set outright, and `additional_classes` extends whichever set won. Both may be combined.

Prefer it over a bare `stringListOption` for any built-in list of names. With a single option a user cannot express "the defaults plus one more" without restating every default, and restated defaults silently rot when a later version of this package adds a name.

Note the semantics of an **empty** list: `classes: []` means "no names", not "the defaults". That is intentional — a user who writes an empty list means it.

### When order matters, use a `List`, not a `Set`

`nameSetOption` returns a `Set`, which is wrong when the list encodes a priority. `disposal_utils.dart` resolves cleanup methods through its own `resolveCleanupMethods(rule)` helper returning a `List`, because `findCleanupMethod` picks the *first* match and a type declaring both `close` and `cancel` must resolve deterministically. Configured names are appended after the base list so a project's `release()` never pre-empts a standard method.

Reach into `config.options` directly only for a shape none of these covers — and if you do, add a typed accessor to `RuleConfig` rather than parsing inline, then document it here.

**Nested YAML survives parsing.** `RuleConfig._fromYaml` stores `options[name] = value.value`, which preserves nested `YamlMap`/`YamlList` structure (verified empirically). A list-of-maps option therefore requires only a **new typed accessor**, not a parser change. `entriesOption(key)` is that accessor: it returns `List<Map<String, Object?>>`, dropping non-map items and non-string keys so a malformed entry costs the user that entry and nothing else. `class_affix_validator.dart` is the worked example, and it is the same shape the `avoid_banned_*` family needs.

## Recipe: A Policy Rule That Ships With No Policy

Six rules (`avoid_banned_imports` / `_exports` / `_types` / `_names` /
`_annotations`, plus `banned_usage`) exist only to enforce user-supplied
policy: with no config they report nothing at all. `lib/src/banned_entry.dart`
is the shared implementation, and the shape generalises to any "list of things
this project forbids" rule.

**One entry shape across the whole family.** Every one of those rules reads the
same `banned:` list with the same four keys, so learning one teaches all six:

```yaml
rules:
  avoid_banned_imports:
    banned:
      - deny: ['package:flutter/material.dart']   # exact match
        deny_pattern: ['package:legacy_.*']       # anchored regex, opt-in
        in: ['lib/domain/**']                     # globs; omit = everywhere
        message: 'Domain must not depend on Flutter.'
```

This is the mistake worth *not* repeating: an `entries:` key that means six
unrelated shapes across twelve rules, so you cannot infer the shape from the
key. Name the key after the concept (`banned:`), and keep the field set fixed.

### Match exactly by default; make patterns opt-in

`deny:` is exact. Were it a regex matched as a *substring*, banning
`visibleForTesting` would also hit `notVisibleForTesting`, leaving users to
anchor every pattern with `^`/`$`. Exact-by-default plus a
separate `deny_pattern:` removes the whole class of surprise.

When you do accept a regex, anchor it **for** the user, and do it by checking
the match span rather than by wrapping the source:

```dart
bool matchesWholeValue(String value) {
  final match = firstMatch(value);
  return match != null && match.start == 0 && match.end == value.length;
}
```

Wrapping as `RegExp('^(?:${p.pattern})\$')` also works, but naive `'^$p\$'`
concatenation silently rebinds a top-level alternation: `foo|bar` becomes
`^foo|bar$`, which matches `xbar`. There is a regression test for this.

### Scope by glob, never by regex

Path scoping (`in:`) uses the same `Glob` as `exclude:`, so path semantics are
identical everywhere in the config file — and because `relativeIfContains`
normalizes separators, the Windows-path caveat that separator-sensitive
matching invites simply does not arise.

To match a glob you need the file's path relative to the package root.
`ManyLintsRule` now exposes it as `rule.relativePath`, captured in the reporter
setter alongside `config` (so, like `config`, it is only meaningful inside a
visitor callback). Take it from the reporter's source rather than
`RuleContext`: `isInLibDir` / `isInTestDirectory` are computed from the
*defining* unit and misreport for part files.

### Accept a scalar where a list is expected

`deny: package:flutter/material.dart` and `deny: [package:...]` both work.
Normalizing a bare scalar into a one-item list costs three lines and removes a
recurring "why is my config ignored" confusion.

### Degrade quietly, entry by entry

A plugin cannot report diagnostics against a YAML file at all, so bad config
must never throw. Push the degradation down to the smallest unit: an invalid
regex costs the user *that pattern*, a malformed entry costs *that entry*, and
everything else still applies. `readBannedEntries` also drops entries that deny
nothing, so callers never re-check emptiness.

### Prefer declarations over references

`avoid_banned_names` reports only declaration sites, not every reference. This
is a general principle for naming rules: a reference is not separately fixable
(renaming the declaration fixes them all), so reporting references buries the
one actionable line under noise. Register the specific declaration callbacks
rather than `addSimpleIdentifier`.

Note `MixinDeclaration` uses `.name` while `ClassDeclaration` / `EnumDeclaration` /
`ExtensionTypeDeclaration` use `.namePart.typeName`.

### Match members through the declaring type

`banned_usage` resolves `Type.member` against the type that **declares** the
member, walking `allSupertypes`, so banning `Iterable.first` also catches a
`List` receiver. Matching the *static receiver* type instead would let any
subclass slip past.

Two shapes are easy to miss: the unnamed constructor has an empty
`ConstructorElement.name` (normalize it to `new` so `Random.new` is writable),
and a `target.member` read parses as `PropertyAccess` **except** when the
target is a simple identifier, where it is a `PrefixedIdentifier` — register
both or tear-offs are missed.

### Disambiguate a bare name with a qualified form

`avoid_banned_types` accepts both `Border` and
`package:flutter/src/painting/border.dart#Border`. Try the qualified spelling
first so a `Type.member`-style entry wins over a bare one when both could
match. Match on the **declared** name (`element.name`), not the written one, or
an import prefix hides the usage.

## Prefer Configuration Over a Hardcoded Constructor Argument

`use_bloc_suffix` / `use_cubit_suffix` / `use_notifier_suffix` were originally three rules over one base class, each passing its base type as a **constructor argument**. Making the *suffix* configurable still left the *type* hardcoded, so the package enforced naming for exactly three types and a project wanting `...Repository` had to fork.

They were replaced by `use_class_suffix` / `use_class_prefix`, which read `entries:` and work for any type. The lesson generalises: when a rule's constructor argument encodes *which thing to look for*, that is usually configuration, not a subclass. Three near-identical subclasses is the smell.

### Gotcha: `isSuperOf` is reflexive

`TypeChecker.isSuperOf` calls `isExactly(element)` first, so **the configured base type matches itself**. With `type: Repository` the abstract `Repository` gets reported for not being named `DbRepository`. The three old rules never hit this because their base types lived in dependencies and were never declared locally — a user-configured type usually is. Guard with an explicit `if (checker.isExactly(element)) continue;`.

Relatedly, `TypeChecker.fromName`'s `packageName` is optional, and null means "any library". That is required for config (a locally declared type has no `package:` URI) but wrong as a default for a rule shipped in this package — always pin the package in first-party rules.

### Gotcha: a `LintCode` built in the constructor goes stale

The old `ClassSuffixValidator` stored its `LintCode` in a field built from `requiredSuffix`. With a configurable suffix that message keeps advertising the default (`'Use Bloc suffix'`) while the rule enforces `Store`.

The fix is to make `diagnosticCode` a **getter** that rebuilds the code per access:

```dart
@override
LintCode get diagnosticCode => LintCode(
  name,
  'Use $requiredSuffix suffix',
  correctionMessage: 'Ex. {0}$requiredSuffix',
);
```

This works because every `reportAt*` method reads the `diagnosticCode` getter at report time rather than capturing it. Assert on the message in a test — a stale message is invisible to a test that only checks the diagnostic's `code`.

**Prefer message arguments when the value varies per report.** The getter above is only safe while the text is constant for a whole file. Once one file can produce several different affixes (one per matched entry), a per-access `LintCode` would mint a *different* code object per report — and `registerFixForRule` keys the fix registry on the `LintCode`, so the fix stops being found. Keep one `static const` code with `{0}` placeholders and pass the varying part through `arguments:`:

```dart
rule.reportAtToken(name, arguments: [violated.affix, className]);
```

Rule of thumb: option affects the message **per file** → getter is fine; **per diagnostic** → `static const` code plus arguments.

### Guard against options that silently disable a rule

An empty `suffix: ""` would make every class name "end with" it, turning the rule off without saying so. Treat empty as absent:

```dart
return configured is String && configured.isNotEmpty ? configured : defaultSuffix;
```

Apply the same scepticism to any option whose degenerate value neutralises the rule.

### A quick fix can read config too

A fix has no `RuleContext`, but it can reach the package root from its unit result and resolve exactly what the rule resolved:

```dart
final resolved = ResolvedRuleConfig.forPath(
  packageRoot: unitResult.session.analysisContext.contextRoot.root,
  path: unitResult.path,
  ruleName: 'use_class_suffix',
);
```

Two constraints shape the design:

- **`fixKind` must be constant.** `registerFixForRule` instantiates the producer at registration time with a stub context and throws if `fixKind` is null (`analysis_server_plugin/src/registry.dart:52`). So the *kind* cannot depend on config — one `FixKind` per rule, with the config-derived part living only inside `compute`.
- **Re-derive, don't parse the message.** Recomputing from config (the pattern `dispose_fields_fix.dart` uses for cleanup methods) keeps the fix correct if the diagnostic is reworded.

Factor the entry matching into a shared helper taking a `RuleConfig` — not a rule — so the fix and the rule cannot drift apart. `readAffixEntries` / `findViolatedEntry` in `class_affix_validator.dart` are shared exactly this way.

To test such a fix, `FixHarness.applyFix` takes a `manyLintsConfig:` parameter. It also calls `ConfigLoader.clearCache()` in `setUp`, without which one test's config leaks into the next.

### Keep detection and recognition on the same list

`dispose_fields` uses the cleanup-method list twice: once to decide a field *needs* cleanup, and once (in a separate collector) to recognise a call that *performs* it. Threading the resolved list into only one of them makes a configured `release()` report as never-disposed — a false positive created by the option itself.

Resolve such a list **once per callback** and pass it into every collector that consumes it.

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

**1. Pick a pure-Dart rule fixture, or mock the package.** Rules whose `TypeChecker` needs Flutter types do **not** resolve under `createMockSdk`. A first attempt at these tests used `avoid_border_all`; the rule reported nothing at all, so every "excluded" assertion passed **vacuously** while proving nothing.

A pure-Dart rule (`prefer_class_destructuring`, `avoid_only_rethrow`) is the easy path. When the rule is inherently package-bound, **mock the package** rather than dropping to a unit test — write the library and a `package_config.json` pointing at it, and the `TypeChecker` resolves normally:

```dart
void _addBlocPackage() {
  final blocRoot = convertPath('/pkg/bloc');
  newFile(join(blocRoot, 'lib', 'bloc.dart'), 'class Bloc<Event, State> {}');

  newFile(join(packagePath, '.dart_tool', 'package_config.json'), '''
{
  "configVersion": 2,
  "packages": [
    {"name": "package", "rootUri": "${toUri(packagePath)}", "packageUri": "lib/"},
    {"name": "bloc", "rootUri": "${toUri(blocRoot)}", "packageUri": "lib/"}
  ]
}
''');
}
```

See `test/rule_options_test.dart` for the working version. This is what makes end-to-end option tests possible for `use_class_suffix` and the other package-keyed rules.

**Always include a control test asserting the rule fires with no config**, whichever route you take. It is the only thing separating "the option worked" from "nothing ran".

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
- [ ] A wrong-typed option value falls back to the default (does not throw, does not disable)
- [ ] A degenerate value (empty string / empty list) does not silently disable the rule
- [ ] If the option feeds the diagnostic text, assert on the **message**, not just the code
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
