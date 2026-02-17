# Lint Rule Implementation Cookbook — Recipes & Testing

## 📚 About This Document

This document contains **copy-paste ready recipes** for common lint rule patterns, plus testing and registration guides. For foundational patterns (rule structure, type checking, AST navigation, etc.), see [rules-patterns.md](rules-patterns.md).

**Target Audience:** AI agents and developers implementing new lint rules
**Analyzer Version:** ^10.0.2
**Last Updated:** February 2026

---

## 🔄 META-INSTRUCTIONS FOR AGENTS

**You MUST update this document when you discover new recipes.** Also update the lean quick reference at `lib/src/rules/CLAUDE.md` with a brief mention.

When adding a recipe, include:
- **Working code example** (tested and verified)
- **File reference** (e.g., `[rule_name.dart](../../../lib/src/rules/rule_name.dart#L10-L20)`)
- **"When to use"** description
- **Key details** / gotchas if any

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

**Reference:** [use_bloc_suffix.dart](../../../lib/src/rules/use_bloc_suffix.dart#L44-L67)

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

**Reference:** [prefer_shorthands_with_static_fields.dart](../../../lib/src/rules/prefer_shorthands_with_static_fields.dart#L133-L185)

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
import 'package:many_lints/src/ast_node_analysis.dart';

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

**Reference:** [prefer_align_over_container.dart](../../../lib/src/rules/prefer_align_over_container.dart#L42-L50)

### Recipe: Extract Single Return Expression

```dart
import 'package:many_lints/src/ast_node_analysis.dart';

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

**Reference:** [ast_node_analysis.dart](../../../lib/src/ast_node_analysis.dart)

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

**Reference:** [prefer_center_over_align.dart](../../../lib/src/rules/prefer_center_over_align.dart#L40-L70)

---

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
**Reference:** [prefer_iterable_of.dart](../../../lib/src/rules/prefer_iterable_of.dart#L53-L76)

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
**Reference:** [prefer_iterable_of.dart](../../../lib/src/rules/prefer_iterable_of.dart#L122-L135)

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
**Reference:** [avoid_accessing_collections_by_constant_index.dart](../../../lib/src/rules/avoid_accessing_collections_by_constant_index.dart#L57-L75)

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
**Reference:** [avoid_accessing_collections_by_constant_index.dart](../../../lib/src/rules/avoid_accessing_collections_by_constant_index.dart#L78-L118)

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
**Reference:** [avoid_cascade_after_if_null.dart](../../../lib/src/rules/avoid_cascade_after_if_null.dart#L55-L63)

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
**Reference:** [avoid_collection_equality_checks.dart](../../../lib/src/rules/avoid_collection_equality_checks.dart#L64-L90)

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
**Reference:** [avoid_collection_methods_with_unrelated_types.dart](../../../lib/src/rules/avoid_collection_methods_with_unrelated_types.dart#L201-L235)

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
**Reference:** [avoid_collection_methods_with_unrelated_types.dart](../../../lib/src/rules/avoid_collection_methods_with_unrelated_types.dart#L173-L184)

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
**Reference:** [avoid_collection_methods_with_unrelated_types.dart](../../../lib/src/rules/avoid_collection_methods_with_unrelated_types.dart#L86-L143)

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
**Reference:** [avoid_commented_out_code.dart](../../../lib/src/rules/avoid_commented_out_code.dart#L47-L97)

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
**Reference:** [avoid_commented_out_code_fix.dart](../../../lib/src/fixes/avoid_commented_out_code_fix.dart#L27-L49)

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
**Reference:** [avoid_duplicate_cascades.dart](../../../lib/src/rules/avoid_duplicate_cascades.dart#L65-L95)

---

### Recipe: Get Top-Level Declaration Names (Non-Deprecated API)

Different declaration types use different APIs to access their name token in analyzer 10.0.2. Some use `name` (not deprecated), others require `namePart.typeName` or `primaryConstructor.typeName`:

```dart
final topLevelNames = <String>{};
for (final declaration in compilationUnit.declarations) {
  switch (declaration) {
    case ClassDeclaration(:final namePart):
      topLevelNames.add(namePart.typeName.lexeme);
    case MixinDeclaration(:final name):
      topLevelNames.add(name.lexeme);
    case EnumDeclaration(:final namePart):
      topLevelNames.add(namePart.typeName.lexeme);
    case GenericTypeAlias(:final name):
      topLevelNames.add(name.lexeme);
    case FunctionTypeAlias(:final name):
      topLevelNames.add(name.lexeme);
    case ExtensionTypeDeclaration(:final primaryConstructor):
      topLevelNames.add(primaryConstructor.typeName.lexeme);
    default:
      break;
  }
}
```

**Key details:**
- `ClassDeclaration.name` → **DEPRECATED**, use `namePart.typeName`
- `EnumDeclaration.name` → **DEPRECATED**, use `namePart.typeName`
- `ExtensionTypeDeclaration.name` → **DEPRECATED**, use `primaryConstructor.typeName`
- `MixinDeclaration.name` → NOT deprecated, use directly
- `GenericTypeAlias.name` / `FunctionTypeAlias.name` → NOT deprecated (inherited from `TypeAlias`)
- `ClassNamePart` (sealed class) has `.typeName` (Token) and `.typeParameters` (TypeParameterList?)

**When to use:** Rules that need to collect or check all type names declared in a file
**Reference:** [avoid_generics_shadowing.dart](../../../lib/src/rules/avoid_generics_shadowing.dart#L50-L67)

---

### Recipe: Visit TypeParameter Declarations Across the File

Use `addCompilationUnit` + `RecursiveAstVisitor` to find all `TypeParameter` nodes across the file:

```dart
@override
void registerNodeProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);
  registry.addCompilationUnit(this, visitor);
}

// In the CompilationUnit visitor:
@override
void visitCompilationUnit(CompilationUnit node) {
  // Collect context (e.g., top-level names)...

  // Use RecursiveAstVisitor to find all TypeParameter nodes
  final checker = _TypeParameterChecker(rule, topLevelNames);
  node.visitChildren(checker);
}

class _TypeParameterChecker extends RecursiveAstVisitor<void> {
  @override
  void visitTypeParameter(TypeParameter node) {
    final name = node.name.lexeme;
    // Check the type parameter...
    super.visitTypeParameter(node);
  }
}
```

**Key details:**
- `TypeParameter.name` returns a `Token` (the type parameter name)
- `TypeParameter.parent` is `TypeParameterList`
- `TypeParameterList.parent` is the declaring scope (ClassDeclaration, MethodDeclaration, etc.)
- `TypeParameterList.typeParameters` gives all sibling type parameters

**When to use:** Rules that analyze type parameters across all declarations in a file
**Reference:** [avoid_generics_shadowing.dart](../../../lib/src/rules/avoid_generics_shadowing.dart#L78-L94)

---

### Recipe: Analyze If-Case Patterns (Dart 3 Pattern Matching)

Register `addIfStatement` to visit `IfStatement` nodes. When using if-case syntax, the `caseClause` property is non-null and contains the pattern AST:

```dart
@override
void registerNodeProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);
  registry.addIfStatement(this, visitor);
}

