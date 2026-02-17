# Lint Rule Implementation Cookbook

## 📚 About This Document

This cookbook provides **copy-paste ready patterns** for implementing lint rules in the `many_lints` package using **analyzer ^10.0.2**. Instead of searching through existing rules or diving into analyzer source code, consult this guide first.

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

### What to Document

When updating, add:
- **Working code example** (tested and verified)
- **File reference** to your implementation (e.g., `[rule_name.dart](rule_name.dart#L10-L20)`)
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
   **Reference:** [file.dart](file.dart#L10-L20)
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
- [Reusable Rule Patterns](#reusable-rule-base-classes) ⚡ NEW
- [Type Checking](#-type-checking-patterns)
- [AST Navigation](#-ast-navigation-patterns)
- [Type Inference & Context](#-type-inference--context) ⚡ UPDATED
- [Visitor Patterns](#-visitor-patterns)
- [Reporting Issues & Quick Fixes](#-reporting--quick-fixes)
- [Utility Functions](#-utility-functions)
- [Analyzer 10.0.2 APIs](#-analyzer-1002-specific-apis)
- [Common Recipes](#-common-recipes)
- [Testing & Registration](#-testing--registration)

---

## 🎯 Rule Structure Template

### Reusable Rule Base Classes

**⚡ NEW:** For common patterns, use base classes instead of duplicating logic!

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
- [use_bloc_suffix.dart](use_bloc_suffix.dart) - ~20 lines (was ~55 lines)
- [use_cubit_suffix.dart](use_cubit_suffix.dart) - ~20 lines (was ~57 lines)  
- [use_notifier_suffix.dart](use_notifier_suffix.dart) - ~21 lines (was ~59 lines)

**Reference:** [../class_suffix_validator.dart](../class_suffix_validator.dart) - Reusable base implementation

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

**Reference:** [use_bloc_suffix.dart](use_bloc_suffix.dart#L1-L60)

---

## 🔍 Type Checking Patterns

### Creating TypeCheckers

The project uses a custom `TypeChecker` class from [../type_checker.dart](../type_checker.dart).

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

**Reference:** [../type_checker.dart](../type_checker.dart#L1-L134), [use_bloc_suffix.dart](use_bloc_suffix.dart#L42-L53)

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

**Reference:** [use_bloc_suffix.dart](use_bloc_suffix.dart#L51-L53)

### Checking Expression Types

Use the helper function from [../utils/helpers.dart](../utils/helpers.dart):

```dart
import 'package:many_lints/src/utils/helpers.dart';

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

**Reference:** [../utils/helpers.dart](../utils/helpers.dart#L6-L11), [prefer_center_over_align.dart](prefer_center_over_align.dart#L43)

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

**Reference:** [avoid_unnecessary_consumer_widgets.dart](avoid_unnecessary_consumer_widgets.dart#L44-L62)

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

**Reference:** [prefer_align_over_container.dart](prefer_align_over_container.dart#L40-L70)

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

**Reference:** [prefer_any_or_every.dart](prefer_any_or_every.dart#L45-L58)

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

**Reference:** [avoid_single_child_in_multi_child_widgets.dart](avoid_single_child_in_multi_child_widgets.dart#L103-L117)

---

## 🎨 Type Inference & Context

### ⚡ NEW: Centralized Type Inference Utilities

**✨ IMPORTANT:** As of February 2026, type inference logic has been extracted into [../type_inference.dart](../type_inference.dart). **Use these utilities instead of reimplementing context type inference!**

**From [../type_inference.dart](../type_inference.dart):**

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
- [prefer_shorthands_with_enums.dart](prefer_shorthands_with_enums.dart) - Uses `inferContextType()` and `isTypeCompatible()`
- [prefer_shorthands_with_static_fields.dart](prefer_shorthands_with_static_fields.dart) - Uses `inferContextType()` and `isTypeCompatible()`
- [prefer_returning_shorthands.dart](prefer_returning_shorthands.dart) - Uses `isTypeCompatible()`

### Legacy Pattern: Getting Context Type from Parent

**⚠️ DEPRECATED:** Use `inferContextType()` from [../type_inference.dart](../type_inference.dart) instead.

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

**Reference:** [use_bloc_suffix.dart](use_bloc_suffix.dart#L55-L67)

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

**Reference:** [avoid_unnecessary_consumer_widgets.dart](avoid_unnecessary_consumer_widgets.dart#L71-L88)

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

**Reference:** [avoid_unnecessary_consumer_widgets.dart](avoid_unnecessary_consumer_widgets.dart#L71-L88)

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

**Reference:** [prefer_center_over_align_fix.dart](../fixes/prefer_center_over_align_fix.dart#L1-L54)

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

**Reference:** [prefer_center_over_align_fix.dart](../fixes/prefer_center_over_align_fix.dart#L40-L50)

---

## 🛠️ Utility Functions

### Type Inference Utilities

**From [../type_inference.dart](../type_inference.dart):**

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

**Reference:** [prefer_shorthands_with_enums.dart](prefer_shorthands_with_enums.dart#L1-L108), [prefer_shorthands_with_static_fields.dart](prefer_shorthands_with_static_fields.dart#L1-L137)

### String Distance Utilities

**From [../text_distance.dart](../text_distance.dart):**

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

**Reference:** [../fixes/add_suffix_fix.dart](../fixes/add_suffix_fix.dart#L85-L98)

### General Helpers

**From [../utils/helpers.dart](../utils/helpers.dart):**

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

**Reference:** [prefer_padding_over_container.dart](prefer_padding_over_container.dart#L44-L50)

**3. Extract single return expression:**
```dart
Expression? maybeGetSingleReturnExpression(FunctionBody body)
```

Returns the expression if the function body is `=> expr` or `{ return expr; }`, otherwise null.

**Reference:** [../utils/helpers.dart](../utils/helpers.dart#L39-L56)

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

**Reference:** [../utils/helpers.dart](../utils/helpers.dart#L96-L104)

### Hook-Specific Helpers

**From [../utils/hook_helpers.dart](../utils/hook_helpers.dart):**

**1. Find all hook calls in a tree:**
```dart
List<MethodInvocation> getAllInnerHookExpressions(AstNode node)
```

**2. Extract hook builder body:**
```dart
FunctionBody? maybeHookBuilderBody(InstanceCreationExpression node)
```

**Reference:** [avoid_unnecessary_hook_widgets.dart](avoid_unnecessary_hook_widgets.dart)

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

**Reference:** [use_bloc_suffix.dart](use_bloc_suffix.dart#L51)

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
**Reference:** [prefer_abstract_final_static_class.dart](prefer_abstract_final_static_class.dart#L45-L78)

### Getting Class Name Token

**For reporting at class name specifically:**
```dart
final classNameToken = classDecl.namePart.typeName;
rule.reportAtToken(classNameToken);
```

**Reference:** [use_bloc_suffix.dart](use_bloc_suffix.dart#L53)

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

**Reference:** [prefer_any_or_every.dart](prefer_any_or_every.dart#L45-L58)

---

## 📋 Common Recipes

### Recipe: Check if Class Extends/Implements Specific Type

```dart
import 'package:many_lints/src/type_checker.dart';

class _Visitor extends SimpleAstVisitor<void> {
  static const _blocChecker = TypeChecker.fromName('Bloc', packageName: 'bloc');
  
  final MyRule rule;
  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;
    
    // Check if class extends/implements Bloc
    if (_blocChecker.isSuperOf(element)) {
      final className = element.name;
      if (!className.endsWith('Bloc')) {
        rule.reportAtToken(node.namePart.typeName);
      }
    }
  }
}
```

**Reference:** [use_bloc_suffix.dart](use_bloc_suffix.dart#L44-L67)

### Recipe: Detect Variable Type from Context

```dart
DartType? getExpectedType(Expression expr) {
  final parent = expr.parent;
  
  return switch (parent) {
    // Variable declaration with explicit type
    VariableDeclaration(
      parent: VariableDeclarationList(:final type?)
    ) => type.type,
    
    // Assignment
    AssignmentExpression(:final leftHandSide) => leftHandSide.staticType,
    
    // Function argument - need to get parameter type
    ArgumentList() => _getParameterType(parent, expr),
    
    // Return statement
    ReturnStatement() => _getReturnType(expr),
    
    _ => null,
  };
}
```

**Reference:** [prefer_shorthands_with_static_fields.dart](prefer_shorthands_with_static_fields.dart#L133-L185)

### Recipe: Find All Method Invocations in Class

```dart
class _MethodInvocationCollector extends RecursiveAstVisitor<void> {
  final String methodName;
  final List<MethodInvocation> invocations = [];
  
  _MethodInvocationCollector(this.methodName);
  
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == methodName) {
      invocations.add(node);
    }
    super.visitMethodInvocation(node);
  }
}

// Usage:
List<MethodInvocation> findMethodCalls(ClassDeclaration cls, String method) {
  final collector = _MethodInvocationCollector(method);
  cls.visitChildren(collector);
  return collector.invocations;
}
```

### Recipe: Check Widget Constructor Parameters

```dart
import 'package:many_lints/src/utils/helpers.dart';

// Check if Container only uses 'alignment' parameter
if (node case InstanceCreationExpression(
  constructorName: ConstructorName(
    type: NamedType(element: final element?),
  ),
) when element.name == 'Container') {
  
  if (isInstanceCreationExpressionOnlyUsingParameter(
    node,
    parameter: 'alignment',
    ignoredParameters: {'key', 'child'},
  )) {
    // Suggest Align widget instead
    rule.reportAtNode(node.constructorName);
  }
}
```

**Reference:** [prefer_align_over_container.dart](prefer_align_over_container.dart#L42-L50)

### Recipe: Extract Single Return Expression

```dart
import 'package:many_lints/src/utils/helpers.dart';

@override
void visitMethodDeclaration(MethodDeclaration node) {
  final body = node.body;
  
  // Get expression from `=> expr` or `{ return expr; }`
  final returnExpr = maybeGetSingleReturnExpression(body);
  
  if (returnExpr != null) {
    // Process the returned expression
  }
}
```

**Reference:** [../utils/helpers.dart](../utils/helpers.dart#L39-L56)

### Recipe: Check for Specific Argument Pattern

```dart
// Find named argument by name
NamedExpression? findNamedArgument(
  InstanceCreationExpression node,
  String name,
) {
  return node.argumentList.arguments
      .whereType<NamedExpression>()
      .firstWhereOrNull((arg) => arg.name.label.name == name);
}

// Check if argument has specific value pattern
final alignmentArg = findNamedArgument(node, 'alignment');
if (alignmentArg != null) {
  final expr = alignmentArg.expression;
  
  // Check if it's Alignment.center
  if (expr case PrefixedIdentifier(
    prefix: SimpleIdentifier(name: 'Alignment'),
    identifier: SimpleIdentifier(name: 'center'),
  )) {
    // Suggest Center widget instead
    rule.reportAtNode(node);
  }
}
```

**Reference:** [prefer_center_over_align.dart](prefer_center_over_align.dart#L40-L70)

---

## 🧪 Testing & Registration

### Test Structure

**Standard test with AnalysisRuleTest:**

```dart
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:many_lints/src/rules/my_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(MyRuleTest));
}

@reflectiveTest
class MyRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MyRule();
    
    // Mock external packages if needed
    newPackage('bloc').addFile('lib/bloc.dart', r'''
      class Bloc {}
    ''');
    
    super.setUp();
  }

  Future<void> test_triggers_lint() async {
    await assertDiagnostics(
      r'''
class MyClass extends Bloc {
//    ^^^^^^^
}
      ''',
      [lint(6, 7)],  // offset 6, length 7
    );
  }

  Future<void> test_no_lint_with_suffix() async {
    await assertNoDiagnostics(r'''
class MyBloc extends Bloc {}
    ''');
  }
  
  Future<void> test_fix() async {
    await assertDiagnostics(
      r'''
final x = Container(alignment: Alignment.center, child: Text('hi'));
      ''',
      [lint(10, 9)],
    );
    
    await assertSingleDiagnosticFix(
      editFileContext(file: testFile),
      r'''
final x = Center(child: Text('hi'));
      ''',
    );
  }
}
```

**Reference:** [use_bloc_suffix_test.dart](../../test/use_bloc_suffix_test.dart#L1-L40)

### Mock Package Setup

**Creating mock dependencies:**

```dart
@override
void setUp() {
  rule = MyRule();
  
  // Mock Flutter widgets
  newPackage('flutter').addFile('lib/widgets.dart', r'''
    class Widget {}
    class Container extends Widget {}
    class Align extends Widget {}
  ''');
  
  // Mock with multiple files
  final blocPackage = newPackage('bloc');
  blocPackage.addFile('lib/bloc.dart', 'class Bloc {}');
  blocPackage.addFile('lib/cubit.dart', 'class Cubit {}');
  
  super.setUp();
}
```

### Registration in Plugin

**In [../../many_lints.dart](../../many_lints.dart):**

```dart
import 'package:analysis_server_plugin/plugin.dart';
import 'package:many_lints/src/rules/my_rule.dart';
import 'package:many_lints/src/fixes/my_rule_fix.dart';
import 'package:many_lints/src/assists/my_assist.dart';

class ManyLintsPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    // Register the lint rule (warning level)
    registry.registerWarningRule(MyRule());
    
    // Register quick fix for the rule
    registry.registerFixForRule(MyRule.code, MyRuleFix.new);
    
    // Optional: Register assist (non-fix code action)
    registry.registerAssist(MyAssist.new);
  }
}
```

**Reference:** [../../many_lints.dart](../../many_lints.dart)

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
| Switch statements | `registry.addSwitchStatement(this, visitor)` |

### Common AST Checks

| Check | Pattern |
|-------|---------|
| Element from node | `node.declaredFragment?.element` |
| Class name token | `classDecl.namePart.typeName` |
| Type display string | `type?.getDisplayString()` |
| Named argument value | `arg.name.label.name` |
| Method name | `method.name.lexeme` |

---

## 🎓 Learning Path

**For new rule implementers:**

1. ✅ Start with [Rule Structure Template](#-rule-structure-template)
2. ✅ Choose appropriate [Node Registration](#node-registration)
3. ✅ Use [Type Checking](#-type-checking-patterns) if you need type analysis
4. ✅ Navigate AST with [AST Navigation](#-ast-navigation-patterns)
5. ✅ Check [Common Recipes](#-common-recipes) for your specific use case
6. ✅ Implement [Quick Fix](#quick-fix-structure) if applicable
7. ✅ Write [Tests](#test-structure) following the pattern
8. ✅ [Register](#registration-in-plugin) your rule in the plugin

**For complex patterns:**
- Study similar existing rules in this directory
- Use [Visitor Patterns](#-visitor-patterns) for deep analysis
- Leverage [Utility Functions](#-utility-functions) to avoid reinventing wheels

### Recipe: Detect Factory Constructor Calls (with and without type args)

**⚠️ Important:** When detecting factory constructors like `List.from()` or `Set.of()`, the AST representation differs depending on whether explicit type arguments are provided:

- **With type args** (`List<int>.from(x)`): Parsed as `InstanceCreationExpression`
- **Without type args** (`List.from(x)`): Parsed as `MethodInvocation`

You must register visitors for **both** node types:

```dart
@override
void registerNodeProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);
  registry.addInstanceCreationExpression(this, visitor);
  registry.addMethodInvocation(this, visitor);
}
```

**Visitor pattern:**
```dart
@override
void visitInstanceCreationExpression(InstanceCreationExpression node) {
  // List<int>.from(source) — constructorName.name is 'from'
  final name = node.constructorName.name;
  if (name == null || name.name != 'from') return;
  final typeName = node.constructorName.type.name.lexeme; // 'List'
  _check(node, node.argumentList, node.staticType, typeName);
}

@override
void visitMethodInvocation(MethodInvocation node) {
  // List.from(source) — methodName is 'from', target is 'List'
  if (node.methodName.name != 'from') return;
  final target = node.target;
  if (target is! SimpleIdentifier) return;
  _check(node, node.argumentList, node.staticType, target.name);
}
```

**When to use:** Any rule that analyzes calls to named constructors on core types (`List.from`, `Set.of`, `Map.from`, etc.)
**Reference:** [prefer_iterable_of.dart](prefer_iterable_of.dart#L53-L76)

---

### Recipe: Extract Element Type from Generic Collection

```dart
DartType? _getIterableElementType(InterfaceType type) {
  // Direct type arguments (List<int> → int)
  if (type.typeArguments.isNotEmpty) {
    return type.typeArguments.first;
  }
  // Walk supertypes for Iterable<T>
  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == 'Iterable' &&
        supertype.typeArguments.isNotEmpty) {
      return supertype.typeArguments.first;
    }
  }
  return null;
}
```

**When to use:** When you need the `T` from `List<T>`, `Set<T>`, or any `Iterable<T>` subtype
**Reference:** [prefer_iterable_of.dart](prefer_iterable_of.dart#L122-L135)

---

### Recipe: Check If Node Is Inside a Loop Body

Walk up the AST parent chain to detect if a node is nested inside a loop, stopping at function boundaries:

```dart
static bool _isInsideLoopBody(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ForStatement ||
        current is WhileStatement ||
        current is DoStatement) {
      return true;
    }
    // Stop at function boundaries — a loop in an outer function
    // doesn't make a nested closure's access suspicious.
    if (current is FunctionExpression ||
        current is FunctionDeclaration ||
        current is MethodDeclaration) {
      return false;
    }
    current = current.parent;
  }
  return false;
}
```

**When to use:** Rules that should only trigger inside loop bodies (for, for-in, while, do-while)
**Reference:** [avoid_accessing_collections_by_constant_index.dart](avoid_accessing_collections_by_constant_index.dart#L57-L75)

---

### Recipe: Check If an Identifier Refers to a Constant

For `SimpleIdentifier.element`, local variables resolve to `VariableElement` while top-level/static fields resolve to `PropertyAccessorElement` (the synthetic getter). Handle both:

```dart
import 'package:analyzer/dart/element/element.dart';

