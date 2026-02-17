---
name: new-lint
description: Creates a new lint rule with quick fix and tests for the many_lints package. Use when the user wants to add a new lint rule.
---

You are creating a new lint rule for the **many_lints** Dart linter package. The user will provide context describing what the lint should detect, possibly a lint name, and optionally reference links.

## Step 1: Parse the user's input

Extract from the `$ARGUMENTS`:
- **Lint name** (snake_case) — if not provided, derive one from the description
- **Description** — what the lint should detect/warn about
- **Reference links** — any URLs for documentation or examples

## Step 2: Research

Before writing any code:

1. **📖 ALWAYS START HERE: Read the Lint Rule Cookbooks** (in this directory)
   - [rules-patterns.md](rules-patterns.md) — Rule structure, type checking, AST navigation, visitors, reporting, utilities, analyzer APIs
   - [rules-recipes.md](rules-recipes.md) — 15+ copy-paste ready recipes for common scenarios, testing, registration
   - These are your **primary reference** for all implementation patterns
   - **Check the cookbooks FIRST** before researching elsewhere

2. Read these reference docs to understand the framework:
   - [Writing a plugin](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md)
   - [Writing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md)
   - [Testing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md)
   - [Writing assists](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md)

3. Read any reference links the user provided in `$ARGUMENTS`.

4. If the cookbook doesn't cover your specific pattern, read 1-2 existing rules in `lib/src/rules/` and their corresponding fixes in `lib/src/fixes/` and tests in `test/` to understand the codebase patterns. Pick rules that are most similar to the new lint being created.

5. Read `lib/src/type_checker.dart` and `lib/src/ast_node_analysis.dart` for reusable utilities.

## Step 3: Ask clarifying questions

Before implementing, use `AskUserQuestion` to clarify:
- What specific AST nodes/patterns should trigger the lint?
- What should the quick fix do exactly? (e.g., replace widget, rename, remove argument)
- Are there edge cases to consider? (e.g., const constructors, nested expressions, generics)
- Does the lint need to check types from a specific package? (determines TypeChecker usage)

Only ask questions that aren't already answered by the user's input.

## Step 4: Create the lint rule

Create `lib/src/rules/<lint_name>.dart` following this exact pattern:

```dart
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

// Add if needed:
// import 'package:many_lints/src/type_checker.dart';
// import 'package:many_lints/src/ast_node_analysis.dart';

/// <doc comment describing what the rule does>
class <RuleClass> extends AnalysisRule {
  static const LintCode code = LintCode(
    '<lint_name>',
    '<problem message describing what is wrong>',
    // Optional: correctionMessage: '<suggestion for how to fix>',
  );

  <RuleClass>()
      : super(
          name: '<lint_name>',
          description: '<short description>',
        );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    // Register for the appropriate AST node type, e.g.:
    // registry.addInstanceCreationExpression(this, visitor);
    // registry.addClassDeclaration(this, visitor);
    // registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final <RuleClass> rule;

  _Visitor(this.rule);

  // Use TypeChecker for type checks:
  // static const _checker = TypeChecker.fromName('WidgetName', packageName: 'flutter');

  @override
  void visit<NodeType>(<NodeType> node) {
    // Detection logic here
    // Report with: rule.reportAtNode(node) or rule.reportAtToken(node.name)
  }
}
```

Key conventions:
- Rule class name: PascalCase version of lint name (e.g., `use_cubit_suffix` -> `UseCubitSuffix`)
- Use `TypeChecker.fromName()` or `TypeChecker.fromUrl()` for type checks
- Use Dart 3.0+ pattern matching for AST analysis
- Use helpers from `lib/src/ast_node_analysis.dart` when applicable

## Step 5: Create the quick fix

**📖 Consult the Quick Fix Cookbook:** See [fixes-cookbook.md](fixes-cookbook.md) for comprehensive patterns and examples.

Create `lib/src/fixes/<lint_name>_fix.dart` following this exact pattern:

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that <description of what the fix does>.
class <FixClass> extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.<lintNameCamelCase>',
    DartFixKindPriority.standard,
    '<Short description of the fix action>',
  );

  <FixClass>({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Access the reported node:
    final targetNode = node;
    // Navigate to the relevant AST node
    // Apply fix using builder.addDartFileEdit(file, (builder) { ... });
  }
}
```

Key conventions:
- Fix class name: PascalCase rule name + `Fix` suffix (e.g., `PreferCenterOverAlignFix`)
- FixKind ID: `many_lints.fix.<lintNameInCamelCase>`
- Use `range.node()` for replacing nodes, `range.nodeInList()` for removing from argument lists
- Use `addSimpleReplacement()` for simple text replacements
- Use `addDeletion()` for removing code

## Step 6: Register in main.dart

Edit `lib/main.dart`:

1. Add imports for the new rule and fix
2. Add `registry.registerWarningRule(<RuleClass>());` in the rules section
3. Add `registry.registerFixForRule(<RuleClass>.code, <FixClass>.new);` in the fixes section

## Step 7: Create tests

Create `test/<lint_name>_test.dart` following this exact pattern:

```dart
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/<lint_name>.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(<RuleClass>Test));
}

