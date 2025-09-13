---
name: new-lint
description: Creates a new lint rule with quick fix and tests for the many_lints package. Use when the user wants to add a new lint rule.
user_invocable: true
---

You are creating a new lint rule for the **many_lints** Dart linter package. The user will provide context describing what the lint should detect, possibly a lint name, and optionally reference links.

## Step 1: Parse the user's input

Extract from the `$ARGUMENTS`:
- **Lint name** (snake_case) — if not provided, derive one from the description
- **Description** — what the lint should detect/warn about
- **Reference links** — any URLs for documentation or examples

## Step 2: Research

Before writing any code:

1. Read these reference docs to understand the framework:
   - [Writing a plugin](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md)
   - [Writing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md)
   - [Testing rules](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md)
   - [Writing assists](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md)

2. Read any reference links the user provided in `$ARGUMENTS`.

3. Read 1-2 existing rules in `lib/src/rules/` and their corresponding fixes in `lib/src/fixes/` and tests in `test/` to understand the codebase patterns. Pick rules that are most similar to the new lint being created.

4. Read `lib/src/type_checker.dart` and `lib/src/utils/helpers.dart` for reusable utilities.

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
// import 'package:many_lints/src/utils/helpers.dart';

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
- Use helpers from `lib/src/utils/helpers.dart` when applicable

## Step 5: Create the quick fix

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

## Step 8: Verify

Run `dart test` from the project root to ensure all tests pass. If tests fail, fix the issues and re-run.