static bool _isConstantIdentifier(SimpleIdentifier id) {
  final element = id.element;
  // Local const/final variables
  if (element is VariableElement) {
    return element.isConst ||
        (element.isFinal && element.computeConstantValue() != null);
  }
  // Top-level / static const fields (resolved as synthetic getter)
  if (element is PropertyAccessorElement) {
    return element.variable.isConst;
  }
  return false;
}
```

**When to use:** Rules that need to distinguish constant vs mutable identifiers
**Reference:** [avoid_accessing_collections_by_constant_index.dart](avoid_accessing_collections_by_constant_index.dart#L78-L118)

---

### Recipe: Analyze Cascade Expression Targets

`CascadeExpression` has a `target` (the expression being cascaded on), `cascadeSections` (the `..method()` parts), and `isNullAware` (whether it's `?..`). Use this to check what the cascade is applied to:

```dart
@override
void visitCascadeExpression(CascadeExpression node) {
  final target = node.target;
  // Check if cascade follows a specific binary operator
  if (target is BinaryExpression &&
      target.operator.type == TokenType.QUESTION_QUESTION) {
    // Cascade after ?? without parentheses
    rule.reportAtNode(node);
  }
}
```

**When to use:** Rules that analyze cascade operator precedence or validate cascade targets
**Reference:** [avoid_cascade_after_if_null.dart](avoid_cascade_after_if_null.dart#L55-L63)

---

### Recipe: Analyze Binary Expression Operators (==, !=, etc.)

Register `addBinaryExpression` to visit `BinaryExpression` nodes and check the operator token type:

```dart
import 'package:analyzer/dart/ast/token.dart';

