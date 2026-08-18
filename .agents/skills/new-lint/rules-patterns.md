# Lint Rule Implementation Cookbook — Patterns

## 📚 About This Document

This cookbook provides **copy-paste ready patterns** for implementing lint rules in the `many_lints` package using **analyzer ^14.1.0**. Instead of searching through existing rules or diving into analyzer source code, consult this guide first.

For common recipes (specific use-case patterns), see [rules-recipes.md](rules-recipes.md).

**Target Audience:** AI agents and developers implementing new lint rules
**Analyzer Version:** ^14.1.0
**Last Updated:** August 2026

---

## 🔄 META-INSTRUCTIONS FOR AGENTS

### When to Update This Cookbook

**You MUST update this cookbook when:**
- ✅ You discover a new analyzer API pattern not documented here
- ✅ You need to research AST traversal techniques beyond what's documented
- ✅ You find a new type checking method or pattern
- ✅ You implement a complex visitor pattern not shown in examples
- ✅ You discover analyzer ^14.1.0 specific APIs different from older versions
- ✅ You create a new helper utility that could benefit other rules

**Also update the lean quick reference** at `lib/src/rules/AGENTS.md` with a brief mention of the new pattern.

### What to Document

When updating, add:
- **Working code example** (tested and verified)
- **File reference** to the real implementation (for example,
  `lib/src/rules/rule_name.dart`; link it only after the file exists)
- **Brief explanation** of when to use this pattern
- **Common pitfalls** if any

### How to Update

1. Find the appropriate section (or create new section if needed)
2. Add your pattern with format:
   ```markdown
   **Pattern Name:**
   ```dart
   // Working code example
   ```
   **When to use:** Brief description
   **Reference:** link the real source file that implements the pattern
   ```
3. Keep consistent formatting with existing entries
4. Update the Pattern Index if adding new sections

### Format Guidelines

- Use emoji headers for main sections (📚 🎯 🔍 etc.)
- Include line number references when linking files
- Prefer concise, copy-paste ready code over verbose explanations
- Show real examples from the codebase, not hypothetical code

---

## 📖 Pattern Index

Quick navigation to common patterns:

