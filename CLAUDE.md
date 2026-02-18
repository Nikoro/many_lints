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
    rules/                # Lint rules (AnalysisRule + SimpleAstVisitor pattern)
    fixes/                # Quick fixes (ResolvedCorrectionProducer pattern)
    assists/              # Code assists (ResolvedCorrectionProducer pattern)
test/
  *.dart                  # Test files (analyzer_testing pattern)
```

## Reference Docs

Before writing any code:

1. Read these reference docs to understand the framework:
   - [Writing a plugin](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md)
   - [Writing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md)
   - [Testing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md)
   - [Writing assists](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md)

## Adding a New Lint Rule

**Use the `/new-lint` skill** for step-by-step guidance, or see the full cookbooks:

- [Rules patterns](.claude/skills/new-lint/rules-patterns.md) - Rule structure, type checking, AST, visitors, reporting
- [Rules recipes](.claude/skills/new-lint/rules-recipes.md) - 30+ copy-paste recipes for common patterns
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

## Code Conventions

- **Language**: English only (code, comments, commits)
- **Lint names**: snake_case (`use_cubit_suffix`, `prefer_align_over_container`)
- **Rule classes**: PascalCase (`UseCubitSuffix`, `PreferCenterOverAlign`)
- **Fix classes**: PascalCase with Fix suffix (`PreferCenterOverAlignFix`)
- **Type checking**: Use `TypeChecker.fromName()` or `TypeChecker.fromUrl()`
- **Pattern matching**: Dart 3.0+ patterns for AST analysis
- **SDK**: Dart ^3.10.0

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
- `lib/src/ast_node_analysis.dart` - AST node analysis helpers
- `lib/src/constant_expression.dart` - Constant expression and identifier checking (isConstantExpression, isConstantIdentifier)