@override
void registerNodeProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);
  registry.addBinaryExpression(this, visitor);
}

@override
void visitBinaryExpression(BinaryExpression node) {
  final op = node.operator.type;
  if (op != TokenType.EQ_EQ && op != TokenType.BANG_EQ) return;

  final leftType = node.leftOperand.staticType;
  final rightType = node.rightOperand.staticType;
  // Analyze operand types...
}
```

**Common TokenType values:** `TokenType.EQ_EQ` (`==`), `TokenType.BANG_EQ` (`!=`), `TokenType.PLUS` (`+`), `TokenType.QUESTION_QUESTION` (`??`)

**Checking for const expressions:**
```dart
static bool _isConstExpression(Expression expr) {
  var e = expr;
  while (e is ParenthesizedExpression) {
    e = e.expression;
  }
  return switch (e) {
    TypedLiteral(constKeyword: _?) => true,  // const [1] or const {1}
    InstanceCreationExpression(:final keyword?)
        when keyword.type == Keyword.CONST => true,
    NullLiteral() => true,
    _ => false,
  };
}
```

**When to use:** Rules that analyze equality/comparison operators between specific types
**Reference:** [avoid_collection_equality_checks.dart](avoid_collection_equality_checks.dart#L64-L90)

---

### Recipe: Check If Two Types Are Unrelated (No Subtype Relationship)

To determine if two types have no subtype relationship in either direction (useful for detecting impossible collection operations):

```dart
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