@override
void visitIfStatement(IfStatement node) {
  final caseClause = node.caseClause;
  if (caseClause == null) return; // Not an if-case statement

  final pattern = caseClause.guardedPattern.pattern;
  final whenClause = caseClause.guardedPattern.whenClause; // Optional guard

  // Analyze the pattern tree
  if (pattern is LogicalAndPattern) {
    final left = pattern.leftOperand;   // DartPattern
    final right = pattern.rightOperand; // DartPattern

    if (left is RelationalPattern) {
      // left.operator.lexeme → '!=', '==', '>', '<', etc.
      // left.operand → Expression (e.g., NullLiteral)
    }

    if (right is DeclaredVariablePattern) {
      // right.keyword → Token? ('final', 'var', or null)
      // right.type → TypeAnnotation? (e.g., NamedType for 'String')
      // right.name → Token (variable name)
    }
  }
}
```

**Key AST types for patterns:**
- `CaseClause` — wraps `guardedPattern` (pattern + optional `when` guard)
- `GuardedPattern` — contains `pattern` (DartPattern) and `whenClause` (WhenClause?)
- `LogicalAndPattern` — `&&` combinator with `leftOperand` / `rightOperand`
- `LogicalOrPattern` — `||` combinator with `leftOperand` / `rightOperand`
- `RelationalPattern` — `!= null`, `> 5`, `== 'foo'` etc. with `operator` (Token) and `operand` (Expression)
- `DeclaredVariablePattern` — `final field`, `var x`, `final String field` with `keyword`, `type`, `name`
- `NullCheckPattern` — postfix `?` (e.g., `final field?`)
- `NullAssertPattern` — postfix `!`
- `ConstantPattern` — literal values in patterns
- `WildcardPattern` — `_` pattern

**When to use:** Rules that analyze Dart 3 pattern matching in if-case, switch expressions, or switch statements
**Reference:** [prefer_simpler_patterns_null_check.dart](../../../lib/src/rules/prefer_simpler_patterns_null_check.dart#L49-L68)

---

### Recipe: Detect Property Access on Typed Target (PrefixedIdentifier vs PropertyAccess)

**⚠️ Important:** When analyzing `target.property.method()` patterns, the AST for `target.property` differs depending on the complexity of `target`:

- **Simple identifier** (`map.keys`): Parsed as `PrefixedIdentifier` (prefix=`map`, identifier=`keys`)
- **Complex expression** (`maps.first.keys`): Parsed as `PropertyAccess` (target=`maps.first`, propertyName=`keys`)

You must handle **both** node types when matching:

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'contains') return;

  final target = node.target;

  // Simple: map.keys.contains(x) — PrefixedIdentifier
  if (target case PrefixedIdentifier(
    identifier: SimpleIdentifier(name: 'keys'),
    prefix: SimpleIdentifier(staticType: final mapType?),
  ) when _mapChecker.isAssignableFromType(mapType)) {
    rule.reportAtNode(node);
    return;
  }

  // Complex: expr.keys.contains(x) — PropertyAccess
  if (target case PropertyAccess(
    propertyName: SimpleIdentifier(name: 'keys'),
    target: Expression(staticType: final mapType?),
  ) when _mapChecker.isAssignableFromType(mapType)) {
    rule.reportAtNode(node);
  }
}
```

