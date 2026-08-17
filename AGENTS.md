# Many Lints - Project Context

Custom Dart linter package for Flutter projects, built on `analysis_server_plugin`. Provides lint rules, fixes, and assists that integrate directly with `dart analyze` and IDEs.

## Commands

```bash
dart pub get              # Install dependencies
dart test                 # Run tests
dart analyze              # Verify lints work
dart format .             # Format code
```

## Project Structure

```
lib/
  main.dart               # Re-exports many_lints.dart for analysis_server_plugin discovery
  many_lints.dart         # Plugin entry point - registers all rules, fixes, and assists
  src/
    type_checker.dart     # Type matching utilities for analyzer
    type_inference.dart   # Context type inference utilities
    class_affix_validator.dart  # Base class for configurable class prefix/suffix rules
    text_distance.dart    # String distance utilities (Levenshtein)
    hook_detection.dart   # Hook widget detection helpers
    ast_node_analysis.dart # AST node analysis helpers
    constant_expression.dart # Constant expression/identifier checking helpers
    disposal_utils.dart   # Shared disposal helpers (findCleanupMethod, cleanupMethods)
    dispose_method_editing.dart # Insert into / synthesise a dispose() override
    flutter_widget_helpers.dart # Flutter widget helpers (FlexAxis enum)
    riverpod_type_checkers.dart # Shared Riverpod TypeChecker constants
    flutter_type_checkers.dart  # Shared Flutter widget TypeChecker constants
    bloc_type_checkers.dart     # Shared Bloc/Cubit TypeChecker constants
    hook_type_checkers.dart     # Shared flutter_hooks TypeChecker constants
    declaration_group.dart      # Per-category file budgets (kinds/types/groups config)
    state_class_pairing.dart    # Match a StatefulWidget to its State class
    set_state_collection.dart   # SetStateCollector (shared rule + fix visitor)
    async_guard_utils.dart # Async helpers (containsAwait, isMountedGuardWithReturn)
    async_builder_utils.dart # Async builder source-allocation detection
    null_check_pattern_conversion.dart # Shared `if (x != null)` guard analysis for the two null-check assists
    rules/                # Lint rules (AnalysisRule + SimpleAstVisitor pattern)
    fixes/                # Quick fixes (ResolvedCorrectionProducer pattern)
    assists/              # Code assists (ResolvedCorrectionProducer pattern)
test/
  *.dart                  # Test files (analyzer_testing pattern)
docs/                     # Astro Starlight docs site (see docs/AGENTS.md)
```

## Findings

See [findings/INDEX.md](findings/INDEX.md) for crucial discoveries and "aha moments" captured during development sessions. Review before making changes to unfamiliar areas.

## Reference Docs

Before writing any code:

1. Read these reference docs to understand the framework:
   - [Writing a plugin](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md)
   - [Writing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md)
   - [Testing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md)
   - [Writing assists](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md)

## Diagnostic Suppression (verified 2026-08-03)

Plugin rules **do** respect `// ignore` and `// ignore_for_file` — but only with the plugin-name prefix. Do not repeat the claim that they cannot be suppressed; it is false.

| Comment | Suppressed? |
|---------|-------------|
| `// ignore: <rule>` | ❌ no |
| `// ignore: many_lints/<rule>` | ✅ yes |
| `// ignore_for_file: <rule>` | ❌ no |
| `// ignore_for_file: many_lints/<rule>` | ✅ yes |
| `// ignore: lint` | ❌ no |
| `// ignore: type=lint` | ✅ yes (silences all lints on the line) |

Why: `PluginServer` filters diagnostics through `!ignoreInfo.ignored(e, pluginName: pluginName)`, and `IgnoredDiagnosticName._matches` returns `false` immediately when `this.pluginName != pluginName`. A bare comment parses to `pluginName == null`, so it can never match a plugin diagnostic. The parser only reads a plugin name when a `/` follows the word. The prefix is the key under `plugins:` in `analysis_options.yaml` — *not* `ManyLintsPlugin.name` (`'Many Lints'`). Type-based ignores need the `type=` form (`word.toLowerCase() == 'type'` + `=`); `LintCode.type` is always `DiagnosticType.LINT` regardless of `registerWarningRule`, so `type=warning` does not match.