@reflectiveTest
class <RuleClass>Test extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = <RuleClass>();
    // Mock external packages if needed:
    // newPackage('package_name').addFile('lib/file.dart', r'''
    //   class SomeClass {}
    // ''');
    super.setUp();
  }

  // Test cases that SHOULD trigger the lint:
  Future<void> test_<descriptive_case_name>() async {
    await assertDiagnostics(
      r'''
<code that should trigger the lint>
''',
      [lint(<offset>, <length>)],
    );
  }

  // Test cases that should NOT trigger the lint:
  Future<void> test_<descriptive_valid_case>() async {
    await assertNoDiagnostics(r'''
<code that should not trigger the lint>
''');
  }
}
```

Key conventions:
- Test class name: `<RuleClass>Test`
- Use `assertDiagnostics(code, [lint(offset, length)])` for code that triggers the lint
- Use `assertNoDiagnostics(code)` for code that should NOT trigger the lint
- Use `newPackage('name').addFile()` to mock external package dependencies
- Include at least: 2 positive cases (triggers lint), 2 negative cases (no lint), 1 edge case
- `lint(offset, length)` — offset is the character position, length is the length of the reported node/token
- Method names start with `test_` and use camelCase

## Step 8: Update the Cookbooks (MANDATORY when discovering new patterns)

**🚨 CRITICAL: If you discovered or researched any new patterns, you MUST update the cookbooks before completing this task.**

You must update if you:
- ✅ Discovered a new analyzer API pattern (e.g., different way to access elements, types, or AST nodes)
- ✅ Researched AST traversal techniques not shown in the cookbook
- ✅ Found a new type checking method or TypeChecker usage pattern
- ✅ Implemented a complex visitor pattern for deep analysis
- ✅ Created a new helper utility function
- ✅ Had to dig into analyzer source code or documentation for APIs not covered in the cookbook
- ✅ Found analyzer ^10.0.2 specific behaviors different from what you "know" from training data

**How to update (two places):**

1. **Full details** — Add to the appropriate cookbook file in this directory:
   - [rules-patterns.md](rules-patterns.md) for foundational patterns (type checking, AST, visitors, etc.)
   - [rules-recipes.md](rules-recipes.md) for new recipes (specific use-case patterns)
   - [fixes-cookbook.md](fixes-cookbook.md) for fix-related patterns
   - Follow the format in each file's Meta-Instructions section

2. **Brief mention** — Add a short entry to the lean quick reference at `lib/src/rules/CLAUDE.md` (or `lib/src/fixes/CLAUDE.md` for fix patterns)

This keeps the cookbooks as **living documents** that improve with each new rule!

## Step 9: Create an example file

Create `example/lib/<lint_name>_example.dart` to demonstrate the lint rule. Look at existing example files in `example/lib/` for the pattern.

The example file should include:
- A file-level `// ignore_for_file: unused_local_variable` (or similar) to suppress unrelated warnings
- A comment header with the lint name and brief description
- **Bad examples** (code that triggers the lint) with `// LINT:` comments explaining each case
- **Good examples** (correct code that does NOT trigger the lint)
- **Edge cases** where the lint intentionally does NOT trigger (e.g., when `.from()` is needed for downcasting)

Example structure:
```dart
// ignore_for_file: unused_local_variable

// <lint_name>
//
// Brief description of what the lint detects.

// ❌ Bad: Description of bad pattern
class BadExamples {
  void example() {
    // LINT: Explanation of why this triggers
    final x = badCode();
  }
}

// ✅ Good: Description of correct pattern
class GoodExamples {
  void example() {
    final x = goodCode();
  }
}
```

## Step 10: Verify

Run the following commands from the project root to ensure everything works:

1. `dart analyze` - Ensure there are **no issues at all** (errors, warnings, or infos). Fix any that appear before proceeding.
2. `dart test` - Ensure all tests pass

If either command fails or reports issues, fix them and re-run until both are fully clean.
