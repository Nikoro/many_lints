# Quick Fix Implementation Cookbook

## About This Document

This cookbook provides **copy-paste ready patterns** for implementing quick fixes in the `many_lints` package using **analyzer ^10.0.2**. Quick fixes are code actions that resolve lint diagnostics automatically.

**Target Audience:** AI agents and developers implementing quick fixes for lint rules
**Analyzer Version:** ^10.0.2
**Last Updated:** February 2026

---

## META-INSTRUCTIONS FOR AGENTS

### When to Update This Cookbook

**You MUST update this cookbook when:**
- You discover a new ChangeBuilder API pattern not documented here
- You find a new range factory usage pattern
- You implement a complex multi-edit transformation
- You discover analyzer ^10.0.2 specific fix behaviors
- You create a new helper method that could benefit other fixes
- You find better ways to preserve formatting or handle edge cases

### What to Document

When updating, add:
- **Working code example** (tested and verified)
- **File reference** to your implementation (e.g., `[my_fix.dart](../../../lib/src/fixes/my_fix.dart#L10-L20)`)
- **Brief explanation** of when to use this pattern
- **Common pitfalls** if any

### How to Update

1. Find the appropriate section (or create new section if needed)
2. Add your pattern following existing format
3. Include file references with line numbers
4. Update the Pattern Index if adding new sections
5. Also update the lean quick reference at `lib/src/fixes/CLAUDE.md` with a brief mention when discovering new patterns

---

## Pattern Index

Quick navigation:

- [Standard Fix Structure](#standard-fix-structure)
- [Accessing Diagnostic Nodes](#accessing-diagnostic-nodes)
- [Range Factory Patterns](#range-factory-patterns)
- [ChangeBuilder Patterns](#changebuilder-patterns)
- [Node Navigation](#node-navigation-techniques)
- [Preserving Formatting](#preserving-formatting--indentation)
- [Complex Transformations](#complex-transformation-patterns)
- [Helper Utilities](#helper-utilities)
- [Common Gotchas](#common-gotchas--edge-cases)
- [Registration](#registration)

---

## Standard Fix Structure

### Pattern 1: Simple Single-Purpose Fix (Most Common)

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that [brief description of what it does].
class MyFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.myFix',               // Unique ID (camelCase)
    DartFixKindPriority.standard,          // Priority level
    'Human-readable action description',   // User-facing message
  );

  MyFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ExpectedType) return;

    // Validation and navigation
    // ...

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), 'replacement');
    });
  }
}
```

**When to use:** 95% of fixes - one fix for one specific lint rule
**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L11-L54), [prefer_explicit_function_type_fix.dart](../../../lib/src/fixes/prefer_explicit_function_type_fix.dart#L8-L37)

---

### Pattern 2: Multi-Factory Fix (Shared Logic)

Use when multiple lint rules need similar fixes with different parameters:

```dart
class AddSuffixFix extends ResolvedCorrectionProducer {
  final String suffix;
  final FixKind _fixKind;

  AddSuffixFix._({
    required super.context,
    required this.suffix,
    required FixKind fixKind,
  }) : _fixKind = fixKind;

  // Factory for Bloc suffix
  static AddSuffixFix blocFix({required CorrectionProducerContext context}) {
    return AddSuffixFix._(
      context: context,
      suffix: 'Bloc',
      fixKind: FixKind(
        'many_lints.fix.addBlocSuffix',
        DartFixKindPriority.standard,
        'Add Bloc suffix',
      ),
    );
  }

  // Factory for Cubit suffix
  static AddSuffixFix cubitFix({required CorrectionProducerContext context}) {
    return AddSuffixFix._(
      context: context,
      suffix: 'Cubit',
      fixKind: FixKind(
        'many_lints.fix.addCubitSuffix',
        DartFixKindPriority.standard,
        'Add Cubit suffix',
      ),
    );
  }

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Shared fix logic using suffix parameter
  }
}
```

**When to use:** Multiple related lint rules with similar fix logic
**Reference:** [add_suffix_fix.dart](../../../lib/src/fixes/add_suffix_fix.dart#L8-L57) (Bloc, Cubit, Notifier), [change_widget_name_fix.dart](../../../lib/src/fixes/change_widget_name_fix.dart) (HookWidget, ConsumerWidget)

---

## FixKind Conventions

### Naming Pattern

**ID:** `'many_lints.fix.<camelCaseDescription>'`

```dart
// Good examples
'many_lints.fix.preferCenterOverAlign'
'many_lints.fix.addBlocSuffix'
'many_lints.fix.convertToSwitchExpression'
'many_lints.fix.useAnyInsteadOfWhereIsNotEmpty'
```

### Priority Levels

**All 15 existing fixes use `DartFixKindPriority.standard`:**

```dart
static const _fixKind = FixKind(
  'many_lints.fix.myFix',
  DartFixKindPriority.standard,  // <- This is the standard choice
  'Fix description',
);
```

**Available priorities:**
- `DartFixKindPriority.standard` - **Use this** (all existing fixes use it)
- `DartFixKindPriority.inFile` - Available but not used in codebase
- `DartFixKindPriority.automatic` - Available but not used in codebase

### Description

User-facing string, concise and action-oriented:

```dart
// Good examples
'Replace with Center'
'Add Bloc suffix'
'Convert to switch expression'
'Use any() instead of where().isNotEmpty'
'Replace SizedBox with Gap'

// Avoid
'Fix the issue'  // Too vague
'This will make the code better'  // Not action-oriented
```

---

## Accessing Diagnostic Nodes

The `node` property contains the AST node where the diagnostic was reported.

### Pattern 1: Direct Type Check

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  final targetNode = node;
  if (targetNode is! ConstructorName) return;

  // targetNode is now known to be ConstructorName
}
```

**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L30-L31), [use_gap_fix.dart](../../../lib/src/fixes/use_gap_fix.dart#L28-L29)

---

### Pattern 2: Parent Navigation

```dart
final targetNode = node;
if (targetNode is! SimpleIdentifier) return;

final classDecl = targetNode.parent;
if (classDecl is! ClassDeclaration) return;
```

**Reference:** [avoid_unnecessary_consumer_widgets_fix.dart](../../../lib/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart#L28-L32)

---

### Pattern 3: Navigate to Specific Parent

```dart
final targetNode = node;
if (targetNode is! ConstructorName) return;

final instanceCreation = targetNode.parent;
if (instanceCreation is! InstanceCreationExpression) return;
```

**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L33-L34)

---

### Pattern 4: Pattern Matching in Switch

```dart
final String? identifierName = switch (node) {
  PrefixedIdentifier(:final identifier) => identifier.name,
  PropertyAccess(:final propertyName) => propertyName.name,
  _ => null,
};

if (identifierName == null) return;
```

**When to use:** Node could be one of multiple types
**Reference:** [prefer_shorthands_with_enums_fix.dart](../../../lib/src/fixes/prefer_shorthands_with_enums_fix.dart#L28-L32)

---

## Range Factory Patterns

The `range` factory creates source ranges for edits. Import: `package:analyzer_plugin/utilities/range_factory.dart`

### range.node() - Replace Entire Node

**Most common pattern - used in all 15 fixes!**

```dart
builder.addSimpleReplacement(
  range.node(targetNode),
  'NewWidgetName',
);
```

**When to use:** Replacing a complete AST node
**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L43), [change_widget_name_fix.dart](../../../lib/src/fixes/change_widget_name_fix.dart#L39), [prefer_explicit_function_type_fix.dart](../../../lib/src/fixes/prefer_explicit_function_type_fix.dart#L33)

---

### range.nodeInList() - Remove from List

**Handles commas and formatting correctly:**

```dart
builder.addDeletion(
  range.nodeInList(
    instanceCreation.argumentList.arguments,
    alignmentArgument,
  ),
);
```

**When to use:** Removing a parameter/argument from a list
**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L46-L51), [avoid_unnecessary_consumer_widgets_fix.dart](../../../lib/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart#L59-L61)

---

### range.startStart() - Prefix Replacement

**Range from start of first node to start of second:**

```dart
builder.addSimpleReplacement(
  range.startStart(targetNode, parent.argumentList),
  'ReplacementPrefix.',
);
```

**When to use:** Replacing just the prefix of a node (before arguments)
**Reference:** [prefer_returning_shorthands_fix.dart](../../../lib/src/fixes/prefer_returning_shorthands_fix.dart#L39-L42), [prefer_shorthands_with_constructors_fix.dart](../../../lib/src/fixes/prefer_shorthands_with_constructors_fix.dart#L38-L41)

---

### Manual SourceRange (Rare)

```dart
import 'package:analyzer/source/source_range.dart';

builder.addSimpleReplacement(
  SourceRange(startOffset, length),
  'replacement',
);
```

**When to use:** Custom ranges not covered by range factory
**Reference:** Most fixes prefer range factory methods

---

## ChangeBuilder Patterns

All edits happen inside `builder.addDartFileEdit(file, (builder) { ... })`.

### Pattern 1: Simple Replacement (Most Common)

**Used in 13 of 15 fixes:**

```dart
await builder.addDartFileEdit(file, (builder) {
  builder.addSimpleReplacement(range.node(targetNode), 'NewText');
});
```

**Reference:** Nearly all fixes use this

---

### Pattern 2: Deletion

```dart
await builder.addDartFileEdit(file, (builder) {
  builder.addDeletion(range.nodeInList(list, item));
});
```

**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L46-L51)

---

### Pattern 3: Multiple Edits

```dart
await builder.addDartFileEdit(file, (builder) {
  // Edit 1: Replace widget name
  builder.addSimpleReplacement(
    range.node(superclass),
    'StatelessWidget',
  );

  // Edit 2: Remove unused parameter
  if (refParam != null && buildMethod != null) {
    builder.addDeletion(
      range.nodeInList(buildMethod.parameters!.parameters, refParam),
    );
  }
});
```

**When to use:** Fix requires multiple changes
**Reference:** [avoid_unnecessary_consumer_widgets_fix.dart](../../../lib/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart#L53-L64)

---

### Pattern 4: Cascade Notation

```dart
await builder.addDartFileEdit(file, (builder) {
  builder
    ..addSimpleReplacement(range.node(node1), 'text1')
    ..addSimpleReplacement(range.node(node2), 'text2');
});
```

**When to use:** Multiple independent edits
**Reference:** [prefer_padding_over_container_fix.dart](../../../lib/src/fixes/prefer_padding_over_container_fix.dart#L38-L44)

---

## Node Navigation Techniques

### Finding Named Arguments

```dart
import 'package:many_lints/src/ast_node_analysis.dart';

final alignmentArgument = instanceCreation.argumentList.arguments
    .whereType<NamedExpression>()
    .firstWhereOrNull((e) => e.name.label.name == 'alignment');

if (alignmentArgument == null) return;
```

**Uses `firstWhereOrNull` extension from helpers!**
**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L36-L39)

---

### Finding Class Members

```dart
final body = classDecl.body;
if (body is! BlockClassBody) return;

final buildMethod = body.members
    .whereType<MethodDeclaration>()
    .firstWhereOrNull((m) => m.name.lexeme == 'build');

if (buildMethod == null) return;
```

**Reference:** [avoid_unnecessary_consumer_widgets_fix.dart](../../../lib/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart#L48-L50)

---

### Finding Method Parameters

```dart
final parameters = buildMethod.parameters?.parameters;
if (parameters == null) return;

final refParam = parameters
    .whereType<SimpleFormalParameter>()
    .firstWhereOrNull((p) => p.name?.lexeme == 'ref');
```

**Reference:** [avoid_unnecessary_consumer_widgets_fix.dart](../../../lib/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart#L52-L58)

---

### Parent Chain Navigation

```dart
final parent = node.parent;
final grandparent = parent?.parent;

if (grandparent is PropertyAccess) {
  // Handle chained property access
}
```

**Reference:** [use_dedicated_media_query_methods_fix.dart](../../../lib/src/fixes/use_dedicated_media_query_methods_fix.dart#L45)

---

## Preserving Formatting & Indentation

### Use .toSource() for Existing Code

**Key insight:** Extract existing code with `.toSource()` to preserve user formatting:

```dart
final valueSource = spacingArg.expression.toSource();
final childSource = childArg.expression.toSource();

final replacement = 'Gap($valueSource), $childSource';
```

**Reference:** [use_gap_fix.dart](../../../lib/src/fixes/use_gap_fix.dart#L55)

---

### String Interpolation for Complex Builds

```dart
final expression = switchStmt.expression.toSource();
final cases = _buildCases(switchStmt);

final switchExpr = 'switch ($expression) {\n$cases}';
```

**Reference:** [prefer_switch_expression_fix.dart](../../../lib/src/fixes/prefer_switch_expression_fix.dart#L90-L91)

---

### Preserve Argument Lists

```dart
final contextVariableName = node.argumentList.arguments.firstOrNull?.toString();
return 'MediaQuery.$methodReplacement($contextVariableName)';
```

**Reference:** [use_dedicated_media_query_methods_fix.dart](../../../lib/src/fixes/use_dedicated_media_query_methods_fix.dart#L41-L48)

---

## Complex Transformation Patterns

### Pattern: Switch Statement -> Expression

Full transformation in [prefer_switch_expression_fix.dart](../../../lib/src/fixes/prefer_switch_expression_fix.dart#L59-L110):

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  // 1. Validate node type
  final switchNode = node.parent;
  if (switchNode is! SwitchStatement) return;

  // 2. Determine conversion type (return-based vs assignment-based)
  final builtExpression = _buildSwitchExpression(switchNode);
  if (builtExpression == null) return;

  // 3. Single replacement for entire statement
  await builder.addDartFileEdit(file, (builder) {
    builder.addSimpleReplacement(
      range.node(switchNode),
      builtExpression,
    );
  });
}

String? _buildSwitchExpression(SwitchStatement stmt) {
  final StringBuffer buffer = StringBuffer();

  // Iteratively build cases
  for (final member in stmt.members) {
    final caseExpr = _buildCaseExpression(member);
    if (caseExpr == null) return null;
    buffer.writeln(caseExpr);
  }

  return 'switch (${stmt.expression.toSource()}) {\n$buffer}';
}
```

**Key techniques:**
- Helper methods for readability
- StringBuffer for building complex output
- Early returns for validation

---

### Pattern: Widget Unwrapping

From [avoid_unnecessary_consumer_widgets_fix.dart](../../../lib/src/fixes/avoid_unnecessary_consumer_widgets_fix.dart):

```dart
// Step 1: Replace superclass
builder.addSimpleReplacement(
  range.node(superclass),
  'StatelessWidget',
);

// Step 2: Remove unused parameter
if (refParam != null) {
  builder.addDeletion(
    range.nodeInList(buildMethod.parameters!.parameters, refParam),
  );
}
```

**Two coordinated edits:**
1. Change widget type
2. Clean up parameters

---

### Pattern: Conditional Widget Transformation

From [use_gap_fix.dart](../../../lib/src/fixes/use_gap_fix.dart#L28-L105):

```dart
// Dispatch based on widget type
final typeName = element.name;

if (typeName == 'SizedBox') {
  await _fixSizedBox(builder, instanceCreation);
} else if (typeName == 'Padding') {
  await _fixPadding(builder, instanceCreation);
}

// Different argument structures need different handling
Future<void> _fixSizedBox(...) {
  final widthArg = findArg('width');
  final heightArg = findArg('height');
  // Logic specific to SizedBox
}

Future<void> _fixPadding(...) {
  final paddingArg = findArg('padding');
  // Logic specific to Padding
}
```

**Use helper methods for different transformation strategies**

---

## Helper Utilities

### From ast_node_analysis.dart

**Import:** `package:many_lints/src/ast_node_analysis.dart`

#### firstWhereOrNull - Safe Element Search

```dart
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test);
}

// Usage:
final arg = arguments
    .whereType<NamedExpression>()
    .firstWhereOrNull((e) => e.name.label.name == 'alignment');
```

**Used in 6 of 15 fixes!**
**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L36-L39)

---

#### isInstanceCreationExpressionOnlyUsingParameter

```dart
bool isInstanceCreationExpressionOnlyUsingParameter(
  InstanceCreationExpression node, {
  required String parameter,
  Set<String> ignoredParameters = const {},
})

// Usage:
if (isInstanceCreationExpressionOnlyUsingParameter(
  node,
  parameter: 'padding',
  ignoredParameters: {'key', 'child'},
)) {
  // Only 'padding' is set (key/child ignored)
}
```

**Reference:** [prefer_padding_over_container_fix.dart](../../../lib/src/fixes/prefer_padding_over_container_fix.dart)

---

#### maybeGetSingleReturnExpression

```dart
Expression? maybeGetSingleReturnExpression(FunctionBody body)

// Returns expression from:
// => expr
// { return expr; }
// Otherwise returns null
```

**Reference:** Used in various fixes

---

## Common Gotchas & Edge Cases

### Handling Nullable Types

```dart
final isNullable = targetNode.question != null;
final replacement = isNullable
    ? 'void Function()?'
    : 'void Function()';
```

**Reference:** [prefer_explicit_function_type_fix.dart](../../../lib/src/fixes/prefer_explicit_function_type_fix.dart#L30-L31)

---

### Conditional Formatting (Question Mark for Chaining)

```dart
final shouldAddQuestionMark = usedMaybe && node.parent?.parent is PropertyAccess;
final replacement = 'MediaQuery.$method($context)${shouldAddQuestionMark ? '?' : ''}';
```

**Reference:** [use_dedicated_media_query_methods_fix.dart](../../../lib/src/fixes/use_dedicated_media_query_methods_fix.dart#L45-L48)

---

### String Manipulation with Edit Distance

[add_suffix_fix.dart](../../../lib/src/fixes/add_suffix_fix.dart#L106-L132) includes Levenshtein distance to strip misspelled suffixes:

```dart
static int _editDistance(String a, String b) {
  // Dynamic programming algorithm
  final matrix = List.generate(
    a.length + 1,
    (i) => List.filled(b.length + 1, 0),
  );

  // ... implementation
}

// Usage: Remove "Blac" (misspelled "Bloc") before adding correct suffix
final distance = _editDistance(existingSuffix, correctSuffix);
if (distance <= threshold) {
  // Strip and replace
}
```

---

### Early Returns for Validation

**Every fix uses this pattern:**

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  // Validate step 1
  final targetNode = node;
  if (targetNode is! ExpectedType) return;

  // Validate step 2
  final parent = targetNode.parent;
  if (parent is! ExpectedParent) return;

  // Validate step 3
  final argument = findArgument('name');
  if (argument == null) return;

  // All validations passed - apply fix
  await builder.addDartFileEdit(...);
}
```

**Clean and readable!**

---

### Extract Helper Methods

For complex logic, use private helper methods:

```dart
String? _buildSwitchExpression(SwitchStatement stmt) { ... }
String? _buildCaseExpression(SwitchMember member) { ... }
Future<void> _fixSizedBox(...) { ... }
Future<void> _fixPadding(...) { ... }
```

**Reference:** [prefer_switch_expression_fix.dart](../../../lib/src/fixes/prefer_switch_expression_fix.dart), [use_gap_fix.dart](../../../lib/src/fixes/use_gap_fix.dart)

---

## Registration

### In lib/many_lints.dart

```dart
import 'package:many_lints/src/rules/my_rule.dart';
import 'package:many_lints/src/fixes/my_rule_fix.dart';

class ManyLintsPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    // Register the rule
    registry.registerWarningRule(MyRule());

    // Register fix for the rule's LintCode
    registry.registerFixForRule(MyRule.code, MyRuleFix.new);
  }
}
```

**Note:** Use `.new` tear-off syntax for constructor reference

---

## Pattern Distribution (15 Fixes)

| Pattern | Usage | Files |
|---------|-------|-------|
| `addSimpleReplacement` | 15/15 | All fixes |
| `range.node()` | 15/15 | All fixes |
| `CorrectionApplicability.singleLocation` | 15/15 | All fixes |
| `DartFixKindPriority.standard` | 15/15 | All fixes |
| `firstWhereOrNull` | 6/15 | Common for finding args/members |
| `addDeletion` | 2/15 | Removing parameters |
| `range.nodeInList()` | 2/15 | List deletions |
| `range.startStart()` | 2/15 | Prefix replacements |
| Factory pattern | 2/15 | Shared logic across rules |
| Helper methods | 3/15 | Complex transformations |

---

## Quick Fix Implementation Checklist

1. Import standard packages (analysis_server_plugin, analyzer, analyzer_plugin)
2. Import helpers if using firstWhereOrNull or other utilities
3. Extend `ResolvedCorrectionProducer`
4. Define `static const _fixKind` with:
   - ID: `'many_lints.fix.<camelCase>'`
   - Priority: `DartFixKindPriority.standard`
   - Description: Action-oriented user message
5. Constructor: `MyFix({required super.context})`
6. Override `applicability` -> `CorrectionApplicability.singleLocation`
7. Override `fixKind` -> return `_fixKind`
8. Implement `compute(ChangeBuilder builder)`:
   - Get and validate target node
   - Navigate to needed nodes with early returns
   - Extract source with `.toSource()` when preserving formatting
   - Use `builder.addDartFileEdit(file, (builder) { ... })`
   - Use appropriate range + edit methods
9. Register in lib/many_lints.dart: `registerFixForRule(RuleCode, FixConstructor.new)`
10. Test manually (test infrastructure for fixes not yet established)

---

## Learning Path

**For new fix implementers:**

1. Read this cookbook
2. Study a simple fix: [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart)
3. Study a complex fix: [prefer_switch_expression_fix.dart](../../../lib/src/fixes/prefer_switch_expression_fix.dart)
4. Use templates from this cookbook
5. Remember to register in lib/many_lints.dart
6. Test manually in a test project
7. Update this cookbook if you discover new patterns!

---

## Changelog

| Date | Agent/Author | Changes |
|------|-------------|---------|
| Feb 2026 | Initial creation | Extracted patterns from 15 existing fixes |

**Remember:** When you discover new patterns, update this document following the [Meta-Instructions](#meta-instructions-for-agents).