This is verifiable end-to-end with the `PluginServer` harness in `test/plugin_diagnostics_config_test.dart`.

**Rule of thumb:** never justify a rule change by claiming a false positive "cannot be silenced". It can. Justify it by the pattern being legitimate and common enough that users should not have to annotate it.

## Adding a New Lint Rule

**Use the `/new-lint` skill** for step-by-step guidance, or **`/release`** to prepare a new version. See the full cookbooks:

- [Rules patterns](.agents/skills/new-lint/rules-patterns.md) - Rule structure, type checking, AST, visitors, reporting
- [Rules recipes](.agents/skills/new-lint/rules-recipes.md) - Copy-paste recipes for common patterns
- [Fixes cookbook](.agents/skills/new-lint/fixes-cookbook.md) - Quick fix implementation patterns
- [Assists cookbook](.agents/skills/new-lint/assists-cookbook.md) - Code assist implementation patterns
- [Config cookbook](.agents/skills/new-lint/config-cookbook.md) - Per-rule `exclude` and options; read before designing any rule configuration

Quick summary:

1. Create `lib/src/rules/<rule_name>.dart`
2. Extend `ManyLintsRule`, define a static `LintCode` with `name`, `problemMessage`, `correctionMessage`
3. Implement `registerManyLintsProcessors()` to register visitors via `RuleVisitorRegistry`
4. Create `_Visitor` extending `SimpleAstVisitor`, report issues with `rule.reportAtNode()`
5. Register the rule in `lib/many_lints.dart` via the project wrapper `_registerWarningRule(registry, ...)`
6. Assign the rule to a preset in `lib/src/presets.dart` (`coreRules`, `_recommendedOnlyRules`, or neither) — registering a rule does **not** switch it on
7. Optionally create a fix in `lib/src/fixes/` extending `ResolvedCorrectionProducer`
8. Create `test/<rule_name>_test.dart` extending `ManyLintsRuleTest` (from `test/many_lints_rule_test_base.dart`), **not** `AnalysisRuleTest`
9. Create a documentation page in `docs/src/content/docs/docs/rules/<category>/`, stating which preset the rule belongs to
10. Create `example/lib/<lint_name>_example.dart` with bad/good/edge-case examples

## Rule Enablement (1.0.0)

Every rule is **opt-in**. With no configuration the package is silent; a project selects
rules with `preset:` in `many_lints.yaml` (or the top-level `many_lints:` section):

| Preset | Rules | Contents |
|--------|-------|----------|
| `none` | 0 | Nothing. The default. |
| `core` | 35 | Near-certain bugs only. |
| `recommended` | 91 | `core` plus likely defects and concrete runtime risks. |
| `opinionated` | 177 | `recommended` plus this package's preferred style. |
| `pedantic` | 234 | `opinionated` plus strict naming, structure, complexity and ordering. |

There is deliberately **no** preset enabling every rule: some rules contradict each other
(`prefer_container` vs `prefer_padding_over_container`, `use_gap` vs `prefer_spacing`).
`opinionated` and `pedantic` pick one side; the other stays opt-in by name, as do config-only rules
(the `banned_*` family, the affix rules) — see `conflictingWithOpinionated` in
`lib/src/presets.dart`.

Presets **cannot** ship as includable YAML the way `package:lints` does: the analyzer
replaces a plugin's config wholesale across `include:` rather than merging it, and
`diagnostics:` accepts severity scalars only. So rules stay registered as *warning* rules
and the real gate is applied per file in `ManyLintsRule.set reporter`, which hands a
disabled rule a null-listener reporter. Resolution order in
`ManyLintsConfig.isRuleEnabled`: explicit `enabled:` → preset → any config block at all
(so an `exclude:` never silently does nothing).

## Code Conventions

- **Language**: English only (code, comments, commits)
- **Lint names**: snake_case (`use_class_suffix`, `prefer_align_over_container`)
- **Rule classes**: PascalCase (`UseClassSuffix`, `PreferCenterOverAlign`)
- **Fix classes**: PascalCase with Fix suffix (`PreferCenterOverAlignFix`)
- **Type checking**: Use `TypeChecker.fromName()` or `TypeChecker.fromUrl()`
- **Pattern matching**: Dart 3.0+ patterns for AST analysis
- **SDK**: Dart ^3.11.0, analyzer ^14.1.0

## Key Helpers