**Similarly in fixes**, extract the map expression differently:
```dart
final String mapSource;
if (keysAccess is PrefixedIdentifier) {
  mapSource = keysAccess.prefix.toSource();
} else if (keysAccess is PropertyAccess) {
  mapSource = keysAccess.target!.toSource();
} else {
  return;
}
```

**When to use:** Any rule that checks `target.property.method()` where `target` could be a simple variable or a complex expression
**Reference:** [avoid_map_keys_contains.dart](../../../lib/src/rules/avoid_map_keys_contains.dart#L49-L71), [avoid_map_keys_contains_fix.dart](../../../lib/src/fixes/avoid_map_keys_contains_fix.dart#L30-L41)

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

**Reference:** [use_bloc_suffix_test.dart](../../../test/use_bloc_suffix_test.dart#L1-L40)

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

**In [many_lints.dart](../../../lib/many_lints.dart):**

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

**Reference:** [many_lints.dart](../../../lib/many_lints.dart)

---

## 🎓 Learning Path

**For new rule implementers:**

1. Start with [Rule Structure Template](rules-patterns.md#-rule-structure-template)
2. Choose appropriate [Node Registration](rules-patterns.md#node-registration)
3. Use [Type Checking](rules-patterns.md#-type-checking-patterns) if you need type analysis
4. Navigate AST with [AST Navigation](rules-patterns.md#-ast-navigation-patterns)
5. Check the recipes above for your specific use case
6. Implement [Quick Fix](rules-patterns.md#quick-fix-structure) if applicable
7. Write [Tests](#test-structure) following the pattern
8. [Register](#registration-in-plugin) your rule in the plugin

**For complex patterns:**
- Study similar existing rules in `lib/src/rules/`
- Use [Visitor Patterns](rules-patterns.md#-visitor-patterns) for deep analysis
- Leverage [Utility Functions](rules-patterns.md#-utility-functions) to avoid reinventing wheels

---

## 🔄 Changelog

| Date | Agent/Author | Changes |
|------|-------------|---------|
| Feb 12, 2026 | Refactoring | **Major refactoring:** Extracted ~370 lines of duplicated code into reusable utilities:<br>- Added [type_inference.dart](../../../lib/src/type_inference.dart) - Centralized type inference (`inferContextType`, `resolveReturnType`, etc.)<br>- Added [class_suffix_validator.dart](../../../lib/src/class_suffix_validator.dart) - Base class for suffix rules<br>- Added [text_distance.dart](../../../lib/src/text_distance.dart) - String distance utilities (`computeEditDistance`)<br>- Updated 7 rules to use new utilities<br>- Reduced suffix rules from ~55 lines to ~20 lines each |
| Feb 14, 2026 | prefer_iterable_of | Added recipes for factory constructor detection (InstanceCreation vs MethodInvocation duality) and extracting generic element types from collections. |
| Feb 14, 2026 | avoid_accessing_collections_by_constant_index | Added `addIndexExpression` to cheat sheet, recipes for loop body detection and constant identifier checking (VariableElement vs PropertyAccessorElement). |
| Feb 14, 2026 | avoid_cascade_after_if_null | Added `addCascadeExpression` to cheat sheet, recipe for analyzing cascade expression targets and operator precedence. |
| Feb 14, 2026 | avoid_collection_equality_checks | Added `addBinaryExpression` to cheat sheet, recipe for analyzing binary expression operators and checking const expressions. |
| Feb 14, 2026 | avoid_collection_methods_with_unrelated_types | Added recipes for checking unrelated types (no subtype relationship), extracting Map key/value types, and analyzing MethodInvocation on collection targets with `realTarget`. |
| Feb 14, 2026 | avoid_commented_out_code | Added `addCompilationUnit` to cheat sheet, recipes for token stream traversal (comment analysis via `precedingComments`) and offset-based reporting/fixing (`reportAtOffset`, `diagnosticOffset`/`diagnosticLength`, `unitResult.content`). |
| Feb 17, 2026 | avoid_duplicate_cascades | Added recipe for comparing cascade sections for duplicates using pattern matching on section types and `toSource()` equality. Documents all cascade section expression types (AssignmentExpression, MethodInvocation, IndexExpression, PropertyAccess, FunctionReference). |
| Feb 17, 2026 | avoid_generics_shadowing | Added recipes for getting top-level declaration names with non-deprecated API (ClassDeclaration→namePart.typeName, EnumDeclaration→namePart.typeName, ExtensionTypeDeclaration→primaryConstructor.typeName) and visiting TypeParameter declarations across a file using RecursiveAstVisitor. |
| Feb 17, 2026 | prefer_simpler_patterns_null_check | Added `addIfStatement` to cheat sheet, recipe for analyzing if-case patterns (CaseClause, GuardedPattern, LogicalAndPattern, RelationalPattern, DeclaredVariablePattern, NullCheckPattern). Documents all key DartPattern subtypes for Dart 3 pattern matching analysis. |
| Feb 18, 2026 | avoid_map_keys_contains | Added recipe for PrefixedIdentifier vs PropertyAccess duality when detecting `target.property.method()` patterns. Simple identifiers (`map.keys`) parse as PrefixedIdentifier, complex expressions (`maps.first.keys`) parse as PropertyAccess — must handle both. |
