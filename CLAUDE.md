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
    rules/                # Lint rules (AnalysisRule + SimpleAstVisitor pattern)
    fixes/                # Quick fixes (ResolvedCorrectionProducer pattern)
    assists/              # Code assists (ResolvedCorrectionProducer pattern)
    utils/                # Shared utilities (helpers.dart, hook_helpers.dart)
test/
  lib/                    # Test files (analyzer_testing pattern)
  pubspec.yaml            # Test project dependencies
```

## Reference Docs

Before writing any code:

1. Read these reference docs to understand the framework:
   - [Writing a plugin](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md)
   - [Writing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md)
   - [Testing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md)
   - [Writing assists](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md)

## Adding a New Lint Rule

**📖 Start with the Cookbooks:**
- [lib/src/rules/CLAUDE.md](lib/src/rules/CLAUDE.md) - Lint rule patterns
- [lib/src/fixes/CLAUDE.md](lib/src/fixes/CLAUDE.md) - Quick fix patterns
- [lib/src/assists/CLAUDE.md](lib/src/assists/CLAUDE.md) - Code assist patterns

See [`.claude/skills/new-lint/SKILL.md`](.claude/skills/new-lint/SKILL.md) for the full step-by-step guide, or use the `/new-lint` skill.

Quick summary:

1. **Consult the cookbooks** for copy-paste ready patterns
2. Create `lib/src/rules/<rule_name>.dart`
3. Extend `AnalysisRule`, define a static `LintCode` with `name`, `problemMessage`, `correctionMessage`
4. Implement `registerNodeProcessors()` to register visitors via `RuleVisitorRegistry`
5. Create `_Visitor` extending `SimpleAstVisitor`, report issues with `rule.reportAtNode()`
6. Register the rule in `lib/main.dart` via `registry.registerWarningRule()`
7. Optionally create a fix in `lib/src/fixes/` extending `ResolvedCorrectionProducer`
8. Create `test/<rule_name>_test.dart` using `analyzer_testing` patterns

## Test Pattern

Tests use `analyzer_testing` with reflective loader:

```dart
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MyRuleTest));
}

@reflectiveTest
class MyRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MyRule();
    super.setUp();
  }

  void test_case() async {
    await assertDiagnostics(r'''
      // code that triggers lint
    ''', [lint(offset, length)]);
  }
}
```

## Code Conventions

- **Language**: English only (code, comments, commits)
- **Lint names**: snake_case (`use_cubit_suffix`, `prefer_align_over_container`)
- **Rule classes**: PascalCase (`UseCubitSuffix`, `PreferCenterOverAlign`)
- **Fix classes**: PascalCase with Fix suffix (`PreferCenterOverAlignFix`)
- **Type checking**: Use `TypeChecker.fromName()` or `TypeChecker.fromUrl()`
- **Pattern matching**: Dart 3.0+ patterns for AST analysis
- **SDK**: Dart ^3.10.0

## Key Helpers

### 📖 Implementation Cookbooks (Start Here!)

- **[lib/src/rules/CLAUDE.md](lib/src/rules/CLAUDE.md)** - Lint Rule Implementation Cookbook
- **[lib/src/fixes/CLAUDE.md](lib/src/fixes/CLAUDE.md)** - Quick Fix Implementation Cookbook
- **[lib/src/assists/CLAUDE.md](lib/src/assists/CLAUDE.md)** - Code Assist Implementation Cookbook

### 🔧 Utility Files

- `lib/src/type_checker.dart` - Type matching utilities
- `lib/src/utils/helpers.dart` - AST helpers, expression checking
- `lib/src/utils/hook_helpers.dart` - Hook widget detection

## Git Operations

**IMPORTANT**: Do NOT use GitHub or GitKraken MCP servers for git operations. Use standard git CLI commands directly.

### Conventional Commits

All commit messages **MUST** follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>
```

#### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Formatting, whitespace (no code meaning changes)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or correcting tests
- **build**: Build system or dependency changes
- **ci**: CI configuration changes
- **chore**: Other changes (not src or test)
- **revert**: Reverts a previous commit

#### Rules

- Use imperative mood ("add" not "added" or "adds")
- Don't capitalize the first letter
- No period at the end
- Scope is optional but encouraged: `feat(auth): add OAuth2 authentication`
- Breaking changes: add `!` after type/scope and `BREAKING CHANGE:` in footer

#### Examples

```
feat(lints): add prefer_const_constructor rule
fix: correct AST visitor for nested widgets
refactor(helpers): simplify type checker logic
test: add coverage for hook widget detection
```

#### What to Avoid

- References to AI models (Claude, GPT, etc.)
- "Generated with Claude Code" or similar branding
- Co-authored-by attributions to AI assistants
- Vague descriptions like "updates", "changes", "fixes"
- Emoji in commit messages
