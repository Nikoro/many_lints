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

### Recipe: Validate Function Call Arguments by Name and Type Category

Register `addMethodInvocation` and match on `methodName.name` to intercept specific function calls (e.g., `expect()`). Then analyze argument types against expected categories:

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'expect') return;

  final args = node.argumentList.arguments;
  if (args.length < 2) return;

  final actualType = args[0].staticType;
  if (actualType == null || actualType is DynamicType) return;

  final matcherExpr = args[1];

  // Resolve matcher name from identifier or method call
  final String? matcherName;
  if (matcherExpr is SimpleIdentifier) {
    matcherName = matcherExpr.name;
  } else if (matcherExpr is MethodInvocation) {
    matcherName = matcherExpr.methodName.name;
  } else {
    return;
  }

  // Check compatibility by category
  if (_isIncompatible(actualType, matcherName)) {
    rule.reportAtNode(matcherExpr, arguments: [matcherName, ...]);
  }
}
```

**Type category checks:**
```dart
// Check nullability
static bool _isNullable(DartType type) {
  return type.nullabilitySuffix == NullabilitySuffix.question;
}

// Check if type is/subtypes a dart:core type by name
static bool _isOrSubtypeOf(InterfaceType type, String targetName) {
  if (type.element.name == targetName) return true;
  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == targetName) return true;
  }
  return false;
}
```

**Key details:**
- Import `NullabilitySuffix` from `package:analyzer/dart/element/nullability_suffix.dart`
- The matcher expression can be `SimpleIdentifier` (e.g., `isNull`) or `MethodInvocation` (e.g., `hasLength(1)`)
- Use `_isOrSubtypeOf` for checking against dart:core types like `num`, `Iterable`, `Map`, `String`
- Skip `DynamicType` actual values since the type is unknown at compile time

**When to use:** Rules that validate argument compatibility in specific function calls
**Reference:** [avoid_misused_test_matchers.dart](../../../lib/src/rules/avoid_misused_test_matchers.dart#L82-L218)

---

### Recipe: Analyze Try-Catch Clauses (CatchClause Body Inspection)

Register `addTryStatement` to visit `TryStatement` nodes. Iterate `catchClauses` and inspect each `CatchClause.body` for specific statement patterns:

```dart
@override
void registerNodeProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);
  registry.addTryStatement(this, visitor);
}

@override
void visitTryStatement(TryStatement node) {
  for (final catchClause in node.catchClauses) {
    final statements = catchClause.body.statements;
    if (statements.length != 1) continue;

    final statement = statements.first;
    if (statement is! ExpressionStatement) continue;

    if (statement.expression is RethrowExpression) {
      rule.reportAtNode(catchClause);
    }
  }
}
```

**Key AST types for try-catch:**
- `TryStatement` — has `body` (Block), `catchClauses` (NodeList<CatchClause>), `finallyBlock` (Block?), `finallyKeyword` (Token?)
- `CatchClause` — has `body` (Block), `onKeyword` (Token?), `exceptionType` (TypeAnnotation?), `catchKeyword` (Token?), `exceptionParameter` (CatchClauseParameter?), `stackTraceParameter` (CatchClauseParameter?)
- `RethrowExpression` — has `rethrowKeyword` (Token). Appears inside `ExpressionStatement`
- `Block.statements` — `NodeList<Statement>` for accessing the body's statements

**When to use:** Rules that analyze exception handling patterns (rethrow-only, empty catch, catch-all, etc.)
**Reference:** [avoid_only_rethrow.dart](../../../lib/src/rules/avoid_only_rethrow.dart#L68-L82)

---

### Recipe: Analyze Return Statements in Async Try-Catch Context

Register `addReturnStatement` to visit `ReturnStatement` nodes, then walk up the parent chain to determine if (a) the node is inside a try body or catch clause, and (b) the enclosing function is async:

```dart
@override
void registerNodeProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);
  registry.addReturnStatement(this, visitor);
}

