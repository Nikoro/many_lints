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
dart format --output=none --set-exit-if-changed .
dart analyze
dart run tool/verify_examples.dart
dart test
cd docs && bun install && bun run build
```

## Adding a New Lint Rule

The easiest way to add a rule is to use the repository's `/new-lint` skill,
which follows the current registration, configuration, test, documentation,
and example conventions.

Before implementing a rule, read the official SDK guides for
[writing plugins](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md),
[writing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md),
and [testing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md).

### Manual steps

1. **Create the rule** in `lib/src/rules/<rule_name>.dart`
   - Extend `ManyLintsRule`
   - Define a static `LintCode` with `name`, `problemMessage`, and `correctionMessage`
   - Implement `registerManyLintsProcessors()` to register visitors
   - Create a `_Visitor` extending `SimpleAstVisitor`

2. **Register the rule** in `lib/many_lints.dart` through
   `_registerWarningRule(registry, ...)`. The wrapper records rule names and
   keeps preset/configuration checks enforceable.

3. **Assign the rule to a preset** in `lib/src/presets.dart`. Registration does
   not enable a rule: choose `core`, `recommended`, `opinionated`, `pedantic`,
   or deliberately leave it opt-in.

4. **Create tests** in `test/<rule_name>_test.dart` by extending
   `ManyLintsRuleTest` from `test/many_lints_rule_test_base.dart`.

5. **Optionally add a quick fix** in `lib/src/fixes/<rule_name>_fix.dart`
   - Extend `ResolvedCorrectionProducer`
   - Register with `registry.registerFixForRule()` in `lib/many_lints.dart`
   - Add an end-to-end output case under `test/fix_output/`

6. **Add an example** in `example/lib/<rule_name>_example.dart`. Include bad,
   good, and important edge-case examples, then run
   `dart run tool/verify_examples.dart`.

7. **Add a rule page** under
   `docs/src/content/docs/docs/rules/<category>/`, including its preset,
   examples, quick-fix behavior, options, and useful official Dart or Flutter
   references.

8. **Refresh generated catalogs** with `cd docs && bun run catalogs`. Update
   `CHANGELOG.md` under `[Unreleased]` and review any README count changes
   reported by `test/plugin_registration_test.dart`.

## Running Tests

```sh
dart test                          # Run all tests
dart test test/<rule_name>_test.dart  # Run a specific test file
dart test --fail-fast              # Stop on first failure
dart run tool/verify_examples.dart # Verify every example triggers its rule
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