### 📂 Quick References (For Understanding Existing Code)

- **[lib/src/rules/AGENTS.md](lib/src/rules/AGENTS.md)** - Lint rules quick reference
- **[lib/src/fixes/AGENTS.md](lib/src/fixes/AGENTS.md)** - Quick fixes quick reference
- **[lib/src/assists/AGENTS.md](lib/src/assists/AGENTS.md)** - Code assists quick reference

### 🔧 Utility Files

- `lib/src/type_checker.dart` - Type matching utilities
- `lib/src/type_inference.dart` - Context type inference (inferContextType, resolveReturnType, etc.)
- `lib/src/class_affix_validator.dart` - Base class for configurable class prefix/suffix rules
- `lib/src/text_distance.dart` - Levenshtein edit distance
- `lib/src/hook_detection.dart` - Hook widget detection helpers
- `lib/src/ast_node_analysis.dart` - AST node analysis helpers (enclosingClassDeclaration, hasOverrideAnnotation, negateExpression, buildEveryReplacement)
- `lib/src/constant_expression.dart` - Constant expression and identifier checking (isConstantExpression, isConstantIdentifier)
- `lib/src/disposal_utils.dart` - Shared disposal helpers (findCleanupMethod, cleanupMethods)
- `lib/src/dispose_method_editing.dart` - Insert a statement into an existing `dispose()` or generate the whole override (shared by dispose_fields_fix + always_remove_listener_fix)
- `lib/src/flutter_widget_helpers.dart` - Flutter widget helpers (FlexAxis enum for spacing rules)
- `lib/src/riverpod_type_checkers.dart` - Shared Riverpod TypeChecker constants (notifierChecker, consumerWidgetChecker, consumerStateChecker, consumerChecker, ...)
- `lib/src/flutter_type_checkers.dart` - Shared Flutter widget TypeChecker constants (buildContextChecker, containerChecker, sizedBoxChecker, anyFlexChecker, ...)
- `lib/src/bloc_type_checkers.dart` - Shared Bloc TypeChecker constants. `blocBaseChecker` (the real `BlocBase`) and `blocOrCubitChecker` (`Bloc|Cubit`) are deliberately distinct
- `lib/src/hook_type_checkers.dart` - `hookWidgetChecker` (is a hook *widget*) vs `hookScopeChecker` (may a hook be called here — adds `HookState`)
- `lib/src/fpdart_type_checkers.dart` - Shared fpdart TypeChecker constants. Each pins the **declaring** library (`package:fpdart/src/task_either.dart#TaskEither`), never the `fpdart.dart` barrel — `fromUrl` matches where a type is declared, not where it was imported from. `lazyFpdartChecker` (Task/TaskEither/IO/IOEither/TaskOption/IOOption) deliberately excludes `Either`/`Option`: those are already-computed values, so discarding one wastes a result but skips no effect
- `lib/src/fpdart_do_notation.dart` - `DoInvocation.tryRead()` + `DoBodyVisitor`, shared by the four Do-notation rules. `Do` resolves to an **`InstanceCreationExpression`** (a named constructor), even though it *parses* as a `MethodInvocation`; `$` is an ordinary formal parameter, so rules read its declared name rather than hardcoding `$`, and a `$(...)` call is a `FunctionExpressionInvocation` when resolved. `DoBodyVisitor` stops at a nested `Do` so one mistake is not reported once per enclosing level
- `lib/src/declaration_group.dart` - `readDeclarationGroups()` + `DeclarationKind`/`DeclarationGroup`. Backs `prefer_single_declaration_per_file`, which subsumes the general *and* Riverpod-specific \"single X per file\" cases: each configured group holds its own one-per-file budget, so one bloc plus one notifier passes. Flat `kinds:`/`types:` are read as the groups' defaults; a declaration counts in the **first** matching group only
- `lib/src/state_class_pairing.dart` - `findStateClassFor()` matches a StatefulWidget to its State via the `extends State<Widget>` type argument
- `lib/src/set_state_collection.dart` - `SetStateCollector`, shared by the prefer_single_setstate rule and its fix
- `lib/src/async_guard_utils.dart` - Async helpers (containsAwait, isMountedGuardWithReturn)
- `lib/src/async_builder_utils.dart` - Detect newly allocated Future/Stream sources passed to async builders