static bool _areUnrelatedTypes(DartType argType, DartType expectedType) {
  // Skip dynamic/void — analyzer can't determine actual type
  if (argType is DynamicType || expectedType is DynamicType) return false;
  if (argType is VoidType || expectedType is VoidType) return false;

  // Skip generic type parameters — too imprecise
  if (argType is TypeParameterType || expectedType is TypeParameterType) {
    return false;
  }

  // Both must be interface types for meaningful comparison
  if (argType is! InterfaceType || expectedType is! InterfaceType) {
    return false;
  }

  final argElement = argType.element;
  final expectedElement = expectedType.element;

  return !_isSubtypeOf(argElement, expectedElement) &&
      !_isSubtypeOf(expectedElement, argElement);
}

static bool _isSubtypeOf(InterfaceElement a, InterfaceElement b) {
  if (a == b) return true;
  for (final supertype in a.allSupertypes) {
    if (supertype.element == b) return true;
  }
  return false;
}
```

**When to use:** Rules that detect type mismatches in method arguments (e.g., passing `String` to `List<int>.contains`)
**Reference:** [avoid_collection_methods_with_unrelated_types.dart](avoid_collection_methods_with_unrelated_types.dart#L201-L235)

---

### Recipe: Extract Map Key/Value Types from `InterfaceType`

To get `K` and `V` from `Map<K, V>`, including when the type is a subclass of Map:

```dart
static (DartType, DartType)? _getMapTypes(InterfaceType type) {
  if (type.element.name == 'Map' && type.typeArguments.length == 2) {
    return (type.typeArguments[0], type.typeArguments[1]);
  }
  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == 'Map' &&
        supertype.typeArguments.length == 2) {
      return (supertype.typeArguments[0], supertype.typeArguments[1]);
    }
  }
  return null;
}
```

**When to use:** Rules that analyze Map operations and need to check key or value types separately
**Reference:** [avoid_collection_methods_with_unrelated_types.dart](avoid_collection_methods_with_unrelated_types.dart#L173-L184)

---

### Recipe: Analyze `MethodInvocation` on Collection Targets

Register `addMethodInvocation` to visit method calls, use `node.realTarget` to get the collection expression:

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  final target = node.realTarget;
  if (target == null) return;

  final targetType = target.staticType;
  if (targetType is! InterfaceType) return;

  final methodName = node.methodName.name;
  final args = node.argumentList.arguments;
  if (args.isEmpty) return;

  final argType = args.first.staticType;
  if (argType == null) return;

  // Check against collection type parameters...
}
```

