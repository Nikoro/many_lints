# Contributing to many_lints

Thanks for your interest in contributing! This guide will help you get started.

## Setup

1. Clone the repository:

```sh
git clone https://github.com/Nikoro/many_lints.git
cd many_lints
```

2. Install dependencies:

```sh
dart pub get
```

3. Verify everything works:

```sh
dart analyze
dart test
```

## Adding a New Lint Rule

The easiest way to add a new rule is using the `/new-lint` skill in Claude Code, which guides you step by step.

### Manual steps

1. **Create the rule** in `lib/src/rules/<rule_name>.dart`
   - Extend `AnalysisRule`
   - Define a static `LintCode` with `name`, `problemMessage`, and `correctionMessage`
   - Implement `registerNodeProcessors()` to register visitors
   - Create a `_Visitor` extending `SimpleAstVisitor`

2. **Register the rule** in `lib/many_lints.dart` via `registry.registerWarningRule()`

3. **Create tests** in `test/<rule_name>_test.dart` using the `analyzer_testing` framework

4. **Optionally add a quick fix** in `lib/src/fixes/<rule_name>_fix.dart`
   - Extend `ResolvedCorrectionProducer`
   - Register with `registry.registerFixForRule()` in `lib/many_lints.dart`

5. **Add an example** in `example/lib/<rule_name>_example.dart`

6. **Update documentation**:
   - Add the rule to `README.md` (Available Lints section)
   - Add the rule to `example/README.md` (All Rules table)
   - Add to `CHANGELOG.md` under `[Unreleased]`

## Running Tests

```sh
dart test                          # Run all tests
dart test test/<rule_name>_test.dart  # Run a specific test file
dart test --fail-fast              # Stop on first failure
```

## Code Style

- Run `dart format .` before committing
- Run `dart analyze` and fix any issues
- Use English for all code, comments, and commit messages
- Follow existing naming conventions (snake_case for rules, PascalCase for classes)

## Commit Messages

Use conventional commit format:

```
feat(lint): add <rule_name> rule with quick fix
fix(lint): handle edge case in <rule_name>
refactor: extract shared utility for <description>
docs: update README with new rules
```

## Project Structure

```
lib/
  many_lints.dart         # Plugin entry point — register all rules here
  src/
    rules/                # Lint rules
    fixes/                # Quick fixes
    assists/              # Code assists
    type_checker.dart     # Type matching utilities
    type_inference.dart   # Context type inference
test/                     # Test files
example/lib/              # Example files demonstrating each rule
```
