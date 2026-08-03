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
    class_suffix_validator.dart # Base class for suffix naming rules
    text_distance.dart    # String distance utilities (Levenshtein)
    hook_detection.dart   # Hook widget detection helpers
    ast_node_analysis.dart # AST node analysis helpers
    constant_expression.dart # Constant expression/identifier checking helpers
    disposal_utils.dart   # Shared disposal helpers (findCleanupMethod, cleanupMethods)
    flutter_widget_helpers.dart # Flutter widget helpers (FlexAxis enum)
    riverpod_type_checkers.dart # Shared Riverpod TypeChecker constants
    async_guard_utils.dart # Async helpers (containsAwait, isMountedGuardWithReturn)
    rules/                # Lint rules (AnalysisRule + SimpleAstVisitor pattern)
    fixes/                # Quick fixes (ResolvedCorrectionProducer pattern)
    assists/              # Code assists (ResolvedCorrectionProducer pattern)
test/
  *.dart                  # Test files (analyzer_testing pattern)
docs/                     # Astro Starlight docs site (see docs/CLAUDE.md)
```

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

- [Rules patterns](.claude/skills/new-lint/rules-patterns.md) - Rule structure, type checking, AST, visitors, reporting
- [Rules recipes](.claude/skills/new-lint/rules-recipes.md) - Copy-paste recipes for common patterns
- [Fixes cookbook](.claude/skills/new-lint/fixes-cookbook.md) - Quick fix implementation patterns
- [Assists cookbook](.claude/skills/new-lint/assists-cookbook.md) - Code assist implementation patterns

Quick summary:

1. Create `lib/src/rules/<rule_name>.dart`
2. Extend `AnalysisRule`, define a static `LintCode` with `name`, `problemMessage`, `correctionMessage`
3. Implement `registerNodeProcessors()` to register visitors via `RuleVisitorRegistry`
4. Create `_Visitor` extending `SimpleAstVisitor`, report issues with `rule.reportAtNode()`
5. Register the rule in `lib/many_lints.dart` via `registry.registerWarningRule()`
6. Optionally create a fix in `lib/src/fixes/` extending `ResolvedCorrectionProducer`
7. Create `test/<rule_name>_test.dart` using `analyzer_testing` patterns
8. Create a documentation page in `docs/src/content/docs/docs/rules/<category>/`
9. Create `example/lib/<lint_name>_example.dart` with bad/good/edge-case examples

## Code Conventions

- **Language**: English only (code, comments, commits)
- **Lint names**: snake_case (`use_cubit_suffix`, `prefer_align_over_container`)
- **Rule classes**: PascalCase (`UseCubitSuffix`, `PreferCenterOverAlign`)
- **Fix classes**: PascalCase with Fix suffix (`PreferCenterOverAlignFix`)
- **Type checking**: Use `TypeChecker.fromName()` or `TypeChecker.fromUrl()`
- **Pattern matching**: Dart 3.0+ patterns for AST analysis
- **SDK**: Dart ^3.11.0, analyzer ^14.1.0

## Key Helpers

### 📂 Quick References (For Understanding Existing Code)

- **[lib/src/rules/CLAUDE.md](lib/src/rules/CLAUDE.md)** - Lint rules quick reference
- **[lib/src/fixes/CLAUDE.md](lib/src/fixes/CLAUDE.md)** - Quick fixes quick reference
- **[lib/src/assists/CLAUDE.md](lib/src/assists/CLAUDE.md)** - Code assists quick reference

### 🔧 Utility Files

- `lib/src/type_checker.dart` - Type matching utilities
- `lib/src/type_inference.dart` - Context type inference (inferContextType, resolveReturnType, etc.)
- `lib/src/class_suffix_validator.dart` - Base class for suffix naming rules
- `lib/src/text_distance.dart` - Levenshtein edit distance
- `lib/src/hook_detection.dart` - Hook widget detection helpers
- `lib/src/ast_node_analysis.dart` - AST node analysis helpers (enclosingClassDeclaration, hasOverrideAnnotation, negateExpression, buildEveryReplacement)
- `lib/src/constant_expression.dart` - Constant expression and identifier checking (isConstantExpression, isConstantIdentifier)
- `lib/src/disposal_utils.dart` - Shared disposal helpers (findCleanupMethod, cleanupMethods)
- `lib/src/flutter_widget_helpers.dart` - Flutter widget helpers (FlexAxis enum for spacing rules)
- `lib/src/riverpod_type_checkers.dart` - Shared Riverpod TypeChecker constants (notifierChecker)
- `lib/src/async_guard_utils.dart` - Async helpers (containsAwait, isMountedGuardWithReturn)