- [Rule Structure Template](#-rule-structure-template)
- [Reusable Rule Patterns](#reusable-rule-base-classes)
- [Type Checking](#-type-checking-patterns)
- [AST Navigation](#-ast-navigation-patterns)
- [Type Inference & Context](#-type-inference--context)
- [Visitor Patterns](#-visitor-patterns)
- [Reporting Issues & Quick Fixes](#-reporting--quick-fixes)
- [Utility Functions](#-utility-functions)
- [Analyzer 14.1.0 APIs](#-analyzer-1410-specific-apis)
- [Quick Reference Cards](#-quick-reference-cards)

For recipes and testing, see [rules-recipes.md](rules-recipes.md).

---

## 🎯 Rule Structure Template

### Reusable Rule Base Classes

For common patterns, use base classes instead of duplicating logic!

**Class Affix Validator Pattern:**

When enforcing naming conventions for classes extending/implementing a configured type:

```dart
import 'package:analyzer/error/error.dart';

import '../class_affix_validator.dart';

class UseClassSuffix extends ClassAffixValidator {
  static const LintCode code = LintCode(
    'use_class_suffix',
    "Class '{1}' does not end with the required '{0}' suffix.",
    correctionMessage: "Rename the class to end with '{0}'.",
  );

  UseClassSuffix()
      : super(
          name: 'use_class_suffix',
          description: 'Warns when a class deriving from a configured type '
              'lacks the required name suffix.',
          kind: AffixKind.suffix,
        );

  @override
  LintCode get diagnosticCode => code;
}
```

**That's it!** The base class handles:
- Reading the `entries:` config (type / affix / optional package / `ignore_private`)
- Type checking with TypeChecker, covering `extends`, `implements`, `with` and indirect ancestors
- Visitor registration and class name validation
- Reporting, with the affix passed as a message argument

**When to use:** Any rule that validates class names based on inheritance/implementation.

Note the base type is **configuration**, not a constructor argument. Both rules built on this
report nothing until the user supplies `entries:`, so installing the package never imposes a
naming convention.

**Examples:**
- [use_class_suffix.dart](../../../lib/src/rules/use_class_suffix.dart) - ~50 lines, mostly docs
- [use_class_prefix.dart](../../../lib/src/rules/use_class_prefix.dart) - same, mirrored

**Reference:** [class_affix_validator.dart](../../../lib/src/class_affix_validator.dart) - Reusable base implementation

### Minimal Lint Rule

For custom patterns, every lint rule follows this structure:

```dart
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class RuleName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'rule_name',
    'Brief description of the issue.',
    correctionMessage: 'How to fix it.',
  );

  RuleName()
      : super(
          name: 'rule_name',
          description: 'Longer description for documentation.',
        );

  @override
  LintCode get diagnosticCode => code;

  // `ManyLintsRule` implements `registerNodeProcessors` itself to wire up
  // per-rule `exclude`, so rules override this hook instead.
  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    // Register the AST nodes you want to visit
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final RuleName rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Your lint logic here
    if (shouldReportLint) {
      rule.reportAtNode(node);
    }
  }
}
```

**Reference:** [use_class_suffix.dart](../../../lib/src/rules/use_class_suffix.dart)

---

## 🔍 Type Checking Patterns

### Creating TypeCheckers

The project uses a custom `TypeChecker` class from [type_checker.dart](../../../lib/src/type_checker.dart).

**By name and package:**
```dart
static const _blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');
static const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');
```

**By URL (for dart: libraries):**
```dart
static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');
static const _functionChecker = TypeChecker.fromUrl('dart:core#Function');
```

**Multiple checkers (ANY match):**
```dart
static const _hookBuilderChecker = TypeChecker.any([
  TypeChecker.fromName('HookBuilder', packageName: 'flutter_hooks'),
  TypeChecker.fromName('HookConsumer', packageName: 'hooks_riverpod'),
]);
```

**Multiple checkers (ALL must match):**
```dart
static const _strictChecker = TypeChecker.all([
  TypeChecker.fromName('Base', packageName: 'my_package'),
  TypeChecker.fromName('Mixin', packageName: 'my_package'),
]);
```

**Reference:** [type_checker.dart](../../../lib/src/type_checker.dart), [use_class_suffix.dart](../../../lib/src/rules/use_class_suffix.dart)

### Checking Types

**Check if element is exactly this type (no inheritance):**
```dart
if (_blocChecker.isExactly(element)) {
  // Element IS Bloc, not a subclass
}
```

**Check if type is exactly this type:**
```dart
if (_iterableChecker.isExactlyType(type)) {
  // Type IS Iterable<T>, not a subtype
}
```

**Check if element is a subtype (inheritance check):**
```dart
if (_blocChecker.isSuperOf(element)) {
  // Element extends/implements Bloc
}
```

**Check if type is assignable from (includes subtypes):**
```dart
if (_iterableChecker.isAssignableFromType(targetType)) {
  // targetType is compatible with Iterable
}
```

**Reference:** [use_class_suffix.dart](../../../lib/src/rules/use_class_suffix.dart)

### Checking Expression Types

Use the helper function from [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart):

```dart
import 'package:many_lints/src/ast_node_analysis.dart';

// Check if an expression has a specific static type
if (isExpressionExactlyType(expression, _widgetChecker)) {
  // Expression's static type is exactly Widget
}
```

**Implementation:**
```dart
bool isExpressionExactlyType(Expression expression, TypeChecker checker) {
  if (expression.staticType case final type?) {
    return checker.isExactlyType(type);
  }
  return false;
}
```

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart), [prefer_center_over_align.dart](../../../lib/src/rules/prefer_center_over_align.dart)

---

## 🌳 AST Navigation Patterns

### Node Registration

Register specific AST node types you want to visit:

```dart
@override
void registerManyLintsProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);

  // For analyzing class declarations
  registry.addClassDeclaration(this, visitor);

  // For widget/object instantiation (Container(), MyClass())
  registry.addInstanceCreationExpression(this, visitor);

  // For method calls (list.map(), object.doSomething())
  registry.addMethodInvocation(this, visitor);

  // For property access (object.isEmpty, myVar.length)
  registry.addPropertyAccess(this, visitor);

  // For prefixed identifiers (Class.field, prefix.identifier)
  registry.addPrefixedIdentifier(this, visitor);

  // For switch statements
  registry.addSwitchStatement(this, visitor);
}
```

**Reference:** Various rules show different patterns

### Navigating Class Members

**Getting class body and members:**
```dart
@override
void visitClassDeclaration(ClassDeclaration node) {
  final body = node.body;
  if (body is! BlockClassBody) return;

  // Find a specific method by name
  final buildMethod = body.members
      .whereType<MethodDeclaration>()
      .firstWhereOrNull((m) => m.name.lexeme == 'build');

  if (buildMethod != null) {
    // Process the method
  }
}
```

**Reference:** [avoid_unnecessary_consumer_widgets.dart](../../../lib/src/rules/avoid_unnecessary_consumer_widgets.dart)

### Constructor and Arguments

**Getting constructor name and element:**
```dart
@override
void visitInstanceCreationExpression(InstanceCreationExpression node) {
  final constructorName = node.constructorName.type;
  final element = constructorName.element;

  if (element?.name == 'Container') {
    // Process Container widget
  }
}
```

**Accessing named arguments:**
```dart
final arguments = node.argumentList.arguments;
for (final arg in arguments.whereType<NamedArgument>()) {
  if (arg.name.lexeme == 'alignment') {
    final value = arg.argumentExpression;
    // Process alignment argument
  }
}
```

`ArgumentList.arguments` is a `NodeList<Argument>`, where `Argument` is sealed:
`Expression` for positional arguments, `NamedArgument` for named ones. Since
analyzer 13.0.0 a `NamedArgument` is **not** an `Expression`, so it has no
`.staticType` or `.element` — read the value through `.argumentExpression`
(`arg.argumentExpression.staticType`) or resolve the target parameter with
`arg.correspondingParameter`.

**Reference:** [prefer_align_over_container.dart](../../../lib/src/rules/prefer_align_over_container.dart)

### Pattern Matching with AST (Dart 3)

Modern pattern matching for complex AST checks:

```dart
@override
void visitPropertyAccess(PropertyAccess node) {
  // Check for .where().isEmpty pattern
  if (node case PropertyAccess(
    propertyName: SimpleIdentifier(name: final property && ('isEmpty' || 'isNotEmpty')),
    target: MethodInvocation(
      target: Expression(staticType: final targetType?),
      methodName: SimpleIdentifier(name: 'where'),
      argumentList: ArgumentList(arguments: [_]),
    ),
  ) when _iterableChecker.isAssignableFromType(targetType)) {
    // Report: prefer .any() or .every() instead of .where().isEmpty
    rule.reportAtNode(node);
  }
}
```

**Reference:** [prefer_any_or_every.dart](../../../lib/src/rules/prefer_any_or_every.dart)

### Analyzing List Literals

**Check list length and elements:**
```dart
if (children case final ListLiteral list) {
  if (list.elements.length == 1) {
    final element = list.elements.first;

    // Check element type with pattern matching
    bool checkExpression(CollectionElement expression) {
      return switch (expression) {
        Expression() => true,
        ForElement() || SpreadElement() => false,
        IfElement(:final thenElement, :final elseElement) =>
          checkExpression(thenElement) &&
          (elseElement == null || checkExpression(elseElement)),
        _ => false,
      };
    }

    if (checkExpression(element)) {
      // Single child in multi-child widget
      rule.reportAtNode(node);
    }
  }
}
```

**Reference:** [avoid_single_child_in_multi_child_widgets.dart](../../../lib/src/rules/avoid_single_child_in_multi_child_widgets.dart)

---

## 🎨 Type Inference & Context

### Centralized Type Inference Utilities

**IMPORTANT:** Type inference logic has been extracted into [type_inference.dart](../../../lib/src/type_inference.dart). **Use these utilities instead of reimplementing context type inference!**

**From [type_inference.dart](../../../lib/src/type_inference.dart):**

```dart
import '../type_inference.dart';

// Infers expected type from expression context (variables, assignments, returns, etc.)
final contextType = inferContextType(expression);

// Resolves return type from function/method
final returnType = resolveReturnType(node);

// Gets switch expression type
final switchType = resolveSwitchExpressionType(node);

// Gets pattern context type (for switch patterns)
final patternType = resolvePatternContextType(node);

// Gets collection element type from List<T>, Set<T>
final elementType = resolveCollectionElementType(collectionNode);

// Checks type compatibility (ignores nullability)
if (isTypeCompatible(contextType, targetElement)) {
  // Context type matches target interface element
}
```

**When to use:** Any time you need to determine expected type from context (variable declarations, assignments, returns, switch cases, collections, binary expressions, etc.)

**Benefits:**
- Single source of truth for type inference
- Handles all common context patterns
- Well-tested and documented
- Easier to maintain

**Reference implementations:**
- [prefer_shorthands_with_enums.dart](../../../lib/src/rules/prefer_shorthands_with_enums.dart) - Uses `inferContextType()` and `isTypeCompatible()`
- [prefer_shorthands_with_static_fields.dart](../../../lib/src/rules/prefer_shorthands_with_static_fields.dart) - Uses `inferContextType()` and `isTypeCompatible()`
- [prefer_returning_shorthands.dart](../../../lib/src/rules/prefer_returning_shorthands.dart) - Uses `isTypeCompatible()`

### Legacy Pattern: Getting Context Type from Parent

**⚠️ DEPRECATED:** Use `inferContextType()` from [type_inference.dart](../../../lib/src/type_inference.dart) instead.

<details>
<summary>Old implementation (for reference only)</summary>

```dart
DartType? _getContextType(Expression node) {
  final parent = node.parent;

  return switch (parent) {
    // Variable declaration: final SomeClass x = value;
    VariableDeclaration(parent: VariableDeclarationList(:final type?)) =>
      type.type,

    // Assignment: x = value;
    AssignmentExpression(:final leftHandSide) =>
      leftHandSide.staticType,

    // Binary expression (comparison): e == value
    BinaryExpression(:final leftOperand, :final rightOperand) =>
      node == rightOperand ? leftOperand.staticType : rightOperand.staticType,

    // Switch case
    SwitchCase() => _getSwitchExpressionType(parent),

    // Return statement
    ReturnStatement() => _getReturnType(parent),

    // Parenthesized expression: pass through
    ParenthesizedExpression() => _getContextType(parent),

    _ => null,
  };
}
```

</details>

---

## 👁️ Visitor Patterns

### SimpleAstVisitor (Single Node Type)

Use when you only need to visit one or two node types:

```dart
class _Visitor extends SimpleAstVisitor<void> {
  final RuleName rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Process only instance creation expressions
    if (condition) {
      rule.reportAtNode(node);
    }
  }
}
```

**Reference:** [use_class_suffix.dart](../../../lib/src/rules/use_class_suffix.dart)

### RecursiveAstVisitor (Deep Traversal)

Use when you need to traverse an entire subtree:

```dart
class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final String name;
  bool used = false;

  _IdentifierVisitor(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) {
      used = true;
    }
    super.visitSimpleIdentifier(node);
  }
}

// Usage: Check if parameter is used in method body
bool _isParameterUsed(AstNode? body, String paramName) {
  if (body == null) return false;

  final visitor = _IdentifierVisitor(paramName);
  body.visitChildren(visitor);
  return visitor.used;
}
```

**Reference:** [avoid_unnecessary_consumer_widgets.dart](../../../lib/src/rules/avoid_unnecessary_consumer_widgets.dart)

### Detecting Variable/Parameter Usage

Full pattern for checking if an identifier is referenced:

```dart
bool _isIdentifierUsed(AstNode? node, String name) {
  if (node == null) return false;

  final visitor = _IdentifierVisitor(name);
  node.visitChildren(visitor);
  return visitor.used;
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final String name;
  bool used = false;

  _IdentifierVisitor(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) {
      used = true;
    }
    super.visitSimpleIdentifier(node);
  }
}
```

**Reference:** [avoid_unnecessary_consumer_widgets.dart](../../../lib/src/rules/avoid_unnecessary_consumer_widgets.dart)

---

## 🚨 Reporting & Quick Fixes

### Reporting Issues

**Different reporting methods:**

```dart
// Report at entire node (highlights whole expression)
rule.reportAtNode(node);

// Report at specific token (e.g., just the class name)
rule.reportAtToken(classDecl.namePart.typeName);

// Report at constructor name only
rule.reportAtNode(node.constructorName);

// Report with message interpolation arguments
rule.reportAtNode(node, arguments: [value1, value2]);

// Report at arbitrary offset (for non-AST constructs like comments)
rule.reportAtOffset(offset, length);
```

**Use in LintCode:**
```dart
static const LintCode code = LintCode(
  'rule_name',
  'The class {0} should have {1} suffix.',  // {0}, {1} are placeholders
  correctionMessage: 'Add the {1} suffix to the class name.',
);

// Later when reporting:
rule.reportAtNode(node, arguments: ['MyClass', 'Bloc']);
// Results in: "The class MyClass should have Bloc suffix."
```

**Reference:** Various rules

### Quick Fix Structure

**Standard fix with ResolvedCorrectionProducer:**

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MyFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.myFix',
    DartFixKindPriority.standard,
    'Description shown in UI',
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
    if (targetNode is! InstanceCreationExpression) return;

    await builder.addDartFileEdit(file, (builder) {
      // Simple replacement
      builder.addSimpleReplacement(
        range.node(targetNode),
        'newCode',
      );

      // Or delete from list
      builder.addDeletion(
        range.nodeInList(argumentList.arguments, argumentToRemove),
      );
    });
  }
}
```

**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart)

### Using Range Factory

**Common range patterns:**

```dart
// Range of entire node
range.node(node)

// Range of a node in a list (includes trailing comma)
range.nodeInList(list, elementNode)

// Range between two tokens
range.startOffsetEndOffset(startToken.offset, endToken.end)

// Range of a token
range.token(token)
```

**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart)

---

## 🛠️ Utility Functions

### Type Inference Utilities

**From [type_inference.dart](../../../lib/src/type_inference.dart):**

Centralized type inference logic for determining expected types from context.

**1. Infer context type:**
```dart
DartType? inferContextType(Expression node)
```
Determines the expected type of an expression based on its usage context (variable declaration, assignment, return statement, collection literal, switch case, etc.).

**2. Resolve return type:**
```dart
DartType? resolveReturnType(AstNode node)
```
Walks up the AST to find the enclosing function/method and returns its declared return type.

**3. Resolve switch expression type:**
```dart
DartType? resolveSwitchExpressionType(AstNode node)
```
Finds the enclosing switch statement/expression and returns the type being switched on.

**4. Resolve pattern context type:**
```dart
DartType? resolvePatternContextType(AstNode node)
```
For switch pattern cases, returns the type of the switch expression.

**5. Resolve collection element type:**
```dart
DartType? resolveCollectionElementType(AstNode collectionNode)
```
Extracts the element type from `List<T>`, `Set<T>`, or `Map<K,V>` (returns first type argument).

**6. Check type compatibility:**
```dart
bool isTypeCompatible(DartType contextType, InterfaceElement targetElement)
```
Checks if a context type matches a target interface element, ignoring nullability. Returns `false` for non-interface types.

**Usage example:**
```dart
import '../type_inference.dart';

@override
void visitPrefixedIdentifier(PrefixedIdentifier node) {
  // Get the expected type from context
  final contextType = inferContextType(node);
  if (contextType == null) return;

  // Check if it matches our target
  final enumElement = node.staticType?.element as EnumElement;
  if (isTypeCompatible(contextType, enumElement)) {
    // Context type makes the enum prefix unnecessary
    rule.reportAtNode(node);
  }
}
```

**Reference:** [prefer_shorthands_with_enums.dart](../../../lib/src/rules/prefer_shorthands_with_enums.dart), [prefer_shorthands_with_static_fields.dart](../../../lib/src/rules/prefer_shorthands_with_static_fields.dart)

### String Distance Utilities

**From [text_distance.dart](../../../lib/src/text_distance.dart):**

**Compute edit distance:**
```dart
int computeEditDistance(String a, String b)
```
Computes the Levenshtein edit distance between two strings (minimum number of single-character edits needed to change one string into another).

**Usage example:**
```dart
import '../text_distance.dart';

// Check if a suffix is a typo
final distance = computeEditDistance('Blok', 'Bloc');
if (distance > 0 && distance <= 2) {
  // Likely a typo - strip and replace
}
```

**Reference:** [add_affix_fix.dart](../../../lib/src/fixes/add_affix_fix.dart)

### General Helpers

**From [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart):**

**1. Check expression type:**
```dart
bool isExpressionExactlyType(Expression expression, TypeChecker checker)
```

**2. Check if instance only uses specific parameter:**
```dart
bool isInstanceCreationExpressionOnlyUsingParameter(
  InstanceCreationExpression node, {
  required String parameter,
  Set<String> ignoredParameters = const {},
})
```

**Usage:**
```dart
if (isInstanceCreationExpressionOnlyUsingParameter(
  node,
  parameter: 'padding',
  ignoredParameters: {'key', 'child'},
)) {
  // Container only uses padding (plus key/child which we ignore)
  rule.reportAtNode(node.constructorName);
}
```

**Reference:** [prefer_padding_over_container.dart](../../../lib/src/rules/prefer_padding_over_container.dart)

**3. Extract single return expression:**
```dart
Expression? maybeGetSingleReturnExpression(FunctionBody body)
```

Returns the expression if the function body is `=> expr` or `{ return expr; }`, otherwise null.

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart)

**4. Safe firstWhere with null return:**
```dart
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test);
}
```

**Usage:**
```dart
final buildMethod = body.members
    .whereType<MethodDeclaration>()
    .firstWhereOrNull((m) => m.name.lexeme == 'build');
```

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart)

**5. Find enclosing class declaration:**
```dart
ClassDeclaration? enclosingClassDeclaration(AstNode node)
```

Walks up parent chain to find the nearest `ClassDeclaration`. Used in rules and fixes that need the enclosing class context.

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart)

**6. Check for @override annotation:**
```dart
bool hasOverrideAnnotation(MethodDeclaration node)
```

Returns true if the method declaration has an `@override` annotation. Shared across rules that filter overridden methods.

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart)

**7. Negate an expression:**
```dart
String negateExpression(Expression expr)
```

Produces the negated form of an expression. Used by `prefer_any_or_every` fix.

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart)

**8. Build `.every()` replacement:**
```dart
String buildEveryReplacement(...)
```

Builds the replacement string for converting `.where().isEmpty` to `.every()`. Used by `prefer_any_or_every` fix.

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart)

### Disposal Utilities

**From [disposal_utils.dart](../../../lib/src/disposal_utils.dart):**

**IMPORTANT:** Use these shared utilities instead of reimplementing cleanup method detection. Extracted from `dispose_fields` and `dispose_provided_instances` rules/fixes.

```dart
import '../disposal_utils.dart';

// Find which cleanup method a type supports (dispose, close, or cancel)
final cleanupMethod = findCleanupMethod(fieldType);
if (cleanupMethod != null) {
  // This type is disposable — use cleanupMethod as the method name
}

// Access the ordered list of cleanup method names
const cleanupMethods = ['dispose', 'close', 'cancel'];
```

**When to use:** Any rule or fix that detects/generates cleanup calls for disposable types.
**Reference:** [disposal_utils.dart](../../../lib/src/disposal_utils.dart), [dispose_fields.dart](../../../lib/src/rules/dispose_fields.dart), [dispose_provided_instances.dart](../../../lib/src/rules/dispose_provided_instances.dart)

### Flutter Widget Helpers

**From [flutter_widget_helpers.dart](../../../lib/src/flutter_widget_helpers.dart):**

```dart
import '../flutter_widget_helpers.dart';

// Enum for flex axis direction (vertical or horizontal)
enum FlexAxis { vertical, horizontal }
```

**When to use:** Rules that detect SizedBox spacers in flex layouts (Row/Column).
**Reference:** [flutter_widget_helpers.dart](../../../lib/src/flutter_widget_helpers.dart), [prefer_spacing.dart](../../../lib/src/rules/prefer_spacing.dart), [use_gap.dart](../../../lib/src/rules/use_gap.dart)

### Riverpod Type Checkers

**From [riverpod_type_checkers.dart](../../../lib/src/riverpod_type_checkers.dart):**

```dart
import '../riverpod_type_checkers.dart';

// TypeChecker that matches all Riverpod Notifier base classes
// (Notifier, AsyncNotifier, AutoDisposeNotifier, etc.)
if (notifierChecker.isSuperOf(element)) {
  // This class extends a Riverpod Notifier
}
```

**When to use:** Rules that need to detect Riverpod Notifier subclasses.
**Reference:** [riverpod_type_checkers.dart](../../../lib/src/riverpod_type_checkers.dart), [avoid_notifier_constructors.dart](../../../lib/src/rules/avoid_notifier_constructors.dart), [dispose_provided_instances.dart](../../../lib/src/rules/dispose_provided_instances.dart)

### Hook-Specific Helpers

**From [hook_detection.dart](../../../lib/src/hook_detection.dart):**

**1. Find all hook calls in a tree:**
```dart
List<MethodInvocation> getAllInnerHookExpressions(AstNode node)
```

**2. Extract hook builder body:**
```dart
FunctionBody? maybeHookBuilderBody(InstanceCreationExpression node)
```

**Reference:** [avoid_unnecessary_hook_widgets.dart](../../../lib/src/rules/avoid_unnecessary_hook_widgets.dart)

---

## 🔧 Analyzer 14.1.0 Specific APIs

### Renamed AST nodes: `NamedArgument`, `FormalParameterDefaultClause`

Two node names that most training data and every pre-14 example still uses **do
not exist** in analyzer 14.1.0. They fail as `type_test_with_undefined_name`,
which reads like a missing import and is not:

| Pre-14 name | analyzer 14.1.0 | Where it appears |
|---|---|---|
| `NamedExpression` | **`NamedArgument`** | the wrapper around a named argument, `f(a: 8)` |
| `DefaultFormalParameter` | **`FormalParameterDefaultClause`** | a parameter's default, `{int a = 7}` |

Note the second is not a renamed parameter node but a *clause*: the literal's
parent is the default clause, whose parent is the `RegularFormalParameter`.

**Do not guess a node's parent chain — ask the analyzer.** A throwaway script
under the package (so `package:analyzer` resolves) settles it in one run, and
is faster than grepping a generated AST barrel:

```dart
// dart run tool/tmp/probe_ast.dart
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class V extends RecursiveAstVisitor<void> {
  @override
  void visitIntegerLiteral(IntegerLiteral node) => print(
    '${node.value} -> ${node.parent.runtimeType} / ${node.parent?.parent.runtimeType}',
  );
}

void main() => parseString(content: 'void f({int a = 7}) {}').unit.accept(V());
// 7 -> FormalParameterDefaultClauseImpl / RegularFormalParameterImpl
```

The `Impl` suffix in the output is the implementation class; test against the
public interface (`FormalParameterDefaultClause`), not the `Impl`.

Grepping `lib/dart/ast/ast.dart` for these names is **not** a reliable check —
in 14.1.0 that file is largely a barrel, so a name can be absent from it and
still exist. `lib/dart/ast/visitor.g.dart` lists the real `visitX` methods and
is the better index.

### Dot shorthands: resolution decides the node type

Dart 3.10 dot shorthands (`.new(...)`, `.zero`) come in three node types, all
exported from `package:analyzer/dart/ast/ast.dart` and all registrable:

| Node | Example | Registry method |
|------|---------|-----------------|
| `DotShorthandConstructorInvocation` | `.new(x)`, `.filled(3, 0)`, factory `.of(x)` | `addDotShorthandConstructorInvocation` |
| `DotShorthandInvocation` | *static method* `.make(x)` | `addDotShorthandInvocation` |
| `DotShorthandPropertyAccess` | `.zero`, `.red` | `addDotShorthandPropertyAccess` |

**⚠️ The split between the two invocation forms is a property of *resolution*,
not of syntax.** Before resolution — which is what `parseString` gives you, and
what an AST dump in a failing test shows — **every** shorthand invocation is a
`DotShorthandInvocation`, including `.new(...)`. Only after resolution does a
constructor (or factory) become a `DotShorthandConstructorInvocation`, while a
static method stays a `DotShorthandInvocation`.

So a rule that registers only the constructor form silently misses every static
method shorthand, and one written from a parse-time AST dump may register only
`DotShorthandInvocation` and then never fire on the constructors it targets.
**Register both invocation forms** unless you deliberately want just one:

```dart
registry.addDotShorthandConstructorInvocation(this, visitor);
registry.addDotShorthandInvocation(this, visitor);
```

Only the two invocation forms carry an `argumentList`; a
`DotShorthandPropertyAccess` cannot contain anything, so it is only ever a
nested node.

No `FeatureSet` gate is needed for these rules — the nodes cannot parse at all
in a pre-3.10 language version, so the visitor simply never runs there.

**Reference:** [avoid_nested_shorthands.dart](../../../lib/src/rules/avoid_nested_shorthands.dart)

### Gating a rule on a Dart language feature (analyzer 14+)

When a lint suggests syntax that only exists from a certain language version
(e.g. private named parameters, Dart 3.12), gate it on the unit's `FeatureSet`
so it stays silent in older-language libraries and the fix can never produce
non-compiling code:

```dart
import 'package:analyzer/dart/analysis/features.dart';

@override
void visitConstructorDeclaration(ConstructorDeclaration node) {
  final unit = node.thisOrAncestorOfType<CompilationUnit>();
  if (unit == null ||
      !unit.featureSet.isEnabled(Feature.private_named_parameters)) {
    return;
  }
  // ...
}
```

Tests can exercise the gate with a `// @dart=3.11` header line.

**Reference:** [prefer_private_named_parameters.dart](../../../lib/src/rules/prefer_private_named_parameters.dart)

### Primary constructors: the class-header AST (Dart 3.13+)

`ClassDeclaration` has **no** `name` field. The name lives in `namePart`, a
sealed `ClassNamePart` that is *either* the plain name *or* a
`PrimaryConstructorDeclaration`:

```dart
// `class Point { ... }`             -> namePart is the plain name part
// `class Point(final int x);`       -> namePart IS a PrimaryConstructorDeclaration
if (node.namePart is PrimaryConstructorDeclaration) return; // already migrated
```

`PrimaryConstructorDeclaration` carries `constKeyword`, `constructorName`,
`typeName`, `typeParameters` and **`formalParameters`** — note it is *not*
`name`/`parameters`, which is the first guess and does not compile.

The body is a sealed `ClassBody`: `EmptyClassBody` (`;`) or `BlockClassBody`
(`{ ... }`, the only one carrying `.members`).

**⚠️ `this.x` is a `FieldFormalParameter`, its own node type.** There is no
`thisKeyword` getter on `RegularFormalParameter`. So "every parameter is an
initializing formal" is a type test, which conveniently rejects a plain `int x`
*and* a `super.x` at once:

```dart
for (final parameter in constructor.parameters.parameters) {
  if (parameter is! FieldFormalParameter) return;    // rejects int x / super.x
  if (parameter.functionTypedSuffix != null) return; // this.cb(int) has no spelling
  final name = parameter.name.lexeme;                // non-nullable here
}
```

Gate on `Feature.primary_constructors`. It is **stable in Dart 3.13** — the
analyzer's own `src/dart/analysis/experiments.g.dart` records
`experimentalReleaseVersion: 3.12.0` and `releaseVersion: 3.13.0`. That table is
the authoritative check whenever release notes are ambiguous about a feature's
status; prefer it over prose.

**Const spelling:** `class const Point(final int x);` — `const` sits *after*
`class`, on the header, not on a constructor. A plain primary constructor is
**not** const, and the other plausible spellings (`const class C(...)`,
`class C.const(...)`, `class C(...) const`) do not compile.

**Reference:** [prefer_primary_constructors.dart](../../../lib/src/rules/prefer_primary_constructors.dart)

### Gating a rule on API existence (SDK-version-independent)

When a lint suggests a member added in a newer Flutter/package version, check
the **resolved element** for the member instead of guessing from versions:

```dart
final element = interfaceType.element;
if (element is EnumElement &&
    element.getters.any((g) => g.name == 'isDark')) {
  // Safe to suggest `.isDark` - the getter exists in the user's Flutter.
}
```

**Reference:** [prefer_theme_mode_getters.dart](../../../lib/src/rules/prefer_theme_mode_getters.dart)

### New Element Access (analyzer ^14.1.0)

**Old API (pre-10.0):**
```dart
final element = node.element;  // Deprecated
```

**New API (10.1.0+):**
```dart
final element = node.declaredFragment?.element;
```

**Reference:** [use_class_suffix.dart](../../../lib/src/rules/use_class_suffix.dart)

### Checking Class Modifiers (abstract, final, sealed, etc.)

**Pattern: Access class declaration modifier tokens**
```dart
@override
void visitClassDeclaration(ClassDeclaration node) {
  final isAbstract = node.abstractKeyword != null;
  final isFinal = node.finalKeyword != null;
  final isSealed = node.sealedKeyword != null;
  final isBase = node.baseKeyword != null;
  final isInterface = node.interfaceKeyword != null;
  final isMixin = node.mixinKeyword != null;
  final classToken = node.classKeyword; // Always non-null
}
```

**⚠️ Important:** Use `node.body` (not deprecated `node.members`) to access class members:
```dart
final body = node.body;
if (body is! BlockClassBody) return;
final members = body.members;
```

**When to use:** Rules that enforce class-level modifiers or analyze class structure
**Reference:** [prefer_abstract_final_static_class.dart](../../../lib/src/rules/prefer_abstract_final_static_class.dart)

### Getting Class Name Token

**For reporting at class name specifically:**
```dart
final classNameToken = classDecl.namePart.typeName;
rule.reportAtToken(classNameToken);
```

**Reference:** [use_class_suffix.dart](../../../lib/src/rules/use_class_suffix.dart)

### Type Display String

**Get human-readable type name:**
```dart
final type = expression.staticType;
if (type != null) {
  final displayName = type.getDisplayString();
  // Use in messages: "Type $displayName is not allowed"
}
```

**Reference:** Multiple rules use this pattern

### InstanceElement Member Access (analyzer 14.1.0)

**⚠️ Important:** In analyzer 14.1.0, `InstanceElement` has `getters`, `methods`, `fields` — NOT `accessors`.

```dart
// Access class members via element
final element = node.declaredFragment?.element;
if (element == null) return;

// Methods (List<MethodElement>)
for (final method in element.methods) {
  if (method.name == '==') { ... }
}

// Getters (List<GetterElement>) — replaces old 'accessors'
for (final getter in element.getters) {
  if (getter.name == 'hashCode') { ... }
}

// Fields (List<FieldElement>)
final instanceFields = element.fields
    .where((f) => !f.isStatic && f.isOriginDeclaration);
```

**Similarly on `InterfaceType`:**
```dart
// InterfaceType also has methods, getters, element
for (final method in type.methods) { ... }
for (final getter in type.getters) { ... }
final el = type.element;  // InterfaceElement
```

**⚠️ Key differences from older analyzer versions:**
- No `accessors` property — use `getters` and `setters` separately
- `FieldElement.isSynthetic` is DEPRECATED → use `f.isOriginDeclaration` instead
- `declaredFragment?.element` returns `ClassElement` (nullable) — use null check, not `is InterfaceElement` (type promotion doesn't work well here)

**Reference:** [prefer_overriding_parent_equality.dart](../../../lib/src/rules/prefer_overriding_parent_equality.dart)

### Resolving the target of an assignment (`writeElement`)

**⚠️ `SimpleIdentifier.element` is `null` on the left of a compound assignment.**
For `_value += 1` the identifier resolves through `writeElement`, not `element`,
so an element lookup that only reads `.element` silently finds nothing and the
rule never reports:

```dart
@override
void visitAssignmentExpression(AssignmentExpression node) {
  final target = switch (node.leftHandSide) {
    SimpleIdentifier() => node.leftHandSide as SimpleIdentifier,
    PropertyAccess(target: ThisExpression()) =>
      (node.leftHandSide as PropertyAccess).propertyName,
    _ => null,
  };
  if (target == null) return;

  // `writeElement` covers `x = 1` and `x += 1`; fall back for safety.
  final element = node.writeElement ?? target.element;
}
```

`writeElement` is declared on `CompoundAssignmentExpression`, which **is**
exported from `package:analyzer/dart/ast/ast.dart` — no implementation import
is needed, even though the declaration lives under `src/`.

**The same storage reaches you as different elements.** A read resolves to a
`GetterElement` (or `FieldElement`), a write to a `SetterElement`. Comparing raw
elements treats `_value` on the left of an assignment as different storage from
`_value` on the right. Canonicalize through `.variable` before comparing:

```dart
Element _canonicalElement(Element element) => switch (element) {
  GetterElement(:final variable) => variable,
  SetterElement(:final variable) => variable,
  _ => element,
};
```

Note `GetterElement.variable` / `SetterElement.variable` are **non-nullable** in
analyzer 14.1.0 — a `?` null-check pattern there is a "will have no effect"
warning.

Canonicalize **before** predicate checks too, not after: an `isStatic` test that
only handles `FieldElement` is skipped entirely by a setter-typed write, so a
static field gets reported despite being excluded by design.

**When to use:** Any rule that tracks reads and writes of the same variable —
assignment analysis, staleness/atomicity checks, use-before-set.
**Reference:** [require_atomic_async_updates.dart](../../../lib/src/rules/require_atomic_async_updates.dart)

### `NamedCompilationUnitMember` is gone: reading a declaration's name (analyzer 14)

Analyzer 14 removed `NamedCompilationUnitMember`, the supertype that used to
expose a `name` token for every top-level declaration. There is now **no**
shared supertype carrying one, and the subtypes split into two shapes:

| Declaration | Name is at |
|---|---|
| `ClassDeclaration`, `EnumDeclaration`, `ExtensionTypeDeclaration` | `namePart.typeName` (a `ClassNamePart`) |
| `MixinDeclaration`, `FunctionDeclaration`, `TypeAlias` | `name` (a `Token`) |
| `ExtensionDeclaration` | `name` (a **`Token?`** — an unnamed extension is legal) |
| `TopLevelVariableDeclaration` | no name of its own; walk `variables.variables` |

Writing `Foo(:final name) || Bar(:final name)` across the two groups fails to
compile twice over — `undefined_getter` on the `namePart` half, then
`inconsistent_pattern_variable_logical_or` because the binding types differ
(`Token` vs `Token?`). Match the groups separately:

```dart
bool isPublic(CompilationUnitMember member) => switch (member) {
  ClassDeclaration(:final namePart) ||
  EnumDeclaration(:final namePart) ||
  ExtensionTypeDeclaration(:final namePart) =>
    !namePart.typeName.lexeme.startsWith('_'),
  FunctionDeclaration(:final name) ||
  MixinDeclaration(:final name) ||
  TypeAlias(:final name) => !name.lexeme.startsWith('_'),
  ExtensionDeclaration(:final name) =>
    name == null || !name.lexeme.startsWith('_'),
  TopLevelVariableDeclaration(:final variables) =>
    variables.variables.any((v) => !v.name.lexeme.startsWith('_')),
  _ => false,
};
```

Used by `require_mirror_test` to decide whether a file declares any public
surface.

### Reading the filesystem from a rule (`Folder`, `File`)

A rule that must check for a *sibling file* — `require_mirror_test` asks
whether `lib/foo.dart` has a `test/foo_test.dart` — reaches the package root
through `RuleContext.package?.root`, captured in
`registerManyLintsProcessors`. `ManyLintsRule` already captures it privately
for configuration, so a rule needing it for its own logic stores its own copy.

```dart
Folder? packageRoot;

@override
void registerManyLintsProcessors(registry, RuleContext context) {
  packageRoot = context.package?.root;
  registry.addCompilationUnit(this, _Visitor(this));
}
```

Then pair it with `relativePath` (already on `ManyLintsRule`) to build and stat
the expected path. Use **`getFile` / `getFolder`**, not
`getChildAssumingFile` / `getChildAssumingFolder` — both are deprecated in
analyzer 14. `folder.getChildren()` can throw `FileSystemException` for a
folder that vanished mid-analysis, so wrap a recursive walk in a try/catch and
degrade to "not found".

### Comments are attached to the *following* token

Comments are not AST nodes. Each hangs off `token.precedingComments`, so the
only way to see all of them is to walk the token stream from
`unit.beginToken`, following `comment.next` within each group:

```dart
Iterable<Token> comments(CompilationUnit node) sync* {
  Token? token = node.beginToken;
  while (token != null) {
    Token? comment = token.precedingComments;
    while (comment != null) {
      yield comment;
      comment = comment.next;
    }
    if (token.isEof) break;
    token = token.next;
  }
}
```

The consequence that costs time: for an **empty block**, the only token after
an interior comment is the closing brace, so a comment inside `catch (e) { /* x */ }`
is found at `body.rightBracket.precedingComments` — not on the block and not on
the left brace. `avoid_empty_catch` relies on exactly this.

Note that the analyzer emits its own `todo` / `fixme` / `hack` *infos* for
marker comments. A rule test over such a fixture must expect them alongside its
own lint (`error(diag.todo, offset, length)`), importing
`package:analyzer/src/diagnostic/diagnostic.dart` as `diag`.

### Pattern Matching Features

Analyzer 14.1.0 works well with Dart 3 pattern matching:

```dart
// Destructuring in patterns
if (node case InstanceCreationExpression(
  constructorName: ConstructorName(:final element?),
  argumentList: ArgumentList(:final arguments),
) when element.name == 'Container') {
  // Process Container with destructured properties
}
```

**Reference:** [prefer_any_or_every.dart](../../../lib/src/rules/prefer_any_or_every.dart)

---

## 📝 Quick Reference Cards

### TypeChecker Cheat Sheet

| Pattern | Code |
|---------|------|
| By name + package | `TypeChecker.fromName('Bloc', packageName: 'bloc')` |
| By URL (dart:) | `TypeChecker.fromUrl('dart:core#Iterable')` |
| Multiple (ANY) | `TypeChecker.any([checker1, checker2])` |
| Multiple (ALL) | `TypeChecker.all([checker1, checker2])` |
| Is exactly | `checker.isExactly(element)` |
| Is subtype | `checker.isSuperOf(element)` |
| Type exactly | `checker.isExactlyType(type)` |
| Type assignable | `checker.isAssignableFromType(type)` |

### Node Registration Cheat Sheet

| What to Analyze | Registry Method |
|----------------|-----------------|
| Entire file | `registry.addCompilationUnit(this, visitor)` |
| Classes | `registry.addClassDeclaration(this, visitor)` |
| Object creation | `registry.addInstanceCreationExpression(this, visitor)` |
| Method calls | `registry.addMethodInvocation(this, visitor)` |
| Properties | `registry.addPropertyAccess(this, visitor)` |
| Prefixed IDs | `registry.addPrefixedIdentifier(this, visitor)` |
| Binary expressions | `registry.addBinaryExpression(this, visitor)` |
| Index access | `registry.addIndexExpression(this, visitor)` |
| Cascade expressions | `registry.addCascadeExpression(this, visitor)` |
| If statements | `registry.addIfStatement(this, visitor)` |
| Switch statements | `registry.addSwitchStatement(this, visitor)` |
| Switch expressions | `registry.addSwitchExpression(this, visitor)` |
| Return statements | `registry.addReturnStatement(this, visitor)` |
| Try statements | `registry.addTryStatement(this, visitor)` |
| Methods | `registry.addMethodDeclaration(this, visitor)` |
| Mixins | `registry.addMixinDeclaration(this, visitor)` |
| Pattern variable decl | `registry.addPatternVariableDeclaration(this, visitor)` |
| Pattern variable stmt | `registry.addPatternVariableDeclarationStatement(this, visitor)` |
| Generic function types | `registry.addGenericFunctionType(this, visitor)` |
| Named arguments | `registry.addNamedArgument(this, visitor)` |
| Formal parameters | `registry.addRegularFormalParameter(this, visitor)` |

**⚠️ Renamed in analyzer 13.0.0:** `addNamedExpression` → `addNamedArgument`, and
`addSimpleFormalParameter` / `addDefaultFormalParameter` → `addRegularFormalParameter`.
The corresponding visitor methods follow the same renaming
(`visitNamedArgument`, `visitRegularFormalParameter`). The old names no longer
exist, so code using them will not compile.

### Common AST Checks

| Check | Pattern |
|-------|---------|
| Element from node | `node.declaredFragment?.element` |
| Class name token | `classDecl.namePart.typeName` |
| Type display string | `type?.getDisplayString()` |
| Named argument name | `arg.name.lexeme` (a `Token`) |
| Named argument value | `arg.argumentExpression` |
| Method name | `method.name.lexeme` |
