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
- [Type Checking](#-type-checking-patterns)
- [AST Navigation](#-ast-navigation-patterns)
- [Type Inference & Context](#-type-inference--context)
- [Visitor Patterns](#-visitor-patterns)
- [Reporting Issues & Quick Fixes](#-reporting--quick-fixes)
- [Utility Functions](#-utility-functions)
- [Analyzer 10.0.2 APIs](#-analyzer-1002-specific-apis)
- [Common Recipes](#-common-recipes)
- [Testing & Registration](#-testing--registration)

---

## 🎯 Rule Structure Template

### Minimal Lint Rule

Every lint rule follows this structure:

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

### Getting Context Type from Parent

Complex pattern for determining expected type from context:

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

**Reference:** [prefer_shorthands_with_static_fields.dart](prefer_shorthands_with_static_fields.dart#L133-L185)

### Getting Return Type

```dart
DartType? _getReturnType(AstNode node) {
  final function = node.thisOrAncestorOfType<FunctionBody>();
  if (function == null) return null;
  
  final parent = function.parent;
  return switch (parent) {
    FunctionExpression(:final declaredElement?) => 
      declaredElement.returnType,
    MethodDeclaration(:final declaredElement?) => 
      declaredElement.returnType,
    _ => null,
  };
}
```

**Reference:** [prefer_shorthands_with_static_fields.dart](prefer_shorthands_with_static_fields.dart#L187-L203)

### Getting Switch Expression Type

```dart
DartType? _getSwitchExpressionType(SwitchCase caseNode) {
  final switchStmt = caseNode.parent;
  if (switchStmt is! SwitchStatement) return null;
  
  return switchStmt.expression.staticType;
}
```

**Reference:** [prefer_shorthands_with_static_fields.dart](prefer_shorthands_with_static_fields.dart#L205-L212)

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

### Available Helpers

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
| Classes | `registry.addClassDeclaration(this, visitor)` |
| Object creation | `registry.addInstanceCreationExpression(this, visitor)` |
| Method calls | `registry.addMethodInvocation(this, visitor)` |
| Properties | `registry.addPropertyAccess(this, visitor)` |
| Prefixed IDs | `registry.addPrefixedIdentifier(this, visitor)` |
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

---

## 🔄 Changelog

| Date | Agent/Author | Changes |
|------|-------------|---------|
| Feb 2026 | Initial creation | Extracted patterns from 18 existing rules |

**Remember:** When you discover new patterns, update this document following the [Meta-Instructions](#-meta-instructions-for-agents).

---

**Happy linting! 🎉**