**⚠️ Important:** Use `node.realTarget` (not `node.target`) — `realTarget` unwraps cascade sections correctly.

**When to use:** Rules that analyze method calls on collection types
**Reference:** [avoid_collection_methods_with_unrelated_types.dart](avoid_collection_methods_with_unrelated_types.dart#L86-L143)

---

### Recipe: Traverse Token Stream for Comment Analysis

Use `addCompilationUnit` to visit the entire file, then walk the token stream to access all comments via `precedingComments`:

```dart
@override
void registerNodeProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);
  registry.addCompilationUnit(this, visitor);
}

@override
void visitCompilationUnit(CompilationUnit node) {
  Token? token = node.beginToken;
  while (token != null && !token.isEof) {
    Token? comment = token.precedingComments;
    while (comment != null) {
      if (comment.type == TokenType.SINGLE_LINE_COMMENT) {
        // Process single-line comment
      }
      comment = comment.next;
    }
    token = token.next;
  }
  // Don't forget EOF token's preceding comments
  if (token != null && token.isEof) {
    Token? comment = token.precedingComments;
    while (comment != null) {
      // Process comment
      comment = comment.next;
    }
  }
}
```

**Key details:**
- Comments are attached to tokens via `precedingComments`, NOT as AST nodes
- `precedingComments` returns the first comment; follow `next` for additional comments before the same token
- `TokenType.SINGLE_LINE_COMMENT` for `//` comments, `TokenType.MULTI_LINE_COMMENT` for `/* */`
- Doc comments (`///`) are also `SINGLE_LINE_COMMENT` — check `lexeme.startsWith('///')` to distinguish
- Always check the EOF token, as trailing comments at file end are attached there

**Reporting at offsets (not AST nodes):**
```dart
// Use reportAtOffset for non-node-based reporting
rule.reportAtOffset(token.offset, token.length);
```

**When to use:** Rules that analyze comments, whitespace, or other non-AST constructs
**Reference:** [avoid_commented_out_code.dart](avoid_commented_out_code.dart#L47-L97)

---

### Recipe: Delete Source by Offset in Quick Fix

When the diagnostic is reported at an offset (not an AST node), use `diagnosticOffset` and `diagnosticLength` in the fix to locate the source range:

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  final offset = diagnosticOffset;
  final length = diagnosticLength;
  if (offset == null || length == null) return;

  final content = unitResult.content;

  // Extend deletion to full lines
  var deleteStart = offset;
  while (deleteStart > 0 && content[deleteStart - 1] != '\n') {
    deleteStart--;
  }
  var deleteEnd = offset + length;
  while (deleteEnd < content.length && content[deleteEnd] != '\n') {
    deleteEnd++;
  }
  if (deleteEnd < content.length) deleteEnd++; // include trailing \n

  await builder.addDartFileEdit(file, (builder) {
    builder.addDeletion(SourceRange(deleteStart, deleteEnd - deleteStart));
  });
}
```

**Key details:**
- `diagnosticOffset` and `diagnosticLength` are available on `ResolvedCorrectionProducer`
- `unitResult.content` provides the full source text for line-boundary calculations
- Use `SourceRange` from `package:analyzer/source/source_range.dart` for custom ranges

**When to use:** Fixes for offset-based diagnostics (comments, tokens not tied to AST nodes)
**Reference:** [../fixes/avoid_commented_out_code_fix.dart](../fixes/avoid_commented_out_code_fix.dart#L27-L49)

---

### Recipe: Compare Cascade Sections for Duplicates

Cascade sections in `cascadeSections` are `Expression` nodes. Use pattern matching to classify each section type, then compare via `toSource()` to detect duplicates:

```dart
@override
void visitCascadeExpression(CascadeExpression node) {
  final sections = node.cascadeSections;
  if (sections.length < 2) return;

  final seen = <String>{};
  for (final section in sections) {
    final key = _sectionKey(section);
    if (key == null) continue;

    if (!seen.add(key)) {
      rule.reportAtNode(section);
    }
  }
}

static String? _sectionKey(Expression section) {
  return switch (section) {
    // ..field = value or ..[index] = value
    AssignmentExpression(:final leftHandSide, :final rightHandSide) =>
      'assign:${leftHandSide.toSource()}=${rightHandSide.toSource()}',
    // ..method(args)
    MethodInvocation(:final methodName, :final argumentList) =>
      'call:${methodName.name}(${argumentList.arguments.map((a) => a.toSource()).join(',')})',
    // ..[index]
    IndexExpression(:final index) => 'index:${index.toSource()}',
    // ..property
    PropertyAccess(:final propertyName) => 'prop:${propertyName.name}',
    _ => null,
  };
}
```

**Key details:**
- `cascadeSections` contains `Expression` nodes of these types: `AssignmentExpression` (property/index assignment), `MethodInvocation` (method call), `IndexExpression` (index access), `PropertyAccess` (property getter), `FunctionReference` (method tear-off)
- `toSource()` preserves the original source text, making it reliable for equality comparison
- Report at the individual section node (not the whole cascade) so the fix can target just the duplicate

**When to use:** Rules that detect repeated or redundant cascade operations
**Reference:** [avoid_duplicate_cascades.dart](avoid_duplicate_cascades.dart#L65-L95)

---

## 🔄 Changelog

| Date | Agent/Author | Changes |
|------|-------------|---------|
| Feb 12, 2026 | Refactoring | **Major refactoring:** Extracted ~370 lines of duplicated code into reusable utilities:<br>• Added [../type_inference.dart](../type_inference.dart) - Centralized type inference (`inferContextType`, `resolveReturnType`, etc.)<br>• Added [../class_suffix_validator.dart](../class_suffix_validator.dart) - Base class for suffix rules<br>• Added [../text_distance.dart](../text_distance.dart) - String distance utilities (`computeEditDistance`)<br>• Updated 7 rules to use new utilities<br>• Reduced suffix rules from ~55 lines to ~20 lines each |
| Feb 14, 2026 | prefer_iterable_of | Added recipes for factory constructor detection (InstanceCreation vs MethodInvocation duality) and extracting generic element types from collections. |
| Feb 14, 2026 | avoid_accessing_collections_by_constant_index | Added `addIndexExpression` to cheat sheet, recipes for loop body detection and constant identifier checking (VariableElement vs PropertyAccessorElement). |
| Feb 14, 2026 | avoid_cascade_after_if_null | Added `addCascadeExpression` to cheat sheet, recipe for analyzing cascade expression targets and operator precedence. |
| Feb 14, 2026 | avoid_collection_equality_checks | Added `addBinaryExpression` to cheat sheet, recipe for analyzing binary expression operators and checking const expressions. |
| Feb 14, 2026 | avoid_collection_methods_with_unrelated_types | Added recipes for checking unrelated types (no subtype relationship), extracting Map key/value types, and analyzing MethodInvocation on collection targets with `realTarget`. |
| Feb 14, 2026 | avoid_commented_out_code | Added `addCompilationUnit` to cheat sheet, recipes for token stream traversal (comment analysis via `precedingComments`) and offset-based reporting/fixing (`reportAtOffset`, `diagnosticOffset`/`diagnosticLength`, `unitResult.content`). |
| Feb 17, 2026 | avoid_duplicate_cascades | Added recipe for comparing cascade sections for duplicates using pattern matching on section types and `toSource()` equality. Documents all cascade section expression types (AssignmentExpression, MethodInvocation, IndexExpression, PropertyAccess, FunctionReference). |

---

**Happy linting! 🎉**
