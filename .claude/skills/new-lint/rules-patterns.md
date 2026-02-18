# Lint Rule Implementation Cookbook — Patterns

## 📚 About This Document

This cookbook provides **copy-paste ready patterns** for implementing lint rules in the `many_lints` package using **analyzer ^10.0.2**. Instead of searching through existing rules or diving into analyzer source code, consult this guide first.

For common recipes (specific use-case patterns), see [rules-recipes.md](rules-recipes.md).

**Target Audience:** AI agents and developers implementing new lint rules
**Analyzer Version:** ^10.0.2
**Last Updated:** February 2026

---

## 🔄 META-INSTRUCTIONS FOR AGENTS

### When to Update This Cookbook

**You MUST update this cookbook when:**
- ✅ You discover a new analyzer API pattern not documented here
- ✅ You need to research AST traversal techniques beyond what's documented
- ✅ You find a new type checking method or pattern
- ✅ You implement a complex visitor pattern not shown in examples
- ✅ You discover analyzer ^10.0.2 specific APIs different from older versions
- ✅ You create a new helper utility that could benefit other rules

**Also update the lean quick reference** at `lib/src/rules/CLAUDE.md` with a brief mention of the new pattern.

### What to Document

When updating, add:
- **Working code example** (tested and verified)
- **File reference** to your implementation (e.g., `[rule_name.dart](../../../lib/src/rules/rule_name.dart#L10-L20)`)
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
   **Reference:** [file.dart](../../../lib/src/rules/file.dart#L10-L20)
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
- [Analyzer 10.0.2 APIs](#-analyzer-1002-specific-apis)
- [Quick Reference Cards](#-quick-reference-cards)

For recipes and testing, see [rules-recipes.md](rules-recipes.md).

---

## 🎯 Rule Structure Template

### Reusable Rule Base Classes

For common patterns, use base classes instead of duplicating logic!

**Class Suffix Validator Pattern:**

When enforcing naming conventions for classes extending/implementing a specific type:

```dart
import 'package:analyzer/error/error.dart';

import '../class_suffix_validator.dart';

class UseBlocSuffix extends ClassSuffixValidator {
  static final LintCode code = LintCode(
    'use_bloc_suffix',
    'Use Bloc suffix',
    correctionMessage: 'Ex. {0}Bloc',
  );

  UseBlocSuffix()
      : super(
          name: 'use_bloc_suffix',
          description: 'Warns if a Bloc class does not have the Bloc suffix.',
          requiredSuffix: 'Bloc',
          baseClassName: 'Bloc',
          packageName: 'bloc',
        );
}
```

**That's it!** The base class handles:
- Type checking with TypeChecker
- Visitor registration
- Class name validation
- Lint code generation
- Error reporting with parameters

**When to use:** Any rule that validates class name suffixes based on inheritance/implementation.

**Examples:**
- [use_bloc_suffix.dart](../../../lib/src/rules/use_bloc_suffix.dart) - ~20 lines (was ~55 lines)
- [use_cubit_suffix.dart](../../../lib/src/rules/use_cubit_suffix.dart) - ~20 lines (was ~57 lines)
- [use_notifier_suffix.dart](../../../lib/src/rules/use_notifier_suffix.dart) - ~21 lines (was ~59 lines)

**Reference:** [class_suffix_validator.dart](../../../lib/src/class_suffix_validator.dart) - Reusable base implementation

### Minimal Lint Rule

For custom patterns, every lint rule follows this structure:

```dart
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class RuleName extends AnalysisRule {
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

  @override
  void registerNodeProcessors(
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

**Reference:** [use_bloc_suffix.dart](../../../lib/src/rules/use_bloc_suffix.dart#L1-L60)

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

**Reference:** [type_checker.dart](../../../lib/src/type_checker.dart#L1-L134), [use_bloc_suffix.dart](../../../lib/src/rules/use_bloc_suffix.dart#L42-L53)

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

**Reference:** [use_bloc_suffix.dart](../../../lib/src/rules/use_bloc_suffix.dart#L51-L53)

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

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart), [prefer_center_over_align.dart](../../../lib/src/rules/prefer_center_over_align.dart#L43)

---

## 🌳 AST Navigation Patterns

### Node Registration

Register specific AST node types you want to visit:

```dart
@override
void registerNodeProcessors(
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

**Reference:** [avoid_unnecessary_consumer_widgets.dart](../../../lib/src/rules/avoid_unnecessary_consumer_widgets.dart#L44-L62)

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
for (final arg in arguments.whereType<NamedExpression>()) {
  if (arg.name.label.name == 'alignment') {
    final value = arg.expression;
    // Process alignment argument
  }
}
```

**Reference:** [prefer_align_over_container.dart](../../../lib/src/rules/prefer_align_over_container.dart#L40-L70)

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

**Reference:** [prefer_any_or_every.dart](../../../lib/src/rules/prefer_any_or_every.dart#L45-L58)

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

**Reference:** [avoid_single_child_in_multi_child_widgets.dart](../../../lib/src/rules/avoid_single_child_in_multi_child_widgets.dart#L103-L117)

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

**Reference:** [use_bloc_suffix.dart](../../../lib/src/rules/use_bloc_suffix.dart#L55-L67)

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

**Reference:** [avoid_unnecessary_consumer_widgets.dart](../../../lib/src/rules/avoid_unnecessary_consumer_widgets.dart#L71-L88)

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

**Reference:** [avoid_unnecessary_consumer_widgets.dart](../../../lib/src/rules/avoid_unnecessary_consumer_widgets.dart#L71-L88)

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

**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L1-L54)

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

**Reference:** [prefer_center_over_align_fix.dart](../../../lib/src/fixes/prefer_center_over_align_fix.dart#L40-L50)

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

**Reference:** [prefer_shorthands_with_enums.dart](../../../lib/src/rules/prefer_shorthands_with_enums.dart#L1-L108), [prefer_shorthands_with_static_fields.dart](../../../lib/src/rules/prefer_shorthands_with_static_fields.dart#L1-L137)

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

**Reference:** [add_suffix_fix.dart](../../../lib/src/fixes/add_suffix_fix.dart#L85-L98)

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

**Reference:** [prefer_padding_over_container.dart](../../../lib/src/rules/prefer_padding_over_container.dart#L44-L50)

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

## 🔧 Analyzer 10.0.2 Specific APIs

### New Element Access (analyzer ^10.0.2)

**Old API (pre-10.0):**
```dart
final element = node.element;  // Deprecated
```

**New API (10.0.2+):**
```dart
final element = node.declaredFragment?.element;
```

**Reference:** [use_bloc_suffix.dart](../../../lib/src/rules/use_bloc_suffix.dart#L51)

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
**Reference:** [prefer_abstract_final_static_class.dart](../../../lib/src/rules/prefer_abstract_final_static_class.dart#L45-L78)

### Getting Class Name Token

**For reporting at class name specifically:**
```dart
final classNameToken = classDecl.namePart.typeName;
rule.reportAtToken(classNameToken);
```

**Reference:** [use_bloc_suffix.dart](../../../lib/src/rules/use_bloc_suffix.dart#L53)

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

### InstanceElement Member Access (analyzer 10.0.2)

**⚠️ Important:** In analyzer 10.0.2, `InstanceElement` has `getters`, `methods`, `fields` — NOT `accessors`.

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

**Reference:** [prefer_overriding_parent_equality.dart](../../../lib/src/rules/prefer_overriding_parent_equality.dart#L68-L97)

### Pattern Matching Features

Analyzer 10.0.2 works well with Dart 3 pattern matching:

```dart
// Destructuring in patterns
if (node case InstanceCreationExpression(
  constructorName: ConstructorName(:final element?),
  argumentList: ArgumentList(:final arguments),
) when element.name == 'Container') {
  // Process Container with destructured properties
}
```

**Reference:** [prefer_any_or_every.dart](../../../lib/src/rules/prefer_any_or_every.dart#L45-L58)

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
| Mixins | `registry.addMixinDeclaration(this, visitor)` |

### Common AST Checks

| Check | Pattern |
|-------|---------|
| Element from node | `node.declaredFragment?.element` |
| Class name token | `classDecl.namePart.typeName` |
| Type display string | `type?.getDisplayString()` |
| Named argument value | `arg.name.label.name` |
| Method name | `method.name.lexeme` |