@override
void visitReturnStatement(ReturnStatement node) {
  final expression = node.expression;
  if (expression == null) return;

  // Already awaited
  if (expression is AwaitExpression) return;

  // Check static type is Future
  final type = expression.staticType;
  if (type is! InterfaceType) return;
  final name = type.element.name;
  if (name != 'Future' && name != 'FutureOr') return;

  // Check enclosing context
  if (!_isInsideTryCatch(node)) return;
  if (!_isEnclosingFunctionAsync(node)) return;

  rule.reportAtNode(expression);
}
```

**Async function detection (walk parent chain):**
```dart
static bool _isEnclosingFunctionAsync(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionExpression) {
      return current.body.isAsynchronous;
    }
    if (current is MethodDeclaration) {
      return current.body.isAsynchronous;
    }
    current = current.parent;
  }
  return false;
}
```

**Try-catch containment check (with function boundary):**
```dart
static bool _isInsideTryCatch(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    // Stop at function boundaries
    if (current is FunctionExpression ||
        current is FunctionDeclaration ||
        current is MethodDeclaration) {
      return false;
    }
    if (current is TryStatement) {
      // Verify node is in try body or catch clause, not finally
      return _isDescendantOf(node, current.body) ||
          current.catchClauses.any((c) => _isDescendantOf(node, c));
    }
    current = current.parent;
  }
  return false;
}

static bool _isDescendantOf(AstNode node, AstNode ancestor) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current == ancestor) return true;
    current = current.parent;
  }
  return false;
}
```

**Key details:**
- `ReturnStatement.expression` is nullable (bare `return;` has no expression)
- `FunctionBody.isAsynchronous` is `true` for both `async` and `async*` functions
- Stop parent-chain walking at function boundaries to avoid false positives for nested closures
- `_isDescendantOf` is needed to distinguish try body, catch clauses, and finally block
- Import `InterfaceType` from `package:analyzer/dart/element/type.dart` for Future type check

**When to use:** Rules that analyze return behavior within specific scoping contexts (try-catch, loops, closures)
**Reference:** [prefer_return_await.dart](../../../lib/src/rules/prefer_return_await.dart#L70-L139)

---

### Recipe: Find Specific Expressions Inside Catch Blocks (RecursiveAstVisitor with Boundary)

Register `addTryStatement`, then use a `RecursiveAstVisitor` to traverse each `CatchClause.body` for specific expression types, stopping at function boundaries to avoid false positives from closures/nested functions:

```dart
@override
void visitTryStatement(TryStatement node) {
  for (final catchClause in node.catchClauses) {
    final finder = _ThrowFinder(rule);
    catchClause.body.visitChildren(finder);
  }
}

class _ThrowFinder extends RecursiveAstVisitor<void> {
  final MyRule rule;

  _ThrowFinder(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    rule.reportAtNode(node);
    super.visitThrowExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Don't traverse into closures — not in catch scope
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Don't traverse into local function declarations
  }
}
```

**Key details:**
- Override `visitFunctionExpression` and `visitFunctionDeclaration` with empty bodies to prevent traversal into closures and local functions
- `ThrowExpression` contains the `throw` keyword + the thrown expression — `node.expression` gives the thrown value
- `ThrowExpression` does NOT include `rethrow` — that's `RethrowExpression` (a separate AST type)
- Use `catchClause.body.visitChildren(finder)` to start traversal from the catch body

**When to use:** Rules that detect specific expression/statement patterns inside catch blocks while respecting function boundaries
**Reference:** [avoid_throw_in_catch_block.dart](../../../lib/src/rules/avoid_throw_in_catch_block.dart#L73-L95)

---

### Recipe: Add Parameters to Catch Clauses in Quick Fix

When a fix needs to add a stack trace parameter (or exception parameter) to a catch clause:

```dart
void _addStackTraceParameter(
  dynamic builder,
  CatchClause catchClause,
  String stackParam,
) {
  final exceptionParam = catchClause.exceptionParameter;

  if (exceptionParam != null) {
    // Has exception parameter: `catch (e)` → `catch (e, stackTrace)`
    builder.addSimpleInsertion(exceptionParam.end, ', $stackParam');
  } else if (catchClause.catchKeyword != null) {
    // Has `catch` keyword but no params (edge case)
    final catchKeyword = catchClause.catchKeyword!;
    builder.addSimpleInsertion(catchKeyword.end, ' (_, $stackParam)');
  } else {
    // Only `on Type` without `catch`: `on Type {` → `on Type catch (_, stackTrace) {`
    final body = catchClause.body;
    builder.addSimpleInsertion(
      body.leftBracket.offset,
      'catch (_, $stackParam) ',
    );
  }
}
```

**Key AST properties for catch parameter manipulation:**
- `CatchClause.exceptionParameter` — `CatchClauseParameter?` for the exception variable
- `CatchClause.stackTraceParameter` — `CatchClauseParameter?` for the stack trace variable
- `CatchClause.catchKeyword` — `Token?` (null when only `on Type` without `catch`)
- `CatchClauseParameter.name` — `Token` (the parameter name)
- `CatchClauseParameter.end` — character offset right after the parameter name

**When to use:** Fixes that need to modify catch clause parameters (add stack trace, add exception variable, etc.)
**Reference:** [avoid_throw_in_catch_block_fix.dart](../../../lib/src/fixes/avoid_throw_in_catch_block_fix.dart#L63-L84)

---

### Recipe: Detect Unassigned Method Invocation Return Values

Register `addMethodInvocation` and check if the call is used as an expression statement (i.e., the return value is discarded). Combine with return type checking to target specific methods:

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'listen') return;

  // Check the return type of the method call
  final returnType = node.staticType;
  if (returnType is! InterfaceType) return;
  if (!_isExpectedType(returnType)) return;

  // Only flag if used as an expression statement (not assigned, returned,
  // or passed as an argument)
  if (node.parent is! ExpressionStatement) return;

  rule.reportAtNode(node);
}

static bool _isExpectedType(InterfaceType type) {
  if (type.element.name == 'StreamSubscription') {
    return type.element.library.identifier.startsWith('dart:async');
  }
  for (final supertype in type.element.allSupertypes) {
    if (supertype.element.name == 'StreamSubscription' &&
        supertype.element.library.identifier.startsWith('dart:async')) {
      return true;
    }
  }
  return false;
}
```

**Key details:**
- `node.staticType` gives the return type of the method invocation
- `node.parent is ExpressionStatement` means the return value is discarded (not assigned, returned, or used as argument)
- Check `library.identifier.startsWith('dart:async')` to match dart:async types without TypeChecker
- This pattern generalizes to any rule that warns about ignored return values

**When to use:** Rules that detect method calls whose return values should be stored (e.g., stream subscriptions, futures, disposables)
**Reference:** [avoid_unassigned_stream_subscriptions.dart](../../../lib/src/rules/avoid_unassigned_stream_subscriptions.dart#L49-L73)

---

### Recipe: Detect Negative Integer Literals in Binary Expressions

Negative numbers like `-1` are NOT parsed as `IntegerLiteral` with a negative value. Instead, they are parsed as `PrefixExpression(MINUS, IntegerLiteral(1))`. Use pattern matching to detect them:

```dart
import 'package:analyzer/dart/ast/token.dart';

static bool _isNegativeOne(Expression expr) {
  if (expr case PrefixExpression(
    operator: Token(type: TokenType.MINUS),
    operand: IntegerLiteral(value: 1),
  )) {
    return true;
  }
  return false;
}
```

**Combined with BinaryExpression for `.indexOf() == -1` detection:**
```dart
@override
void visitBinaryExpression(BinaryExpression node) {
  final op = node.operator.type;
  if (op != TokenType.EQ_EQ && op != TokenType.BANG_EQ) return;

  final left = node.leftOperand;
  final right = node.rightOperand;

  // x.indexOf(item) == -1 or x.indexOf(item) != -1
  if (_isIndexOfCall(left) && _isNegativeOne(right)) {
    rule.reportAtNode(node);
    return;
  }

  // Reversed: -1 == x.indexOf(item) or -1 != x.indexOf(item)
  if (_isNegativeOne(left) && _isIndexOfCall(right)) {
    rule.reportAtNode(node);
  }
}

static bool _isIndexOfCall(Expression expr) {
  return expr is MethodInvocation && expr.methodName.name == 'indexOf';
}
```

**Key details:**
- `-1` in source code is `PrefixExpression(MINUS, IntegerLiteral(1))`, NOT `IntegerLiteral(-1)`
- Always check both operand orders for commutative comparisons (user may write `x == -1` or `-1 == x`)
- `IntegerLiteral.value` returns `int?` — the `1` in `-1` has value `1`, not `-1`

**When to use:** Rules that detect comparisons against negative integer literals
**Reference:** [prefer_contains.dart](../../../lib/src/rules/prefer_contains.dart#L68-L77)

---

### Recipe: Check If Ancestor Overrides Specific Members (== and hashCode)

Walk `element.allSupertypes` to check if any ancestor defines specific methods/getters. Use `InterfaceType.methods` and `InterfaceType.getters` (NOT `.accessors` which doesn't exist in 10.0.2). For the current class, use AST-level checks via `MethodDeclaration.isOperator` and `MethodDeclaration.isGetter`:

```dart
@override
void visitClassDeclaration(ClassDeclaration node) {
  final element = node.declaredFragment?.element;
  if (element == null) return;

  // Check ancestors via InterfaceType
  for (final supertype in element.allSupertypes) {
    if (supertype.element.name == 'Object') continue;

    // Check methods on the type
    final hasEqualsOp = supertype.methods.any(
      (m) => m.name == '==' && !m.isAbstract,
    );
    // Check getters on the type
    final hasHashCode = supertype.getters.any(
      (g) => g.name == 'hashCode' && !g.isAbstract,
    );

    if (hasEqualsOp && hasHashCode) { /* ancestor overrides equality */ }
  }

  // Check current class via AST
  final body = node.body;
  if (body is! BlockClassBody) return;

  final overridesEquals = body.members.any(
    (m) => m is MethodDeclaration && m.isOperator && m.name.lexeme == '==',
  );
  final overridesHashCode = body.members.any(
    (m) => m is MethodDeclaration && m.isGetter && m.name.lexeme == 'hashCode',
  );
}
```

**Key details:**
- `InterfaceType.methods` → `List<MethodElement>` (not deprecated in 10.0.2)
- `InterfaceType.getters` → `List<GetterElement>` (replaces old `accessors`)
- `MethodElement.name` / `GetterElement.name` → `String?`
- `MethodDeclaration.isOperator` → true for `operator ==`
- `MethodDeclaration.isGetter` → true for `get hashCode`
- `element.allSupertypes` includes the full chain (grandparent, mixins, etc.)
- Skip `Object` to avoid false positives on default `==`/`hashCode`

**When to use:** Rules that check inheritance patterns for specific member overrides
**Reference:** [prefer_overriding_parent_equality.dart](../../../lib/src/rules/prefer_overriding_parent_equality.dart#L68-L97)

---

### Recipe: Detect ObjectPattern by Type Name in Switch/If-Case Patterns

Register `addSwitchExpression`, `addSwitchStatement`, and `addIfStatement` to visit all contexts where patterns appear. Walk the pattern tree recursively to find `ObjectPattern` nodes matching a specific type:

```dart
@override
void registerNodeProcessors(
  RuleVisitorRegistry registry,
  RuleContext context,
) {
  final visitor = _Visitor(this);
  registry.addSwitchExpression(this, visitor);
  registry.addSwitchStatement(this, visitor);
  registry.addIfStatement(this, visitor);
}

@override
void visitSwitchExpression(SwitchExpression node) {
  for (final caseNode in node.cases) {
    _checkPattern(caseNode.guardedPattern.pattern);
  }
}

@override
void visitSwitchStatement(SwitchStatement node) {
  for (final member in node.members) {
    if (member is SwitchPatternCase) {
      _checkPattern(member.guardedPattern.pattern);
    }
  }
}

@override
void visitIfStatement(IfStatement node) {
  final caseClause = node.caseClause;
  if (caseClause == null) return;
  _checkPattern(caseClause.guardedPattern.pattern);
}

void _checkPattern(DartPattern pattern) {
  if (pattern is ObjectPattern &&
      pattern.type.name.lexeme == 'Object' &&
      pattern.fields.isEmpty) {
    rule.reportAtNode(pattern);
    return;
  }

  // Walk nested patterns
  if (pattern is LogicalAndPattern) {
    _checkPattern(pattern.leftOperand);
    _checkPattern(pattern.rightOperand);
  }
  if (pattern is LogicalOrPattern) {
    _checkPattern(pattern.leftOperand);
    _checkPattern(pattern.rightOperand);
  }
}
```

**Key AST types for ObjectPattern:**
- `ObjectPattern` — matches `Type()` or `Type(field: pattern)` syntax
  - `type: NamedType` — the type name (access via `type.name.lexeme`)
  - `fields: NodeList<PatternField>` — field destructurings (empty for bare `Object()`)
- `SwitchExpressionCase.guardedPattern.pattern` — the pattern in switch expression cases
- `SwitchPatternCase.guardedPattern.pattern` — the pattern in switch statement cases (Dart 3 style)
- `SwitchPatternCase` is a `SwitchMember` — use type check when iterating `node.members`

**When to use:** Rules that analyze pattern types in switch expressions, switch statements, and if-case patterns
**Reference:** [prefer_wildcard_pattern.dart](../../../lib/src/rules/prefer_wildcard_pattern.dart#L59-L98)

---

### Recipe: Cross-Method Call Pairing (addListener/removeListener Across Methods)

Register `addClassDeclaration` and use `RecursiveAstVisitor` collectors to gather method calls from different class methods, then pair them by comparing `toSource()` of target and arguments:

```dart
@override
void visitClassDeclaration(ClassDeclaration node) {
  final element = node.declaredFragment?.element;
  if (element == null) return;
  if (!_stateChecker.isSuperOf(element)) return;

  final body = node.body;
  if (body is! BlockClassBody) return;
  final methods = body.members.whereType<MethodDeclaration>();

  // Collect calls from one method (e.g., dispose)
  final disposeMethod = methods.where((m) => m.name.lexeme == 'dispose').firstOrNull;
  final removeCalls = <_ListenerCall>{};
  if (disposeMethod != null) {
    final collector = _MethodCallCollector('removeListener', stopAtFunctions: true);
    disposeMethod.body.visitChildren(collector);
    removeCalls.addAll(collector.calls);
  }

  // Check calls from other methods (e.g., initState)
  for (final method in methods) {
    if (method.name.lexeme != 'initState') continue;
    final collector = _MethodCallCollector('addListener', stopAtFunctions: true);
    method.body.visitChildren(collector);

    for (final addCall in collector.calls) {
      if (!_hasMatch(addCall, removeCalls)) {
        rule.reportAtNode(addCall.node);
      }
    }
  }
}

// Match by comparing toSource() of target and first argument:
static bool _hasMatch(_ListenerCall addCall, Set<_ListenerCall> removeCalls) {
  return removeCalls.any((r) =>
      r.targetSource == addCall.targetSource &&
      r.listenerSource == addCall.listenerSource);
}
```

**Collector with function boundary stopping:**
```dart
class _MethodCallCollector extends RecursiveAstVisitor<void> {
  final String methodName;
  final bool stopAtFunctions;
  final List<_ListenerCall> calls = [];

  _MethodCallCollector(this.methodName, {this.stopAtFunctions = false});

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == methodName && node.argumentList.arguments.isNotEmpty) {
      final target = node.realTarget;
      calls.add(_ListenerCall(
        node: node,
        targetSource: target?.toSource() ?? 'this',
        listenerSource: node.argumentList.arguments.first.toSource(),
      ));
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (stopAtFunctions) return;
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (stopAtFunctions) return;
    super.visitFunctionDeclaration(node);
  }
}
```

**Key details:**
- Use `node.realTarget?.toSource() ?? 'this'` to get the object the method is called on
- Use `args.first.toSource()` to get the callback argument as source text
- Compare source strings for matching (handles field references, method tear-offs, stored callbacks)
- Stop at function boundaries to avoid false positives from closures/nested functions
- `firstOrNull` (from Dart 3) works on `Iterable` directly — no extension needed

**When to use:** Rules that need to verify paired method calls across different class methods (e.g., addListener/removeListener, subscribe/unsubscribe, open/close)
**Reference:** [always_remove_listener.dart](../../../lib/src/rules/always_remove_listener.dart#L66-L102)

---

### Recipe: Check If Widget Is Direct Child of Specific Parent Widget

Walk the AST parent chain from an `InstanceCreationExpression` through intermediate nodes (`ListLiteral`, `NamedExpression`) up to the nearest `ArgumentList` to find the enclosing widget constructor and check its type:

```dart
static bool _isDirectChildOfFlex(InstanceCreationExpression node) {
  AstNode? current = node.parent;
  while (current != null) {
    // Skip list literals (children: [Flexible(...)])
    if (current is ListLiteral) {
      current = current.parent;
      continue;
    }

    // Skip named expressions (child: Flexible(...) or children: [...])
    if (current is NamedExpression) {
      current = current.parent;
      continue;
    }

    // We've reached an argument list — check the parent constructor
    if (current is ArgumentList) {
      final parent = current.parent;
      if (parent is InstanceCreationExpression) {
        final parentElement = parent.constructorName.type.element;
        if (parentElement != null && _flexChecker.isSuperOf(parentElement)) {
          return true;
        }
      }
      return false;
    }

    // Stop at function/method boundaries
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

**Key details:**
- A widget passed as `child:` has the parent chain: `NamedExpression` → `ArgumentList` → `InstanceCreationExpression`
- A widget in `children: [...]` has the chain: `ListLiteral` → `NamedExpression` → `ArgumentList` → `InstanceCreationExpression`
- Always stop at function/method boundaries to avoid false positives from nested closures
- Use `TypeChecker.isSuperOf()` on the parent constructor's element to check against a type hierarchy (e.g., `Flex` covers `Row`, `Column`, `Flex`)

**When to use:** Rules that validate widget placement in the widget tree (e.g., Flexible must be inside Flex, Positioned must be inside Stack)
**Reference:** [avoid_flexible_outside_flex.dart](../../../lib/src/rules/avoid_flexible_outside_flex.dart#L80-L119)

---

### Recipe: Detect Wrapper Widget with Specific Child Type (InstanceCreation + MethodInvocation)

**⚠️ Important:** Widget constructors without `new`/`const` and without explicit type arguments (e.g., `Opacity(...)`, `Image.asset(...)`) are parsed as `MethodInvocation`, NOT `InstanceCreationExpression`. You must register visitors for **both** node types:

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

@override
void visitInstanceCreationExpression(InstanceCreationExpression node) {
  final element = node.constructorName.type.element;
  if (element == null || !_wrapperChecker.isExactly(element)) return;

  _checkChildArgument(node.argumentList, node.constructorName);
}

@override
void visitMethodInvocation(MethodInvocation node) {
  final type = node.staticType;
  if (type == null || !_wrapperChecker.isExactlyType(type)) return;

  _checkChildArgument(node.argumentList, node.methodName);
}

void _checkChildArgument(ArgumentList argumentList, AstNode reportNode) {
  for (final arg in argumentList.arguments.whereType<NamedExpression>()) {
    if (arg.name.label.name == 'child') {
      final childType = arg.expression.staticType;
      if (childType != null &&
          _childChecker.isAssignableFromType(childType)) {
        rule.reportAtNode(reportNode);
      }
      return;
    }
  }
}
```

**Key details:**
- For `InstanceCreationExpression`: check via `node.constructorName.type.element` and report at `node.constructorName`
- For `MethodInvocation`: check via `node.staticType` and report at `node.methodName`
- The child expression's `staticType` works regardless of whether the child is `InstanceCreationExpression` or `MethodInvocation`
- In the fix, handle both `ConstructorName` and `SimpleIdentifier` as the reported node type

**When to use:** Rules that detect widget wrapping patterns (e.g., Opacity wrapping Image, Container wrapping only a child)
**Reference:** [avoid_incorrect_image_opacity.dart](../../../lib/src/rules/avoid_incorrect_image_opacity.dart#L62-L88)

---

### Recipe: Search for Specific Identifiers Inside a Callback Argument

Register `addMethodInvocation` to visit a specific method call (e.g., `setState`), extract the callback argument as `FunctionExpression`, and use `RecursiveAstVisitor` to search its body for specific identifier references. Handle all three forms: bare identifier, prefixed (`context.mounted`), and property access (`this.mounted`):

```dart
@override
void visitMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'setState') return;

  // Get the callback argument
  final args = node.argumentList.arguments;
  if (args.isEmpty) return;
  final callback = args.first;
  if (callback is! FunctionExpression) return;

  // Search for the identifier inside the callback body
  final finder = _IdentifierFinder(rule);
  callback.body.visitChildren(finder);
}

class _IdentifierFinder extends RecursiveAstVisitor<void> {
  final MyRule rule;
  _IdentifierFinder(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'mounted') {
      // Exclude cases handled by visitPrefixedIdentifier/visitPropertyAccess
      final parent = node.parent;
      if (parent is PrefixedIdentifier && parent.identifier == node) return;
      if (parent is PropertyAccess && parent.propertyName == node) return;
      rule.reportAtNode(node);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'mounted') {
      rule.reportAtNode(node); // context.mounted
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'mounted') {
      rule.reportAtNode(node); // this.mounted
    }
    super.visitPropertyAccess(node);
  }
}
```

**Key details:**
- `SimpleIdentifier` catches bare `mounted` — but also fires for `context.mounted` and `this.mounted` children, so exclude those via parent type checks
- `PrefixedIdentifier` catches `context.mounted` (simple variable prefix)
- `PropertyAccess` catches `this.mounted` and complex expressions like `widget.context.mounted`
- The callback argument `args.first` may be a `FunctionExpression` (inline closure) or another expression (method reference) — only analyze closures

**When to use:** Rules that search for specific identifier/property usage inside a callback argument of a method call
**Reference:** [avoid_mounted_in_setstate.dart](../../../lib/src/rules/avoid_mounted_in_setstate.dart#L59-L124)

---

### Recipe: Detect Unnecessary Overrides (Methods, Getters, Setters, Operators, Abstract)

Register `addClassDeclaration` + `addMixinDeclaration` and iterate class members for `MethodDeclaration` nodes with `@override`. Handle five cases:

1. **Abstract members** — `member.isAbstract` (has `EmptyFunctionBody`); must check BEFORE `isGetter`/`isSetter` since abstract getters/setters have both flags
2. **Getters** — body returns `super.getterName` (via `PropertyAccess`)
3. **Setters** — body assigns `super.setterName = param` (via `AssignmentExpression`)
4. **Operators** — body is `BinaryExpression` with `SuperExpression` left operand (NOT `MethodInvocation`)
5. **Regular methods** — body is `MethodInvocation` on `super` with pass-through args

```dart
void _checkMethodDeclaration(MethodDeclaration member) {
  final memberName = member.name.lexeme;

  // Abstract redeclaration — check FIRST (abstract getters/setters also have isGetter/isSetter)
  if (member.isAbstract) {
    rule.reportAtNode(member, arguments: [memberName]);
    return;
  }

  if (member.isGetter) {
    if (_isUnnecessaryGetter(member, memberName)) {
      rule.reportAtNode(member, arguments: [memberName]);
    }
  } else if (member.isSetter) {
    if (_isUnnecessarySetter(member, memberName)) {
      rule.reportAtNode(member, arguments: [memberName]);
    }
  } else {
    if (_isOnlySuperCall(member, memberName)) {
      rule.reportAtNode(member, arguments: [memberName]);
    }
  }
}
```

**Operator override detection via BinaryExpression:**
```dart
// In _isOnlySuperCall, after checking MethodInvocation:
if (method.isOperator && expression is BinaryExpression) {
  return expression.leftOperand is SuperExpression &&
      expression.operator.lexeme == methodName &&
      _isSingleParamPassThrough(method.parameters, expression.rightOperand);
}
```

**Arg pass-through validation:**
```dart
static bool _areArgsPassThrough(FormalParameterList? params, ArgumentList args) {
  if (params == null) return args.arguments.isEmpty;
  final parameters = params.parameters;
  final arguments = args.arguments;
  if (parameters.length != arguments.length) return false;

  for (var i = 0; i < parameters.length; i++) {
    final param = parameters[i];
    final arg = arguments[i];
    final paramName = param.name?.lexeme;
    if (paramName == null) return false;

    if (arg is NamedExpression) {
      if (arg.name.label.name != paramName) return false;
      final expr = arg.expression;
      if (expr is! SimpleIdentifier || expr.name != paramName) return false;
    } else if (arg is SimpleIdentifier) {
      if (arg.name != paramName) return false;
    } else {
      return false;
    }
  }
  return true;
}
```

**Key details:**
- `member.isAbstract` is true for methods/getters/setters with `EmptyFunctionBody` (`;`)
- `super.property` is parsed as `PropertyAccess(SuperExpression, SimpleIdentifier)` — NOT `PrefixedIdentifier`
- `super == other` is `BinaryExpression`, NOT `MethodInvocation` — `method.isOperator` distinguishes operator declarations
- `FormalParameter.name` returns `Token?` — use `.lexeme` to get the string
- Named args have `NamedExpression(name: Label, expression: Expression)` — both label and value must match the parameter name

**When to use:** Rules that detect redundant overrides in any class or mixin
**Reference:** [avoid_unnecessary_overrides.dart](../../../lib/src/rules/avoid_unnecessary_overrides.dart#L71-L210)

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
| Feb 18, 2026 | avoid_misused_test_matchers | Added recipe for validating function call arguments by name and type category. Shows pattern for intercepting specific method calls (e.g., `expect()`), resolving matcher expressions (SimpleIdentifier vs MethodInvocation), and checking type compatibility with `NullabilitySuffix` and `_isOrSubtypeOf`. |
| Feb 18, 2026 | avoid_only_rethrow | Added `addTryStatement` to cheat sheet, recipe for analyzing try-catch clauses (TryStatement, CatchClause body inspection, RethrowExpression detection). Documents all key CatchClause properties. |
| Feb 18, 2026 | prefer_return_await | Added `addReturnStatement` to cheat sheet, recipe for analyzing return statements with async function detection and try-catch context checking. Shows parent-chain walking for async detection via `body.isAsynchronous` and `_isDescendantOf` for try/catch containment. |
| Feb 18, 2026 | avoid_throw_in_catch_block | Added recipe for finding specific expressions inside catch blocks using RecursiveAstVisitor with function boundary stopping (ThrowExpression vs RethrowExpression distinction). Also added recipe for adding parameters to catch clauses in quick fixes (CatchClauseParameter manipulation). |
| Feb 18, 2026 | avoid_unassigned_stream_subscriptions | Added recipe for detecting unassigned method invocation return values using `node.staticType` (return type) + `node.parent is ExpressionStatement` (discarded value). Shows dart:async type checking via `library.identifier`. |
| Feb 18, 2026 | prefer_contains | Added recipe for detecting negative integer literals (`-1` is `PrefixExpression(MINUS, IntegerLiteral(1))`, NOT `IntegerLiteral(-1)`). Combined with BinaryExpression for `.indexOf() == -1` pattern detection with reversed operand handling. |
| Feb 18, 2026 | prefer_overriding_parent_equality | Added recipe for checking if ancestors override specific members (== and hashCode) using `InterfaceType.methods`/`InterfaceType.getters` + AST-level `MethodDeclaration.isOperator`/`MethodDeclaration.isGetter`. Also documented that `InstanceElement` has `getters`/`methods`/`fields` (NOT `accessors`), `FieldElement.isOriginDeclaration` replaces deprecated `isSynthetic`, and `declaredFragment?.element` returns `ClassElement` with type promotion limitations. |
| Feb 18, 2026 | prefer_wildcard_pattern | Added `addSwitchExpression` to cheat sheet, recipe for detecting ObjectPattern by type name in switch/if-case patterns. Documents `ObjectPattern.type.name.lexeme` + `fields.isEmpty` check, recursive pattern walking through `LogicalAndPattern`/`LogicalOrPattern`, and `SwitchPatternCase` vs `SwitchExpressionCase` access patterns. |
| Feb 18, 2026 | avoid_incorrect_image_opacity | Added recipe for detecting wrapper widget with specific child type. Constructors without `new`/`const`/type args are parsed as `MethodInvocation` — must register both `addInstanceCreationExpression` and `addMethodInvocation`. Use `staticType` on the child expression for type checking regardless of AST node type. |
| Feb 18, 2026 | always_remove_listener | Added recipe for cross-method call pairing (tracking addListener/removeListener across lifecycle methods). Uses RecursiveAstVisitor collectors with function boundary stopping, `realTarget?.toSource()` matching, and `args.first.toSource()` for callback comparison. |
| Feb 18, 2026 | avoid_flexible_outside_flex | Added recipe for checking if a widget is a direct child of a specific parent widget type by walking the AST parent chain through ListLiteral/NamedExpression/ArgumentList to the enclosing InstanceCreationExpression. |
| Feb 18, 2026 | avoid_mounted_in_setstate | Added recipe for searching callback argument body for specific identifiers. Shows handling of three identifier forms: bare SimpleIdentifier (with parent exclusion), PrefixedIdentifier (`context.mounted`), and PropertyAccess (`this.mounted`). |
| Feb 18, 2026 | avoid_unnecessary_overrides | Added recipe for detecting unnecessary overrides across five patterns: abstract members (check `isAbstract` BEFORE `isGetter`/`isSetter`), getters (PropertyAccess on super), setters (AssignmentExpression to super), operators (BinaryExpression with SuperExpression, NOT MethodInvocation), and regular methods with arg pass-through validation. |
